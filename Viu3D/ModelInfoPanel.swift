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
                        InfoRow(label: "文件名", value: modelData.modelInfo.fileName)
                        InfoRow(label: "文件大小", value: modelData.modelInfo.fileSize)
                    }
                    
                    // 几何信息
                    InfoSection(title: "几何信息") {
                        InfoRow(label: "顶点数量", value: "\(modelData.modelInfo.vertexCount)")
                        InfoRow(label: "三角形数量", value: "\(modelData.modelInfo.triangleCount)")
                        InfoRow(label: "材质数量", value: "\(modelData.modelInfo.materialCount)")
                        InfoRow(label: "边界框大小", value: modelData.modelInfo.boundingBoxSize)
                    }
                    
                    // 变换信息
                    InfoSection(title: "当前变换") {
                        InfoRow(label: "旋转角度", value: "\(Int(modelData.rotation * 180 / Float.pi))°")
                        InfoRow(label: "缩放比例", value: String(format: "%.1fx", modelData.scale))
                    }
                    
                    // 性能信息
                    InfoSection(title: "渲染信息") {
                        InfoRow(label: "渲染引擎", value: "SceneKit")
                        InfoRow(label: "光照模式", value: "简单光照 (Lambert)")
                        InfoRow(label: "抗锯齿", value: "2x MSAA")
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

// 信息行组件
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(":")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

#Preview {
    VStack {
        ModelInfoPanel(modelData: ModelData())
            .padding()
        
        Spacer()
    }
    .background(Color(.systemBackground))
}