import Foundation
import UIKit

// MARK: - Real API Service
class APIService: ObservableObject {
    static let shared = APIService()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // MARK: - Health Check
    func checkHealth() async throws -> Bool {
        do {
            let health = try await networkService.checkHealth()
            print("API Health check: \(health.status)")
            return health.status.lowercased() == "ok" || health.status.lowercased() == "healthy"
        } catch {
            print("API Health check failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Text to 3D Generation
    func generateFromText(_ text: String, withTexture texture: Bool) async throws -> String {
        print("API: Starting text-to-3D generation")
        print("Text: '\(text)'")
        print("Texture: \(texture)")
        
        do {
            let uid = try await networkService.generateFromText(text, texture: texture)
            print("API: Task started with UID: \(uid)")
            return uid
        } catch {
            print("API Error in text generation: \(error)")
            throw error
        }
    }
    
    // MARK: - Image to 3D Generation
    func generateFromImage(_ image: UIImage, withTexture texture: Bool) async throws -> String {
        print("API: Starting image-to-3D generation")
        
        // Process and optimize the image
        let processedImage = ImageProcessor.processImage(image)
        let imageInfo = ImageProcessor.getImageInfo(processedImage)
        
        print("Original image size: \(image.size)")
        print("Processed image size: \(imageInfo.size)")
        print("Image data size: \(ByteCountFormatter.string(fromByteCount: Int64(imageInfo.dataSize), countStyle: .file))")
        print("Texture enabled: \(texture)")
        
        do {
            let uid = try await networkService.generateFromImage(processedImage, texture: texture)
            print("API: Task started with UID: \(uid)")
            return uid
        } catch {
            print("API Error in image generation: \(error)")
            throw error
        }
    }
    
    // MARK: - Task Status Checking  
    func checkTaskStatus(uid: String) async throws -> StatusResponse {
        print("API: Checking status for UID: \(uid)")
        
        do {
            let status = try await networkService.checkTaskStatus(uid)
            print("API Status: \(status.status), Progress: \(Int(status.progressValue * 100))%")
            return status
        } catch {
            print("API Error checking status: \(error)")
            throw error
        }
    }
    
    // MARK: - Save Completed Model
    func saveCompletedModel(from statusResponse: StatusResponse) -> URL? {
        guard let modelBase64 = statusResponse.model_base64 else {
            print("No model data in response")
            return nil
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "generated_model_\(timestamp).glb"
        
        return networkService.saveGLBModel(from: modelBase64, filename: filename)
    }
    

}

// MARK: - Generation Task Manager
class GenerationTaskManager: ObservableObject {
    @Published var generationState: GenerationState
    private var pollingTask: Task<Void, Error>?
    
    init(generationState: GenerationState) {
        self.generationState = generationState
    }
    
    // MARK: - Start Generation
    func startGeneration() async {
        guard generationState.canGenerate() else { return }
        
        await MainActor.run {
            generationState.reset()
            generationState.isGenerating = true
            generationState.progress = 0.0
        }
        
        do {
            let taskID: String
            
            switch generationState.currentMode {
            case .text:
                taskID = try await APIService.shared.generateFromText(
                    generationState.textInput,
                    withTexture: generationState.generateTexture
                )
                
            case .image:
                guard let image = generationState.selectedImage else {
                    throw APIError.missingImage
                }
                taskID = try await APIService.shared.generateFromImage(
                    image,
                    withTexture: generationState.generateTexture
                )
                
            case .file:
                // File mode is handled separately
                return
            }
            
            await MainActor.run {
                generationState.currentTaskID = taskID
            }
            
            // Start polling task status
            await startPolling(taskID: taskID)
            
        } catch {
            await MainActor.run {
                generationState.isGenerating = false
                generationState.generationError = "Failed to start generation: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Status Polling
    private func startPolling(taskID: String) async {
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let statusResponse = try await APIService.shared.checkTaskStatus(uid: taskID)
                    
                    await MainActor.run {
                        generationState.progress = statusResponse.progressValue
                        generationState.generationStatus = statusResponse.displayMessage
                    }
                    
                    if statusResponse.isCompleted {
                        await handleGenerationCompleted(statusResponse: statusResponse)
                        break
                    } else if statusResponse.isError {
                        await handleGenerationError(statusResponse: statusResponse)
                        break
                    }
                    
                    // Wait before next poll (using API config)
                    let pollInterval = UInt64(APIConfig.pollInterval * 1_000_000_000) // Convert to nanoseconds
                    try await Task.sleep(nanoseconds: pollInterval)
                    
                } catch {
                    await MainActor.run {
                        generationState.isGenerating = false
                        generationState.generationError = "Polling error: \(error.localizedDescription)"
                    }
                    break
                }
            }
        }
    }
    
    private func handleGenerationCompleted(statusResponse: StatusResponse) async {
        guard let modelURL = APIService.shared.saveCompletedModel(from: statusResponse) else {
            await MainActor.run {
                generationState.isGenerating = false
                generationState.generationError = "Failed to save generated model"
            }
            return
        }
        
        print("Generation completed! Model saved to: \(modelURL.path)")
        
        await MainActor.run {
            generationState.isGenerating = false
            generationState.progress = 1.0
            generationState.generationStatus = "Generation completed successfully!"
            generationState.generatedModelURL = modelURL
        }
    }
    
    private func handleGenerationError(statusResponse: StatusResponse) async {
        await MainActor.run {
            generationState.isGenerating = false
            generationState.generationError = statusResponse.message ?? "Generation failed"
        }
    }
    
    // MARK: - Cancel Generation
    func cancelGeneration() {
        pollingTask?.cancel()
        pollingTask = nil
        
        generationState.reset()
    }
    
    deinit {
        pollingTask?.cancel()
    }
}

