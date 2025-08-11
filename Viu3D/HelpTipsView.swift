import SwiftUI

struct HelpTipsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("AI 3D Generation Guide")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Transform text and images into 3D models")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Text Generation Section
                    HelpSection(
                        icon: "text.cursor",
                        title: "Text to 3D",
                        color: .green
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Write a detailed description of your object")
                            Text("• Be specific about shape, color, and style")
                            Text("• Example: \"a cute red dragon with golden wings\"")
                            Text("• Enable texture for colorful, detailed models")
                        }
                        .font(.body)
                    }
                    
                    // Image Generation Section
                    HelpSection(
                        icon: "camera",
                        title: "Image to 3D",
                        color: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Take a photo or choose from your library")
                            Text("• Use clear, well-lit images for best results")
                            Text("• Objects with simple backgrounds work better")
                            Text("• The app will automatically optimize your image")
                        }
                        .font(.body)
                    }
                    
                    // Camera Tips Section
                    HelpSection(
                        icon: "camera.viewfinder",
                        title: "Camera Tips",
                        color: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Good lighting is essential")
                            Text("• Keep the object centered in frame")
                            Text("• Avoid reflective or transparent surfaces")
                            Text("• Multiple angles can help (future feature)")
                        }
                        .font(.body)
                    }
                    
                    // Texture Options Section
                    HelpSection(
                        icon: "paintbrush",
                        title: "Texture Options",
                        color: .purple
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("✅ Texture ON: Colorful, detailed models")
                            Text("⚡ Texture OFF: Faster, geometry-only models")
                            Text("• Texture generation takes more time")
                            Text("• Perfect for viewing and printing")
                        }
                        .font(.body)
                    }
                    
                    // File Support Section
                    HelpSection(
                        icon: "doc",
                        title: "File Support",
                        color: .indigo
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Supported formats:")
                            Text("• .usdz (Apple 3D format)")
                            Text("• .glb/.gltf (Web 3D standard)")
                            Text("• .obj, .dae (Legacy formats)")
                        }
                        .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct HelpSection<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    let content: Content
    
    init(icon: String, title: String, color: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    HelpTipsView(isPresented: .constant(true))
}