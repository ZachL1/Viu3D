import SwiftUI

struct ControlPanel: View {
    @ObservedObject var modelData: ModelData
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            Text("模型控制")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 旋转控制
            VStack(alignment: .leading, spacing: 8) {
                Text("旋转")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button(action: { modelData.rotateModel(by: -0.2) }) {
                        Image(systemName: "rotate.left")
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(modelData.rotation * 180 / Float.pi))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { modelData.rotateModel(by: 0.2) }) {
                        Image(systemName: "rotate.right")
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            // 缩放控制
            VStack(alignment: .leading, spacing: 8) {
                Text("缩放")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button(action: { modelData.scaleModel(by: 0.9) }) {
                        Image(systemName: "minus.magnifyingglass")
                            .frame(width: 44, height: 44)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1fx", modelData.scale))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { modelData.scaleModel(by: 1.1) }) {
                        Image(systemName: "plus.magnifyingglass")
                            .frame(width: 44, height: 44)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // 缩放滑块
                Slider(value: Binding(
                    get: { modelData.scale },
                    set: { modelData.scale = max(0.1, min(3.0, $0)) }
                ), in: 0.1...3.0, step: 0.1)
                .accentColor(.green)
            }
            
            // 重置按钮
            Button(action: { modelData.resetModel() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重置")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            .foregroundColor(.orange)
            
            // 模型信息
            VStack(alignment: .leading, spacing: 4) {
                Text("模型信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("文件:")
                    Text(modelData.modelName + ".usdz")
                        .foregroundColor(.blue)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ControlPanel(modelData: ModelData())
        .padding()
} 
