import SwiftUI
import Combine
import SceneKit

class ModelData: ObservableObject {
    @Published var rotation: Float = 0.0
    @Published var scale: Float = 1.0
    @Published var isLoading: Bool = false
    @Published var modelName: String = "plane"
    @Published var modelURL: URL?
    @Published var errorMessage: String?
    @Published var modelInfo: ModelInfo = ModelInfo()
    
    // 模型信息结构
    struct ModelInfo {
        var fileName: String = "plane.usdz"
        var fileSize: String = ""
        var vertexCount: Int = 0
        var triangleCount: Int = 0
        var materialCount: Int = 0
        var boundingBoxSize: String = ""
    }
    
    init() {
        // 设置默认的内置模型
        if let defaultURL = Bundle.main.url(forResource: "plane", withExtension: "usdz") {
            self.modelURL = defaultURL
            self.modelName = "plane"
            updateModelInfo(for: defaultURL)
        }
    }
    
    // 加载新模型
    func loadModel(from url: URL) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 验证文件是否存在且可读
                guard FileManager.default.fileExists(atPath: url.path) else {
                    throw ModelLoadError.fileNotFound
                }
                
                // 尝试加载场景以验证文件格式
                _ = try SCNScene(url: url, options: nil)
                
                DispatchQueue.main.async {
                    self.modelURL = url
                    self.modelName = url.deletingPathExtension().lastPathComponent
                    self.updateModelInfo(for: url)
                    self.resetModel()
                    self.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = self.getErrorMessage(for: error)
                    self.isLoading = false
                }
            }
        }
    }
    
    // 更新模型信息
    private func updateModelInfo(for url: URL) {
        var info = ModelInfo()
        info.fileName = url.lastPathComponent
        
        // 获取文件大小
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? NSNumber {
                info.fileSize = ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)
            }
        } catch {
            info.fileSize = "未知"
        }
        
        // 尝试获取模型几何信息
        do {
            let scene = try SCNScene(url: url, options: nil)
            var vertexCount = 0
            var triangleCount = 0
            var materialCount = 0
            
            scene.rootNode.enumerateChildNodes { node, _ in
                if let geometry = node.geometry {
                    // 计算顶点和三角形数量
                    for source in geometry.sources {
                        if source.semantic == .vertex {
                            vertexCount += source.vectorCount
                        }
                    }
                    
                    for element in geometry.elements {
                        if element.primitiveType == .triangles {
                            triangleCount += element.primitiveCount
                        }
                    }
                    
                    materialCount += geometry.materials.count
                }
//                return true
            }
            
            info.vertexCount = vertexCount
            info.triangleCount = triangleCount
            info.materialCount = materialCount
            
            // 获取边界框信息
            let (min, max) = scene.rootNode.boundingBox
            let size = SCNVector3(max.x - min.x, max.y - min.y, max.z - min.z)
            info.boundingBoxSize = String(format: "%.2f × %.2f × %.2f", size.x, size.y, size.z)
            
        } catch {
            // 如果无法获取详细信息，保持默认值
        }
        
        DispatchQueue.main.async {
            self.modelInfo = info
        }
    }
    
    // 重置模型到初始状态
    func resetModel() {
        rotation = 0.0
        scale = 1.0
    }
    
    // 旋转模型
    func rotateModel(by angle: Float) {
        rotation += angle
        // 保持角度在0-2π范围内
        if rotation > Float.pi * 2 {
            rotation -= Float.pi * 2
        } else if rotation < 0 {
            rotation += Float.pi * 2
        }
    }
    
    // 缩放模型
    func scaleModel(by factor: Float) {
        scale = max(0.1, min(3.0, scale * factor))
    }
    
    // 错误处理
    private func getErrorMessage(for error: Error) -> String {
        if let modelError = error as? ModelLoadError {
            return modelError.localizedDescription
        }
        return "加载模型时发生错误：\(error.localizedDescription)"
    }
}

// 自定义错误类型
enum ModelLoadError: LocalizedError {
    case fileNotFound
    case unsupportedFormat
    case corruptedFile
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到指定的模型文件"
        case .unsupportedFormat:
            return "不支持的文件格式"
        case .corruptedFile:
            return "文件已损坏或格式错误"
        }
    }
} 
