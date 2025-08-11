import Foundation
import UIKit

// MARK: - API Request/Response Models
struct GenerationRequest: Codable {
    let image: String?      // Base64 encoded image
    let text: String?       // Text prompt
    let texture: Bool       // Whether to generate texture
    
    init(image: String? = nil, text: String? = nil, texture: Bool = false) {
        self.image = image
        self.text = text
        self.texture = texture
    }
}

struct GenerationResponse: Codable {
    let uid: String
}

struct StatusResponse: Codable {
    let status: String      // "preparing", "processing", "texturing", "completed", "error"
    let model_base64: String?   // Base64 encoded GLB file when completed (only when status is 'completed')
    let message: String?    // Error message (only when status is 'error')
}

struct HealthResponse: Codable {
    let status: String      // "healthy" if the service is running
    let worker_id: String   // Worker identifier
}

// MARK: - Network Service
class NetworkService {
    static let shared = NetworkService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.timeoutIntervalForResource = APIConfig.uploadTimeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Health Check
    func checkHealth() async throws -> HealthResponse {
        let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.healthEndpoint)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode, "Health check failed")
        }
        
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }
    
    // MARK: - Text to 3D Generation (Async)
    func generateFromText(_ text: String, texture: Bool) async throws -> String {
        let request = GenerationRequest(text: text, texture: texture)
        return try await sendAsyncGenerationRequest(request)
    }
    
    // MARK: - Image to 3D Generation (Async)
    func generateFromImage(_ image: UIImage, texture: Bool) async throws -> String {
        // Convert image to base64
        let imageBase64 = ImageProcessor.imageToBase64(image, quality: APIConfig.defaultImageQuality)
        let request = GenerationRequest(image: imageBase64, texture: texture)
        return try await sendAsyncGenerationRequest(request)
    }
    
    // MARK: - Send Async Generation Request
    private func sendAsyncGenerationRequest(_ request: GenerationRequest) async throws -> String {
        let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.sendAsyncEndpoint)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw APIError.invalidResponse
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let generationResponse = try JSONDecoder().decode(GenerationResponse.self, from: data)
        return generationResponse.uid
    }
    
    // MARK: - Check Task Status
    func checkTaskStatus(_ uid: String) async throws -> StatusResponse {
        let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.statusEndpoint)/\(uid)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        return try JSONDecoder().decode(StatusResponse.self, from: data)
    }
    
    // MARK: - Save GLB Model from Base64
    func saveGLBModel(from base64Data: String, filename: String) -> URL? {
        guard let data = Data(base64Encoded: base64Data) else {
            print("Failed to decode base64 data")
            return nil
        }
        
        // Get documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("GLB model saved to: \(fileURL.path)")
            return fileURL
        } catch {
            print("Failed to save GLB model: \(error)")
            return nil
        }
    }
}

// MARK: - Task Status Extensions
extension StatusResponse {
    var isCompleted: Bool {
        return status.lowercased() == "completed"
    }
    
    var isError: Bool {
        return status.lowercased() == "error"
    }
    
    var isProcessing: Bool {
        let lowerStatus = status.lowercased()
        return lowerStatus == "preparing" || lowerStatus == "processing" || lowerStatus == "texturing"
    }
    
    // 根据状态计算进度值
    var progressValue: Float {
        switch status.lowercased() {
        case "preparing":
            return 0.2  // 20% - 文本/图像处理阶段
        case "processing":
            return 0.5  // 50% - 3D模型生成阶段
        case "texturing":
            return 0.8  // 80% - 纹理生成阶段
        case "completed":
            return 1.0  // 100% - 完成
        case "error":
            return 0.0  // 0% - 错误
        default:
            return 0.0  // 默认
        }
    }
    
    // 状态显示消息
    var displayMessage: String {
        switch status.lowercased() {
        case "preparing":
            return "Processing input..."
        case "processing":
            return "Generating 3D model..."
        case "texturing":
            return "Adding textures..."
        case "completed":
            return "Generation completed!"
        case "error":
            return message ?? "Generation failed"
        default:
            return "Unknown status"
        }
    }
}
