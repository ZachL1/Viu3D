import SwiftUI

struct ModelInfoPanel: View {
    @ObservedObject var modelData: ModelData
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 可折叠的标题栏
            Button(action: { 
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("模型信息")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.spring(), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
            }
            .buttonStyle(PlainButtonStyle())
            
            // 详细信息面板
            if isExpanded {
                VStack(spacing: 12) {
                    // 基本信息
                    InfoSection(title: "文件信息") {
                        InfoRow(label: "文件名", value: modelData.modelInfo.fileName, icon: "doc.text")
                        InfoRow(label: "文件大小", value: modelData.modelInfo.fileSize, icon: "doc")
                    }
                    
                    // 几何信息
                    InfoSection(title: "几何信息") {
                        InfoRow(label: "顶点数量", value: "\(modelData.modelInfo.vertexCount)", icon: "point.3.connected.trianglepath.dotted")
                        InfoRow(label: "三角形数量", value: "\(modelData.modelInfo.triangleCount)", icon: "triangle")
                        InfoRow(label: "材质数量", value: "\(modelData.modelInfo.materialCount)", icon: "paintbrush")
                        InfoRow(label: "边界框大小", value: modelData.modelInfo.boundingBoxSize, icon: "cube")
                    }
                    
                    // 变换信息
                    InfoSection(title: "当前变换") {
                        InfoRow(label: "旋转角度", value: "\(Int(modelData.rotation * 180 / Float.pi))°", icon: "rotate.3d")
                        InfoRow(label: "缩放比例", value: String(format: "%.1fx", modelData.scale), icon: "plus.magnifyingglass")
                    }
                    
                    // 性能信息
                    InfoSection(title: "渲染信息") {
                        InfoRow(label: "渲染引擎", value: "SceneKit", icon: "gear")
                        InfoRow(label: "光照模式", value: getLightingMode(), icon: "light.max")
                        InfoRow(label: "抗锯齿", value: "2x MSAA", icon: "square.grid.3x1.folder.badge.plus")
                        if isGLTFFile() {
                            InfoRow(label: "格式支持", value: "GLTFSceneKit", icon: "arrow.triangle.2.circlepath")
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // 判断是否为glTF文件
    private func isGLTFFile() -> Bool {
        let exten = modelData.modelInfo.fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        return exten == "gltf" || exten == "glb"
    }
    
    // 获取光照模式描述
    private func getLightingMode() -> String {
        if isGLTFFile() {
            return "混合模式 (PBR/Lambert)"
        } else {
            return "简单光照 (Lambert)"
        }
    }
}

// 信息分组组件
struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
            
            VStack(spacing: 4) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// InfoRow component is now defined in SlidingBottomPanel.swift

#Preview {
    VStack {
        ModelInfoPanel(modelData: ModelData())
            .padding()
        
        Spacer()
    }
    .background(Color(.systemBackground))
}
