# Viu3D - AI-Powered 3D Model Generator & Viewer

<div align="center">

📱 **A powerful iOS app for generating, viewing, and experiencing 3D models**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Supported Formats](#supported-formats) • [Requirements](#requirements)

</div>

## ✨ Features

### 🎨 AI Model Generation
- **Text-to-3D**: Generate 3D models from text descriptions
- **Image-to-3D**: Create 3D models from photos
- **Texture Control**: Optional high-quality texture generation
- **Camera Integration**: Take photos directly for 3D generation

### 🌟 3D Model Viewing
- **Interactive 3D Viewer**: Rotate, scale, and explore models
- **Multi-format Support**: USDZ, GLB, GLTF, DAE, OBJ
- **Real-time Rendering**: Smooth 60fps performance with SceneKit
- **File Import**: Load models from Files app or other sources

### 🥽 AR Preview
- **Immersive AR Experience**: View models in your real environment
- **Smart Placement**: Automatic plane detection for realistic positioning
- **Gesture Controls**: Intuitive pinch, rotate, and drag interactions
- **Scale Adjustment**: Automatic sizing for optimal viewing

### 📱 Modern UI
- **SwiftUI Interface**: Clean, native iOS design
- **Dual Modes**: Creation and browsing modes
- **History Management**: Keep track of all generated models
- **Editable Names**: Customize project names
- **Collapsible Panels**: Optimized for model viewing

### 📋 TODO
- [ ] 🎨 UI Improvements
- [ ] 📤 Export & Sharing
- [ ] 🖨️ 3D Printing Integration
- [ ] ...

<!-- #### 🎨 UI Improvements
- [ ] **Dark Mode Support**: Full dark theme implementation
- [ ] **Accessibility**: VoiceOver and larger text support
- [ ] **Animations**: Enhanced transitions and micro-interactions
- [ ] **Customizable Themes**: User-selectable color schemes
- [ ] **iPad Optimization**: Better layout for larger screens

#### 📤 Export & Sharing
- [ ] **Multi-format Export**: Support OBJ, STL, PLY export
- [ ] **Cloud Storage**: iCloud Drive integration
- [ ] **Share Extensions**: Direct sharing to social media
- [ ] **Batch Operations**: Export multiple models at once
- [ ] **Compression Options**: Optimized file sizes

#### 🖨️ 3D Printing Integration
- [ ] **Bambu Lab Connect**: Direct printer connection
- [ ] **Print Preparation**: Automatic support generation
- [ ] **Slicing Integration**: Built-in G-code generation
- [ ] **Material Library**: Filament compatibility check
- [ ] **Print Queue**: Manage multiple print jobs

#### 🔧 Advanced Features
- [ ] **Model Editing**: Basic mesh modification tools
- [ ] **Animation Support**: Keyframe animation viewer
- [ ] **Physics Simulation**: Real-time collision detection
- [ ] **Collaborative Features**: Model sharing and comments
- [ ] **Version Control**: Track model iterations

#### 🤖 AI Enhancements
- [ ] **Style Transfer**: Apply artistic styles to models
- [ ] **Auto-rigging**: Automatic skeleton generation
- [ ] **LOD Generation**: Multiple detail levels
- [ ] **Texture Upscaling**: AI-powered texture enhancement
- [ ] **Scene Composition**: Multi-object scene generation -->

## 🚀 Installation

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- CocoaPods

### Setup
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Viu3D
   ```

2. **Install dependencies**
   ```bash
   pod install
   ```

3. **Open the workspace**
   ```bash
   open Viu3D.xcworkspace
   ```

4. **Configure API (Optional)**
   - Update API endpoints in `GenerationModels.swift`
   - Configure your backend URL in `APIConfig`

5. **Build and run**
   - Select your target device or simulator
   - Press ⌘+R to build and run

## 📖 Usage

### Getting Started
1. **Launch the app** - Start in Creation Mode
2. **Choose generation method**:
   - 📝 **Text**: Enter a description (e.g., "A red sports car")
   - 📷 **Image**: Take a photo or select from library
   - 📁 **File**: Import existing 3D model

3. **Generate** - Wait for AI processing
4. **View & Interact** - Automatically switches to Browsing Mode

### AR Preview
1. Open any model in Browsing Mode
2. Tap the **AR Preview** button in the model info panel
3. Point camera at a flat surface
4. Tap to place the model
5. Use gestures to interact:
   - **Pinch**: Scale the model
   - **Rotate**: Change orientation
   - **Drag**: Move position

### History Management
- Access via the **History** button (top-left)
- View all previously generated models
- Tap any item to load the model
- Long-press to delete individual items
- Clear all history with confirmation

## 📄 Supported Formats

| Format | Import | Export | AR Support |
|--------|--------|--------|------------|
| USDZ   | ✅     | ✅     | ✅         |
| USD    | ✅     | ❌     | ✅         |
| GLB    | ✅     | ✅     | ✅         |
| GLTF   | ✅     | ✅     | ✅         |
| DAE    | ✅     | ❌     | ✅         |
| OBJ    | ✅     | ❌     | ✅         |

## 🛠 Requirements

### System Requirements
- **iOS**: 17.0 or later
- **Device**: iPhone/iPad with A12 Bionic chip or newer
- **Camera**: Required for AR features and image-to-3D
- **Storage**: 1GB+ recommended for model files

### Permissions
- **Camera**: For AR preview and photo capture
- **Photo Library**: For image-to-3D generation
- **Files Access**: For importing/exporting models

## 🏗 Architecture

### Core Components
- **ContentView**: Main app coordinator and UI state management
- **ModelData**: 3D model loading and property management
- **ARPreviewView**: ARKit-based augmented reality viewer
- **GenerationService**: AI model generation and API communication
- **HistoryManager**: Persistent storage and model organization

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **SceneKit**: High-performance 3D rendering
- **ARKit + RealityKit**: Augmented reality experiences
- **GLTFSceneKit**: glTF/GLB format support
- **Swift Concurrency**: Async/await for smooth performance

## 🔧 Configuration

### API Setup
Update the API configuration in `GenerationModels.swift`:

```swift
struct APIConfig {
    static let baseURL = "https://your-api-endpoint.com"
    static let textToModelEndpoint = "/generate/text"
    static let imageToModelEndpoint = "/generate/image"
    // ... other settings
}
```

### Model Storage
- Generated models are saved to the app's Documents directory
- History metadata is stored in UserDefaults
- Files are automatically cleaned up when history items are deleted

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [**SceneKit**](https://developer.apple.com/documentation/scenekit/) - 3D rendering engine
- [**GLTFSceneKit**](https://github.com/magicien/GLTFSceneKit) - GLB/GLTF format support
- [**Apple's ARKit**](https://developer.apple.com/augmented-reality/arkit/) - Augmented reality capabilities

---

<div align="center">

**Made with ❤️ for the 3D community**

[Report Bug](issues) • [Request Feature](issues) • [Documentation](wiki)

</div>
