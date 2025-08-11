import SwiftUI
import Foundation

// MARK: - Generation Modes
enum GenerationMode: String, CaseIterable {
    case text = "text"
    case image = "image"
    case file = "file"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .file: return "File"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "text.cursor"
        case .image: return "photo"
        case .file: return "folder"
        }
    }
}

// MARK: - Note: API Request/Response models are defined in NetworkService.swift

// MARK: - Generation State Management
class GenerationState: ObservableObject {
    @Published var currentMode: GenerationMode = .text
    @Published var textInput: String = ""
    @Published var selectedImage: UIImage?
    @Published var generateTexture: Bool = true
    
    // Task state
    @Published var isGenerating: Bool = false
    @Published var currentTaskID: String?
    @Published var progress: Float = 0.0
    @Published var generationStatus: String = ""
    @Published var generationError: String?
    
    // Generated model
    @Published var generatedModelURL: URL?
    
    // MARK: - Validation Methods
    func canGenerate() -> Bool {
        switch currentMode {
        case .text:
            return APIConfig.validateTextInput(textInput)
        case .image:
            guard let image = selectedImage else { return false }
            return APIConfig.validateImageSize(image)
        case .file:
            return true // File mode handled by DocumentPicker
        }
    }
    
    func getInputValidationError() -> String? {
        switch currentMode {
        case .text:
            if textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Please enter a description"
            }
            if textInput.count > APIConfig.maxTextLength {
                return "Text is too long (max \(APIConfig.maxTextLength) characters)"
            }
        case .image:
            if selectedImage == nil {
                return "Please select an image"
            }
            if let image = selectedImage, !APIConfig.validateImageSize(image) {
                return "Image size is too large"
            }
        case .file:
            break // No validation needed for file mode
        }
        return nil
    }
    
    func reset() {
        isGenerating = false
        currentTaskID = nil
        progress = 0.0
        generationStatus = ""
        generationError = nil
        generatedModelURL = nil
    }
}

// MARK: - API Configuration
struct APIConfig {
    // MARK: - Image Processing Settings
    static let maxImageSize = CGSize(width: 512, height: 512)
    static let defaultImageQuality: CGFloat = 0.85
    static let maxImageDataSize = 2 * 1024 * 1024 // 2MB max
    
    // MARK: - API Endpoints (Hunyuan3D API)
    static let baseURL = "http://localhost:8081"    // Update with actual server URL
    static let generateEndpoint = "/generate"        // For direct generation
    static let sendAsyncEndpoint = "/send"          // For async generation
    static let statusEndpoint = "/status"           // For checking status: /status/{uid}
    static let healthEndpoint = "/health"           // For health check
    
    // MARK: - Request Timeouts
    static let requestTimeout: TimeInterval = 30.0
    static let uploadTimeout: TimeInterval = 60.0
    static let pollInterval: TimeInterval = 2.0
    
    // MARK: - Generation Limits
    static let maxTextLength = 500
    static let maxTaskDuration: TimeInterval = 300.0 // 5 minutes
    
    // MARK: - Validation Methods
    static func validateImageSize(_ image: UIImage) -> Bool {
        let imageData = image.jpegData(compressionQuality: defaultImageQuality) ?? Data()
        return imageData.count <= maxImageDataSize
    }
    
    static func validateTextInput(_ text: String) -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               text.count <= maxTextLength
    }
}

// MARK: - Error Types
enum APIError: LocalizedError {
    case invalidImageSize
    case invalidTextInput
    case missingImage
    case networkError(String)
    case serverError(Int, String)
    case timeout
    case invalidResponse
    case taskFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageSize:
            return "Image size is too large. Please use a smaller image."
        case .invalidTextInput:
            return "Text input is invalid or too long."
        case .missingImage:
            return "No image selected."
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .timeout:
            return "Request timed out. Please try again."
        case .invalidResponse:
            return "Invalid response from server."
        case .taskFailed(let reason):
            return "Generation failed: \(reason)"
        }
    }
}
