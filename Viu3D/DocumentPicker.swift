import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?
    @Environment(\.presentationMode) var presentationMode
    var onError: ((String) -> Void)?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // 支持的文件类型：USDZ, USD, DAE, OBJ, GLTF, GLB
        let supportedTypes: [UTType] = [
            UTType(filenameExtension: "usdz") ?? UTType.data,
            UTType(filenameExtension: "usd") ?? UTType.data,
            UTType(filenameExtension: "dae") ?? UTType.data,
            UTType(filenameExtension: "obj") ?? UTType.data,
            UTType(filenameExtension: "gltf") ?? UTType.data,
            UTType(filenameExtension: "glb") ?? UTType.data
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { 
                print("No URL selected")
                return 
            }
            
            print("Selected file: \(url.path)")
            
            // 开始访问安全作用域资源
            let isSecurityScoped = url.startAccessingSecurityScopedResource()
            
            // 如果无法访问安全作用域资源，提供用户友好的错误信息
            if !isSecurityScoped {
                print("Failed to start accessing security scoped resource")
                DispatchQueue.main.async {
                    self.parent.onError?("无法访问所选文件，请确保文件未被其他应用占用")
                }
                return
            }
            
            // 检查文件是否可读
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("File does not exist at path: \(url.path)")
                url.stopAccessingSecurityScopedResource()
                DispatchQueue.main.async {
                    self.parent.onError?("无法访问所选文件")
                }
                return
            }
            
            // 验证文件格式
            let fileExtension = url.pathExtension.lowercased()
            let supportedExtensions = ["usdz", "usd", "dae", "obj", "gltf", "glb"]
            guard supportedExtensions.contains(fileExtension) else {
                print("Unsupported file format: \(fileExtension)")
                url.stopAccessingSecurityScopedResource()
                DispatchQueue.main.async {
                    self.parent.onError?("不支持的文件格式: .\(fileExtension)")
                }
                return
            }
            
            print("File validation successful, using original URL")
            
            // 直接使用原始URL，不复制文件
            // 注意：这里不调用stopAccessingSecurityScopedResource()
            // 因为我们需要保持对文件的访问权限，直到不再需要它
            DispatchQueue.main.async {
                self.parent.selectedFileURL = url
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}