import SwiftUI

struct GenerationStatusView: View {
    @ObservedObject var generationState: GenerationState
    
    var body: some View {
        if generationState.isGenerating || !generationState.generationStatus.isEmpty || generationState.generationError != nil {
            VStack(spacing: 12) {
                // Progress Bar
                if generationState.isGenerating {
                    VStack(spacing: 8) {
                        // Animated Progress Bar
                        ProgressView(value: generationState.progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 8)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        // Progress Percentage
                        HStack {
                            Text("Progress: \(Int(generationState.progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let taskID = generationState.currentTaskID {
                                Text("Task: \(String(taskID.prefix(8)))...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontDesign(.monospaced)
                            }
                        }
                    }
                }
                
                // Status Message
                HStack {
                    statusIcon
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusMessage)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        if let subMessage = statusSubMessage {
                            Text(subMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Cancel/Retry Button
                    if generationState.isGenerating {
                        Button("Cancel") {
                            generationState.reset()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    } else if generationState.generationError != nil {
                        Button("Retry") {
                            generationState.reset()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                // Error Message
                if let errorMessage = generationState.generationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        Group {
            if generationState.isGenerating {
                if generationState.progress < 0.1 {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }
            } else if generationState.generationError != nil {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            } else if generationState.progress >= 1.0 && !generationState.generationStatus.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if !generationState.generationStatus.isEmpty {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
            }
        }
        .font(.title2)
    }
    
    private var statusMessage: String {
        if let error = generationState.generationError {
            return "Generation failed"
        } else if !generationState.generationStatus.isEmpty {
            return generationState.generationStatus
        } else if generationState.isGenerating {
            return "Starting generation..."
        } else {
            return "Ready to generate"
        }
    }
    
    private var statusSubMessage: String? {
        if generationState.isGenerating {
            if generationState.generateTexture {
                return "Generating with high-quality textures"
            } else {
                return "Generating geometry only"
            }
        }
        return nil
    }
}

#Preview {
    VStack(spacing: 20) {
        // Preview different states
        Group {
            // Idle state
            GenerationStatusView(generationState: {
                let state = GenerationState()
                return state
            }())
            
            // Generating state
            GenerationStatusView(generationState: {
                let state = GenerationState()
                state.isGenerating = true
                state.progress = 0.65
                state.currentTaskID = "abc123def456"
                state.generationStatus = "Generating 3D mesh..."
                return state
            }())
            
            // Error state
            GenerationStatusView(generationState: {
                let state = GenerationState()
                state.progress = 0.0
                state.generationError = "Network connection lost"
                return state
            }())
            
            // Completed state
            GenerationStatusView(generationState: {
                let state = GenerationState()
                state.progress = 1.0
                state.generationStatus = "Model generated successfully"
                return state
            }())
        }
    }
    .padding()
}