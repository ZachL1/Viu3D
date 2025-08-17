import SwiftUI
import ARKit
import RealityKit
import SceneKit

struct ARPreviewView: UIViewRepresentable {
    @ObservedObject var modelData: ModelData
    @Binding var isPresented: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // 配置AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        
        // 添加手势识别
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // 设置代理
        arView.session.delegate = context.coordinator
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.modelData = modelData
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARPreviewView
        var arView: ARView?
        var modelData: ModelData
        var placedModel: ModelEntity?
        var isModelPlaced = false
        
        init(_ parent: ARPreviewView) {
            self.parent = parent
            self.modelData = parent.modelData
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let location = gesture.location(in: arView)
            
            if !isModelPlaced {
                // 首次点击：放置模型
                placeModel(at: location)
            } else {
                // 后续点击：移动模型
                moveModel(to: location)
            }
        }
        
        private func placeModel(at location: CGPoint) {
            guard let arView = arView,
                  let modelURL = modelData.modelURL else { return }
            
            // 执行射线检测
            let results = arView.raycast(from: location, allowing: .existingPlaneInfinite, alignment: .horizontal)
            
            guard let firstResult = results.first else {
                // 如果没有检测到平面，在相机前方放置
                placeModelInFrontOfCamera()
                return
            }
            
            // 创建锚点
            let anchor = AnchorEntity(world: firstResult.worldTransform)
            
            // 加载并放置模型
            loadAndPlaceModel(at: anchor, modelURL: modelURL)
        }
        
        private func placeModelInFrontOfCamera() {
            guard let arView = arView,
                  let modelURL = modelData.modelURL else { return }
            
            // 在相机前方1.5米处放置模型
            let cameraTransform = arView.cameraTransform
            var translation = cameraTransform.translation
            translation.z -= 1.5 // 前方1.5米
            
            let anchor = AnchorEntity(world: Transform(scale: SIMD3<Float>(1, 1, 1), 
                                                     rotation: simd_quatf(), 
                                                     translation: translation).matrix)
            
            loadAndPlaceModel(at: anchor, modelURL: modelURL)
        }
        
        private func loadAndPlaceModel(at anchor: AnchorEntity, modelURL: URL) {
            Task {
                do {
                    let modelEntity: ModelEntity
                    
                    // 根据文件类型加载模型
                    if GLTFLoader.isGLTFFile(url: modelURL) {
                        // 对于glTF/GLB文件，需要先转换为SceneKit场景再转为RealityKit
                        let scene = try await GLTFLoader.loadScene(from: modelURL)
                        modelEntity = await convertSceneKitToRealityKit(scene: scene)
                    } else {
                        // 对于USDZ等原生支持的格式
                        modelEntity = try await ModelEntity(contentsOf: modelURL)
                    }
                    
                    // 调整模型大小和位置
                    let boundingBox = modelEntity.model?.mesh.bounds
                    let size = boundingBox?.extents ?? SIMD3<Float>(0.1, 0.1, 0.1)
                    let maxDimension = max(size.x, max(size.y, size.z))
                    
                    // 将模型缩放到合适的大小（最大0.3米）
                    if maxDimension > 0.3 {
                        let scale = 0.3 / maxDimension
                        await MainActor.run {
                            modelEntity.scale = SIMD3<Float>(scale, scale, scale)
                        }
                    }
                    
                    // 添加碰撞组件以支持手势交互
                    await modelEntity.generateCollisionShapes(recursive: true)
                    
                    await MainActor.run {
                        // 启用手势（移动、旋转、缩放）
                        arView?.installGestures([.rotation, .scale, .translation], for: modelEntity)
                        
                        anchor.addChild(modelEntity)
                        arView?.scene.addAnchor(anchor)
                    }
                    
                    await MainActor.run {
                        self.placedModel = modelEntity
                        self.isModelPlaced = true
                    }
                    
                } catch {
                    print("Error loading model in AR: \(error)")
                }
            }
        }
        
        private func convertSceneKitToRealityKit(scene: SCNScene) async -> ModelEntity {
            // 这是一个简化的转换，实际项目中可能需要更复杂的处理
            // 对于glTF模型，可以考虑使用其他方法或者第三方库
            
            // 临时方案：创建一个基本的ModelEntity
            let modelEntity = ModelEntity()
            
            // 遍历SceneKit场景的节点并尝试转换
            scene.rootNode.enumerateChildNodes { node, _ in
                if let geometry = node.geometry {
                    // 这里需要更复杂的几何体转换逻辑
                    // 现在创建一个简单的占位符
                    let mesh = MeshResource.generateBox(size: 0.1)
                    let material = SimpleMaterial(color: .blue, isMetallic: false)
                    let childEntity = ModelEntity(mesh: mesh, materials: [material])
                    
                    // 应用变换 - 转换SCNMatrix4到float4x4
                    childEntity.transform.matrix = simd_float4x4(node.worldTransform)
                    modelEntity.addChild(childEntity)
                }
            }
            
            return modelEntity
        }
        
        private func moveModel(to location: CGPoint) {
            guard let arView = arView,
                  let placedModel = placedModel else { return }
            
            let results = arView.raycast(from: location, allowing: .existingPlaneInfinite, alignment: .horizontal)
            
            if let firstResult = results.first {
                // 移动模型到新位置
                let newTransform = Transform(matrix: firstResult.worldTransform)
                placedModel.move(to: newTransform, relativeTo: nil, duration: 0.25, timingFunction: .easeInOut)
            }
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR Session failed with error: \(error)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("AR Session was interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("AR Session interruption ended")
        }
    }
}

// AR预览的覆盖UI
struct AROverlayView: View {
    @Binding var isPresented: Bool
    let onResetModel: () -> Void
    
    var body: some View {
        VStack {
            // 顶部控制栏
            HStack {
                Button("完成") {
                    isPresented = false
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
                
                Spacer()
                
                Button(action: onResetModel) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
            }
            .padding()
            
            Spacer()
            
            // 底部提示信息
            VStack(spacing: 8) {
                Text("点击水平面放置模型")
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                
                Text("使用手势缩放、旋转和移动模型")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
            }
            .padding()
        }
    }
}

// 完整的AR预览视图
struct FullARPreviewView: View {
    @ObservedObject var modelData: ModelData
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            ARPreviewView(modelData: modelData, isPresented: $isPresented)
                .ignoresSafeArea()
            
            AROverlayView(isPresented: $isPresented) {
                // 重置模型位置的逻辑
                // 这里可以添加重新放置模型的功能
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            // 当AR视图消失时，暂停AR会话以节省电池
        }
    }
}

#if DEBUG
struct ARPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        FullARPreviewView(
            modelData: ModelData(),
            isPresented: .constant(true)
        )
    }
}
#endif
