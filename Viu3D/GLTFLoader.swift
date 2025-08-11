import Foundation
import SceneKit
import GLTFSceneKit

/// GLTFLoader - 专门处理glTF和GLB文件的加载器
class GLTFLoader {
    
    /// 检查文件是否为glTF格式
    static func isGLTFFile(url: URL) -> Bool {
        let exten = url.pathExtension.lowercased()
        return exten == "gltf" || exten == "glb"
    }
    
    /// 加载glTF或GLB文件
    /// - Parameter url: 文件URL
    /// - Returns: SceneKit场景
    /// - Throws: 加载过程中的错误
    static func loadScene(from url: URL) throws -> SCNScene {
        guard isGLTFFile(url: url) else {
            throw GLTFLoadError.unsupportedFormat
        }
        
        do {
            print("Loading glTF file: \(url.lastPathComponent)")
            
            // 使用GLTFSceneKit加载glTF文件
            let sceneSource = GLTFSceneSource(url: url)
            let scene = try sceneSource.scene()
            
            print("Successfully loaded glTF scene")
            
            // 应用基础优化
            optimizeScene(scene)
            
            return scene
            
        } catch {
            print("Failed to load glTF file: \(error)")
            throw GLTFLoadError.loadFailed(error.localizedDescription)
        }
    }
    
    /// 优化glTF场景
    private static func optimizeScene(_ scene: SCNScene) {
        scene.rootNode.enumerateChildNodes { node, _ in
            // 优化几何体
            if let geometry = node.geometry {
                // 启用双面渲染（对glTF模型很重要）
                for material in geometry.materials {
                    material.isDoubleSided = true
                    
                    // 如果模型本身包含PBR材质，保持原有设置
                    // 否则使用Lambert模型
                    if material.lightingModel == .constant {
                        material.lightingModel = .lambert
                    }
                }
            }
            
//            return true
        }
    }
    
    /// 获取glTF文件的基本信息
    static func getFileInfo(from url: URL) -> (vertexCount: Int, triangleCount: Int, materialCount: Int) {
        var vertexCount = 0
        var triangleCount = 0
        var materialCount = 0
        
        do {
            let sceneSource = GLTFSceneSource(url: url)
            let scene = try sceneSource.scene()
            
            scene.rootNode.enumerateChildNodes { node, _ in
                if let geometry = node.geometry {
                    // 计算顶点数
                    for source in geometry.sources {
                        if source.semantic == .vertex {
                            vertexCount += source.vectorCount
                        }
                    }
                    
                    // 计算三角形数
                    for element in geometry.elements {
                        if element.primitiveType == .triangles {
                            triangleCount += element.primitiveCount
                        }
                    }
                    
                    // 计算材质数
                    materialCount += geometry.materials.count
                }
//                return true
            }
            
        } catch {
            print("Failed to get glTF file info: \(error)")
        }
        
        return (vertexCount, triangleCount, materialCount)
    }
}

// MARK: - Error Types
enum GLTFLoadError: LocalizedError {
    case unsupportedFormat
    case loadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "不支持的glTF文件格式"
        case .loadFailed(let message):
            return "glTF文件加载失败: \(message)"
        }
    }
}
