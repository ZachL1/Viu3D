import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?
    @Environment(\.presentationMode) var presentationMode
    var onError: ((String) -> Void)?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // 支持的文件类型：USDZ, USD, DAE, OBJ
        let supportedTypes: [UTType] = [
            UTType(filenameExtension: "usdz") ?? UTType.data,
            UTType(filenameExtension: "usd") ?? UTType.data,
            UTType(filenameExtension: "dae") ?? UTType.data,
            UTType(filenameExtension: "obj") ?? UTType.data
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
            
            // 确保在函数结束时停止访问
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // 检查文件是否可读
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("File does not exist at path: \(url.path)")
                DispatchQueue.main.async {
                    self.parent.onError?("无法访问所选文件")
                }
                return
            }
            
            // 获取应用的Documents目录
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Cannot access Documents directory")
                DispatchQueue.main.async {
                    self.parent.onError?("无法访问应用文档目录")
                }
                return
            }
            
            // 创建唯一的文件名以避免冲突
            let fileName = url.lastPathComponent
            let destinationURL = documentsPath.appendingPathComponent(fileName)
            
            do {
                // 如果目标文件已存在，先删除
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Removed existing file at: \(destinationURL.path)")
                }
                
                // 复制文件到Documents目录
                try FileManager.default.copyItem(at: url, to: destinationURL)
                print("Successfully copied file to: \(destinationURL.path)")
                
                // 验证复制是否成功
                guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                    print("File copy verification failed")
                    DispatchQueue.main.async {
                        self.parent.onError?("文件复制验证失败")
                    }
                    return
                }
                
                // 在主线程上更新UI
                DispatchQueue.main.async {
                    self.parent.selectedFileURL = destinationURL
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
                
            } catch {
                print("Error copying file: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.parent.onError?("文件复制失败: \(error.localizedDescription)")
                }
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}