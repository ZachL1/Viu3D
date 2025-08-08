import SwiftUI
import Combine
import SceneKit
import GLTFSceneKit

class ModelData: ObservableObject {
    @Published var rotation: Float = 0.0
    @Published var scale: Float = 1.0
    @Published var isLoading: Bool = false
    @Published var modelName: String = "plane"
    @Published var modelURL: URL?
    @Published var errorMessage: String?
    @Published var modelInfo: ModelInfo = ModelInfo()
    
    // 安全作用域资源管理
    private var currentSecurityScopedURL: URL?
    
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
    
    deinit {
        // 释放安全作用域资源
        stopAccessingCurrentSecurityScopedResource()
    }
    
    // 加载新模型
    func loadModel(from url: URL) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 首先停止访问当前的安全作用域资源
            DispatchQueue.main.async {
                self.stopAccessingCurrentSecurityScopedResource()
            }
            
            // 检查是否是Bundle内的文件
            let isBundleFile = url.path.contains(Bundle.main.bundlePath)
            var needsSecurityScopedAccess = false
            
            // 如果不是Bundle文件，需要开始安全作用域访问
            if !isBundleFile {
                needsSecurityScopedAccess = url.startAccessingSecurityScopedResource()
                if !needsSecurityScopedAccess {
                    DispatchQueue.main.async {
                        self.errorMessage = "无法访问所选文件"
                        self.isLoading = false
                    }
                    return
                }
            }
            
            do {
                // 验证文件是否存在且可读
                guard FileManager.default.fileExists(atPath: url.path) else {
                    throw ModelLoadError.fileNotFound
                }
                
//                // 根据文件格式验证文件
//                let isGLTF = GLTFLoader.isGLTFFile(url: url)
//                print("ModelData validation - File: \(url.lastPathComponent), extension: \(url.pathExtension), isGLTF: \(isGLTF)")
//                
//                if isGLTF {
//                    // 验证glTF/GLB文件
//                    // print("Validating glTF/GLB file with GLTFSceneKit...")
//                    _ = try GLTFLoader.loadScene(from: url)
//                    print("Successfully validated glTF/GLB file: \(url.lastPathComponent)")
//                } else {
//                    // 验证其他格式文件
//                    // print("Validating with SceneKit native loader...")
//                    _ = try SCNScene(url: url, options: nil)
//                    print("Successfully validated native format file: \(url.lastPathComponent)")
//                }
                
                DispatchQueue.main.async {
                    self.modelURL = url
                    self.modelName = url.deletingPathExtension().lastPathComponent
                    
                    // 如果需要安全作用域访问，保存引用
                    if needsSecurityScopedAccess {
                        self.currentSecurityScopedURL = url
                    }
                    
                    self.updateModelInfo(for: url)
                    self.resetModel()
                    self.isLoading = false
                }
                
            } catch {
                // 如果出错，释放安全作用域资源
                if needsSecurityScopedAccess {
                    url.stopAccessingSecurityScopedResource()
                }
                
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
            var vertexCount = 0
            var triangleCount = 0
            var materialCount = 0
            var scene: SCNScene
            
            // 检查是否为glTF文件
            if GLTFLoader.isGLTFFile(url: url) {
                // 使用GLTFLoader获取信息
                let gltfInfo = GLTFLoader.getFileInfo(from: url)
                vertexCount = gltfInfo.vertexCount
                triangleCount = gltfInfo.triangleCount
                materialCount = gltfInfo.materialCount
                
                // 加载场景获取边界框
                scene = try GLTFLoader.loadScene(from: url)
            } else {
                // 使用SceneKit原生加载器
                scene = try SCNScene(url: url, options: nil)
                
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
//                    return true
                }
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
            print("Failed to get model info: \(error)")
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
    
    // 停止访问当前的安全作用域资源
    private func stopAccessingCurrentSecurityScopedResource() {
        if let url = currentSecurityScopedURL {
            url.stopAccessingSecurityScopedResource()
            currentSecurityScopedURL = nil
            print("Stopped accessing security scoped resource: \(url.path)")
        }
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
