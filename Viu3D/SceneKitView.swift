import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    @ObservedObject var modelData: ModelData
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        
        // 创建场景
        let scene = SCNScene()
        sceneView.scene = scene
        
        // 设置背景色和渲染选项
        sceneView.backgroundColor = UIColor.clear
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true // 使用默认简单光照
        sceneView.antialiasingMode = .multisampling2X
        
        // 加载模型
        if let modelURL = modelData.modelURL {
            loadModel(from: modelURL, into: scene)
        }
        
        // 设置相机
        setupCamera(scene: scene)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 检查是否需要重新加载模型
        if let modelURL = modelData.modelURL,
           let currentScene = uiView.scene,
           shouldReloadModel(currentScene: currentScene, newURL: modelURL) {
            
            // 清除当前场景
            currentScene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
            
            // 加载新模型
            loadModel(from: modelURL, into: currentScene)
            
            // 重新设置相机
            setupCamera(scene: currentScene)
        }
        
        // 根据绑定的值更新模型变换
        if let modelNode = findModelNode(in: uiView.scene?.rootNode) {
            modelNode.scale = SCNVector3(modelData.scale, modelData.scale, modelData.scale)
            modelNode.rotation = SCNVector4(0, 1, 0, modelData.rotation)
        }
    }
    
    // 查找模型节点（不包括相机和光照节点）
    private func findModelNode(in rootNode: SCNNode?) -> SCNNode? {
        guard let rootNode = rootNode else { return nil }
        
        for child in rootNode.childNodes {
            if child.camera == nil && child.light == nil && child.geometry != nil {
                return child
            }
            if child.childNodes.contains(where: { $0.geometry != nil }) {
                return child
            }
        }
        return nil
    }
    
    // 检查是否需要重新加载模型
    private func shouldReloadModel(currentScene: SCNScene, newURL: URL) -> Bool {
        // 简单检查：如果场景中没有几何体节点，则需要加载
        return findModelNode(in: currentScene.rootNode) == nil
    }
    
    private func loadModel(from url: URL, into scene: SCNScene) {
        do {
            let modelScene = try SCNScene(url: url, options: [
                .checkConsistency: true,
                .flattenScene: false
            ])
            
            // 创建一个容器节点来包含模型
            let modelNode = SCNNode()
            modelNode.name = "ModelContainer"
            
            // 将模型的所有子节点添加到容器节点
            for child in modelScene.rootNode.childNodes {
                modelNode.addChildNode(child)
            }
            
            // 应用基础材质设置
            setupBasicMaterials(node: modelNode)
            
            // 计算模型的边界框并居中
            let (min, max) = modelNode.boundingBox
            let center = SCNVector3(
                (min.x + max.x) / 2,
                (min.y + max.y) / 2,
                (min.z + max.z) / 2
            )
            
            // 将模型移动到原点
            modelNode.position = SCNVector3(-center.x, -center.y, -center.z)
            
            // 添加到场景
            scene.rootNode.addChildNode(modelNode)
            
        } catch {
            print("Error loading model from \(url): \(error)")
        }
    }
    
    // 基础材质设置
    private func setupBasicMaterials(node: SCNNode) {
        node.enumerateChildNodes { childNode, _ in
            if let geometry = childNode.geometry {
                for material in geometry.materials {
                    // 使用简单的Lambert光照模型
                    material.lightingModel = .lambert
                    
                    // 启用双面渲染
                    material.isDoubleSided = true
                }
            }
//            return true
        }
    }
    
    private func setupCamera(scene: SCNScene) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)
    }
    

} 
