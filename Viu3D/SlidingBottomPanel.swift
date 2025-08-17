import SwiftUI
import SceneKit

// MARK: - Sliding Bottom Panel

struct SlidingBottomPanel<Content: View>: View {
    @Binding var isExpanded: Bool
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    let content: () -> Content
    
    @GestureState private var dragOffset: CGFloat = 0
    @State private var currentHeight: CGFloat = 0
    
    init(
        isExpanded: Binding<Bool>,
        collapsedHeight: CGFloat = 120,
        expandedHeight: CGFloat = 400,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isExpanded = isExpanded
        self.collapsedHeight = collapsedHeight
        self.expandedHeight = expandedHeight
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            dragHandle
            
            // Content
            content()
        }
        .frame(height: targetHeight + dragOffset)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .offset(y: max(0, (targetHeight + dragOffset) - targetHeight))
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.height
                }
                .onEnded { value in
                    let velocity = value.predictedEndLocation.y - value.location.y
                    let threshold = (expandedHeight - collapsedHeight) * 0.3
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        if value.translation.height > threshold || velocity > 100 {
                            isExpanded = false
                        } else if value.translation.height < -threshold || velocity < -100 {
                            isExpanded = true
                        }
                    }
                }
        )
        .onChange(of: isExpanded) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentHeight = targetHeight
            }
        }
        .onAppear {
            currentHeight = targetHeight
        }
    }
    
    private var targetHeight: CGFloat {
        isExpanded ? expandedHeight : collapsedHeight
    }
    
    @ViewBuilder
    private var dragHandle: some View {
        VStack(spacing: 8) {
            // Handle Bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Expand/Collapse Indicator
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 20)
            }
        }
    }
}

// MARK: - Enhanced Model Info Panel

struct EnhancedModelInfoPanel: View {
    @ObservedObject var modelData: ModelData
    @ObservedObject var historyManager: HistoryManager
    @Binding var isExpanded: Bool
    @Binding var currentHistory: GenerationHistory?
    @State private var refreshTrigger = UUID()
    @State private var isEditingName = false
    @State private var editingName = ""
    @State private var showingARPreview = false
    
    var body: some View {
        SlidingBottomPanel(
            isExpanded: $isExpanded,
            collapsedHeight: 120,
            expandedHeight: 500
        ) {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if isExpanded {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if let history = currentHistory {
                                generationInfoSection(history: history)
                                Divider()
                            }
                            
                            modelInfoSection
                            
                            if let history = currentHistory {
                                Divider()
                                promptSection(history: history)
                            }
                        }
                        .padding(.horizontal, 20)
//                        .padding(.bottom, 40) // 增加底部内边距，避免内容被截断
                    }
                    .frame(maxHeight: 350) // 限制ScrollView最大高度，为header预留空间
                } else {
                    // Collapsed view
                    collapsedView
                }
            }
        }
        .onChange(of: modelData.modelInfo.vertexCount) { _ in
            refreshTrigger = UUID()
        }
        .onChange(of: modelData.modelURL) { _ in
            refreshTrigger = UUID()
        }
        .id(refreshTrigger)
        .fullScreenCover(isPresented: $showingARPreview) {
            FullARPreviewView(modelData: modelData, isPresented: $showingARPreview)
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let history = currentHistory {
                    if isEditingName {
                        TextField("Project Name", text: $editingName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                saveEditedName()
                            }
                            .frame(maxWidth: 200) // 限制输入框宽度
                    } else {
                        Button(action: {
                            startEditingName(history.modelName)
                        }) {
                            HStack(spacing: 6) {
                                Text(history.modelName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Image(systemName: "pencil")
                                    .font(.callout)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else if let url = modelData.modelURL {
                    Text(url.lastPathComponent)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            if isEditingName {
                HStack(spacing: 8) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Button("Save") {
                        saveEditedName()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else if let history = currentHistory {
                Label(history.generationType.displayName, systemImage: history.generationType.iconName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var collapsedView: some View {
        HStack {
            HStack(spacing: 12) {
                if let history = currentHistory {
                    Text(history.shortDate)
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                    
                    Text(history.formattedFileSize)
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                } else {
                    Text("Model loaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let history = currentHistory, history.generateTexture {
                Image(systemName: "paintbrush.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    private func generationInfoSection(history: GenerationHistory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generation Details")
                .font(.headline)
            
            InfoRow(label: "Type", value: history.generationType.displayName, icon: history.generationType.iconName)
            InfoRow(label: "Created", value: history.formattedDate, icon: "calendar")
            InfoRow(label: "File Size", value: history.formattedFileSize, icon: "doc")
            
            if history.generateTexture {
                InfoRow(label: "Texture", value: "High Quality", icon: "paintbrush.fill", valueColor: .blue)
            } else {
                InfoRow(label: "Texture", value: "Geometry Only", icon: "cube", valueColor: .orange)
            }
        }
    }
    
    @ViewBuilder
    private var modelInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Properties")
                .font(.headline)
            
            if modelData.modelURL != nil {
                InfoRow(label: "File Name", value: modelData.modelURL?.lastPathComponent ?? "Unknown", icon: "doc.text")
                InfoRow(label: "File Size", value: modelData.modelInfo.fileSize.isEmpty ? "Unknown" : modelData.modelInfo.fileSize, icon: "doc")
                InfoRow(label: "Vertices", value: "\(modelData.modelInfo.vertexCount)", icon: "point.3.connected.trianglepath.dotted")
                InfoRow(label: "Triangles", value: "\(modelData.modelInfo.triangleCount)", icon: "triangle")
                InfoRow(label: "Materials", value: "\(modelData.modelInfo.materialCount)", icon: "paintbrush")
            }
            
            InfoRow(label: "Format", value: modelData.modelURL?.pathExtension.uppercased() ?? "UNKNOWN", icon: "doc.text")
            InfoRow(label: "Anti-aliasing", value: "2x MSAA", icon: "square.grid.3x1.folder.badge.plus")
            
            // AR预览按钮
            if modelData.modelURL != nil {
                Button(action: {
                    showingARPreview = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arkit")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AR Preview")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("View in your space")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 8)
            }
        }
    }
    
    @ViewBuilder
    private func promptSection(history: GenerationHistory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generation Prompt")
                .font(.headline)
            
            if let promptText = history.promptText, !promptText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Prompt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\"\(promptText)\"")
                        .font(.body)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            if let promptImage = history.promptImage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reference Image")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Image(uiImage: promptImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    // MARK: - Name Editing Methods
    
    private func startEditingName(_ currentName: String) {
        editingName = currentName
        isEditingName = true
    }
    
    private func saveEditedName() {
        guard let history = currentHistory,
              !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cancelEditing()
            return
        }
        
        historyManager.updateModelName(historyId: history.id, newName: editingName)
        
        // 更新当前历史记录
        if let updatedHistory = historyManager.histories.first(where: { $0.id == history.id }) {
            currentHistory = updatedHistory
        }
        
        isEditingName = false
    }
    
    private func cancelEditing() {
        isEditingName = false
        editingName = ""
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .leading)
            
            Text(label)
                .font(.callout)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        EnhancedModelInfoPanel(
            modelData: ModelData(),
            historyManager: HistoryManager.shared,
            isExpanded: .constant(true),
            currentHistory: .constant(GenerationHistory.mock())
        )
    }
    .background(Color(.systemGroupedBackground))
}
