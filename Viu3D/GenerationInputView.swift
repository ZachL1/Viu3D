import SwiftUI

struct GenerationInputView: View {
    @ObservedObject var generationState: GenerationState
    @State private var showingImageSourcePicker = false
    
    var onGenerate: (() -> Void)?
    var onFileSelect: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Mode Selector
            Picker("Generation Mode", selection: $generationState.currentMode) {
                ForEach(GenerationMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(generationState.isGenerating)
            
            // Input Area
            inputArea
            
            // Texture Option
            HStack {
                Image(systemName: generationState.generateTexture ? "checkmark.square.fill" : "square")
                    .foregroundColor(generationState.generateTexture ? .blue : .gray)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            generationState.generateTexture.toggle()
                        }
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate Texture")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text("Higher quality with colors and materials")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
            .disabled(generationState.isGenerating)
            
            // Generate Button
            generateButton
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
                    .background(
            ImageSourcePicker(
                selectedImage: $generationState.selectedImage,
                isPresented: $showingImageSourcePicker
            )
        )
    }
    
    @ViewBuilder
    private var inputArea: some View {
        switch generationState.currentMode {
        case .text:
            textInputArea
        case .image:
            imageInputArea
        case .file:
            fileInputArea
        }
    }
    
    private var textInputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Describe your 3D model")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextEditor(text: $generationState.textInput)
                .frame(maxHeight: 100)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .disabled(generationState.isGenerating)
            
            Text("Example: \"a cute red dragon with wings\"")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var imageInputArea: some View {
        VStack(spacing: 12) {
            Text("Select an image to generate 3D model")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let image = generationState.selectedImage {
                // Image Preview with Info
                VStack(spacing: 8) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
                    // Image Info
                    HStack {
                        let imageInfo = ImageProcessor.getImageInfo(image)
                        Text("Size: \(Int(imageInfo.size.width))×\(Int(imageInfo.size.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Data: \(ByteCountFormatter.string(fromByteCount: Int64(imageInfo.dataSize), countStyle: .file))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button("📷 Retake") {
                            showingImageSourcePicker = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .disabled(generationState.isGenerating)
                        
                        Button("🗑️ Remove") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                generationState.selectedImage = nil
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .disabled(generationState.isGenerating)
                    }
                }
            } else {
                // Image Selection Area
                VStack(spacing: 12) {
                    Button(action: { showingImageSourcePicker = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("Select Image")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            
                            Text("Camera or Photo Library")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                    .disabled(generationState.isGenerating)
                    
                    // Quick action hints
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Take Photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Choose Photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var fileInputArea: some View {
        VStack(spacing: 12) {
            Text("Load 3D model from file")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(action: {
                onFileSelect?()
            }) {
                HStack {
                    Image(systemName: "folder")
                        .font(.title2)
                    Text("Browse Files")
                        .font(.body)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .disabled(generationState.isGenerating)
            
            Text("Supports: .usdz, .glb, .gltf, .obj, .dae")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var generateButton: some View {
        Button(action: {
            onGenerate?()
        }) {
            HStack {
                if generationState.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Generating...")
                } else {
                    Image(systemName: "wand.and.stars")
                    Text("Generate 3D Model")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                generationState.canGenerate() && !generationState.isGenerating 
                ? Color.blue 
                : Color.gray
            )
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(!generationState.canGenerate() || generationState.isGenerating)
    }
}



#Preview {
    GenerationInputView(
        generationState: GenerationState(),
        onGenerate: { print("Generate tapped") },
        onFileSelect: { print("File select tapped") }
    )
    .padding()
}
