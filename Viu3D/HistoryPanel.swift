import SwiftUI

struct HistoryPanel: View {
    @ObservedObject var historyManager: HistoryManager
    @Binding var isPresented: Bool
    let onModelSelect: (GenerationHistory) -> Void
    
    @State private var showingDeleteConfirmation = false
    @State private var historyToDelete: GenerationHistory?
    @State private var showingClearAllConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if historyManager.histories.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .alert("Delete Model", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let history = historyToDelete {
                    historyManager.deleteHistory(history)
                }
            }
        } message: {
            Text("Are you sure you want to delete this 3D model from your history?")
        }
        .alert("Clear All History", isPresented: $showingClearAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                historyManager.clearAllHistory()
            }
        } message: {
            let count = historyManager.histories.count
            Text("Are you sure you want to clear all \(count) 3D model\(count == 1 ? "" : "s") from your history? This action cannot be undone.")
        }
    }
    
    // MARK: - Header View
    @ViewBuilder
    private var headerView: some View {
        HStack {
            // Close Button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Title
            Text("History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Clear All Button
            if !historyManager.histories.isEmpty {
                Button("Clear") {
                    showingClearAllConfirmation = true
                }
                .font(.callout)
                .foregroundColor(.red)
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No 3D Models Yet")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Generated 3D models will appear here.\nStart creating to build your collection!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - History List View
    @ViewBuilder
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(historyManager.histories) { history in
                    HistoryRow(
                        history: history,
                        onTap: {
                            onModelSelect(history)
                            isPresented = false
                        },
                        onDelete: {
                            historyToDelete = history
                            showingDeleteConfirmation = true
                        }
                    )
                    .padding(.horizontal, 20)
                    
                    if history.id != historyManager.histories.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - History Row Component

struct HistoryRow: View {
    let history: GenerationHistory
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon/Thumbnail
                iconView
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Model Name
                    Text(history.modelName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Generation Type & Details
                    HStack(spacing: 8) {
                        Label(history.generationType.displayName, systemImage: history.generationType.iconName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if history.generateTexture {
                            Image(systemName: "paintbrush.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Prompt Preview
                    if let promptText = history.promptText, !promptText.isEmpty {
                        Text("\"\(promptText)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Date & Size
                    HStack(spacing: 12) {
                        Text(history.shortDate)
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                        
                        Text(history.formattedFileSize)
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                
                Spacer()
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.callout)
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
            
            if let promptImage = history.promptImage {
                Image(uiImage: promptImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: history.generationType.iconName)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryPanel(
        historyManager: HistoryManager.shared,
        isPresented: .constant(true),
        onModelSelect: { _ in }
    )
}