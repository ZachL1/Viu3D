import SwiftUI
import UIKit
import AVFoundation

// MARK: - Image Source Selection
enum ImageSource {
    case camera
    case photoLibrary
}

// MARK: - Enhanced Image Picker with Camera Support
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    let sourceType: UIImagePickerController.SourceType
    
    init(selectedImage: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType = .photoLibrary) {
        self._selectedImage = selectedImage
        self.sourceType = sourceType
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        
        // Camera specific settings
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.allowsEditing = true
        } else {
            picker.allowsEditing = true
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            // Use edited image if available, otherwise use original
            let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            
            if let image = selectedImage {
                // Compress and optimize the image
                let optimizedImage = ImageProcessor.processImage(image)
                parent.selectedImage = optimizedImage
                
                print("Image captured/selected - Size: \(image.size)")
                print("Optimized image size: \(optimizedImage.size)")
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Image Source Action Sheet
struct ImageSourcePicker: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var showingImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        EmptyView()
            .actionSheet(isPresented: $isPresented) {
                ActionSheet(
                    title: Text("Select Image Source"),
                    message: Text("Choose how you want to add an image"),
                    buttons: actionSheetButtons()
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                CameraImagePicker(selectedImage: $selectedImage, sourceType: imageSource)
            }
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(permissionAlertMessage)
            }
    }
    
    private func actionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Camera option (only if available)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            buttons.append(.default(Text("📷 Take Photo")) {
                checkCameraPermission()
            })
        }
        
        // Photo Library option
        buttons.append(.default(Text("📁 Choose from Library")) {
            imageSource = .photoLibrary
            showingImagePicker = true
        })
        
        // Cancel button
        buttons.append(.cancel())
        
        return buttons
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission already granted
            openCamera()
            
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        openCamera()
                    } else {
                        showPermissionDeniedAlert()
                    }
                }
            }
            
        case .denied, .restricted:
            showPermissionDeniedAlert()
            
        @unknown default:
            showPermissionDeniedAlert()
        }
    }
    
    private func openCamera() {
        imageSource = .camera
        showingImagePicker = true
    }
    
    private func showPermissionDeniedAlert() {
        permissionAlertMessage = "Camera access is required to take photos. Please enable camera access in Settings."
        showingPermissionAlert = true
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Image Processing Utilities
class ImageProcessor {
    
    /// Process and optimize image for 3D generation
    static func processImage(_ image: UIImage) -> UIImage {
        // First, resize to reasonable dimensions
        let resizedImage = resizeImage(image, to: APIConfig.maxImageSize)
        
        // Enhance contrast and brightness if needed
        let enhancedImage = enhanceImage(resizedImage)
        
        return enhancedImage
    }
    
    /// Resize image while maintaining aspect ratio
    static func resizeImage(_ image: UIImage, to maxSize: CGSize) -> UIImage {
        let ratio = min(maxSize.width / image.size.width, maxSize.height / image.size.height)
        
        // If image is already smaller, don't upscale
        guard ratio < 1.0 else { return image }
        
        let newSize = CGSize(
            width: image.size.width * ratio,
            height: image.size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Enhance image contrast and brightness
    static func enhanceImage(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        // Convert to CIImage for processing
        let ciImage = CIImage(cgImage: cgImage)
        
        // Apply subtle enhancements
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey)      // Slightly increase contrast
        filter?.setValue(0.05, forKey: kCIInputBrightnessKey)   // Slightly increase brightness
        filter?.setValue(1.05, forKey: kCIInputSaturationKey)   // Slightly increase saturation
        
        guard let outputImage = filter?.outputImage else { return image }
        
        // Convert back to UIImage
        let context = CIContext()
        guard let enhancedCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: enhancedCGImage)
    }
    
    /// Convert image to base64 for API transmission
    static func imageToBase64(_ image: UIImage, quality: CGFloat = 0.8) -> String {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            return ""
        }
        return imageData.base64EncodedString()
    }
    
    /// Get optimized image data size info
    static func getImageInfo(_ image: UIImage) -> (size: CGSize, dataSize: Int) {
        let size = image.size
        let dataSize = image.jpegData(compressionQuality: 0.8)?.count ?? 0
        return (size, dataSize)
    }
}

// MARK: - Preview Helpers
#Preview("Image Source Picker") {
    struct PreviewWrapper: View {
        @State private var selectedImage: UIImage?
        @State private var showingPicker = false
        
        var body: some View {
            VStack {
                Button("Show Image Picker") {
                    showingPicker = true
                }
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(
                ImageSourcePicker(
                    selectedImage: $selectedImage,
                    isPresented: $showingPicker
                )
            )
        }
    }
    
    return PreviewWrapper()
}