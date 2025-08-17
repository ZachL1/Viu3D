import Foundation
import UIKit

// MARK: - History Data Models

struct GenerationHistory: Codable, Identifiable {
    let id: String
    let modelURL: URL
    let createdAt: Date
    let generationType: GenerationType
    let promptText: String?        // 文本提示词（如果是文本生成）
    let promptImageData: Data?     // 图像数据（如果是图像生成）
    let generateTexture: Bool      // 是否生成纹理
    var modelName: String          // 模型显示名称（可编辑）
    let fileSize: Int64           // 文件大小（字节）
    
    enum GenerationType: String, Codable, CaseIterable {
        case text = "text"
        case image = "image" 
        case file = "file"
        
        var displayName: String {
            switch self {
            case .text: return "Text to 3D"
            case .image: return "Image to 3D"
            case .file: return "File Import"
            }
        }
        
        var iconName: String {
            switch self {
            case .text: return "text.bubble"
            case .image: return "photo"
            case .file: return "folder"
            }
        }
    }
    
    // 计算属性
    var promptImage: UIImage? {
        guard let data = promptImageData else { return nil }
        return UIImage(data: data)
    }
    
    var formattedFileSize: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(createdAt) {
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: createdAt))"
        } else if Calendar.current.isDateInYesterday(createdAt) {
            formatter.timeStyle = .short
            return "Yesterday \(formatter.string(from: createdAt))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: createdAt)
        }
    }
}

// MARK: - History Manager

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var histories: [GenerationHistory] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "generation_histories"
    private let maxHistoryCount = 100 // 最大保存100条记录
    
    private init() {
        loadHistories()
    }
    
    // MARK: - Public Methods
    
    func addHistory(
        modelURL: URL,
        generationType: GenerationHistory.GenerationType,
        promptText: String? = nil,
        promptImage: UIImage? = nil,
        generateTexture: Bool = false,
        demo: Bool = false
    ) {
        let id = UUID().uuidString
        let modelName = generateModelName(for: generationType, demo: demo)
        let fileSize = getFileSize(at: modelURL)
        
        let history = GenerationHistory(
            id: id,
            modelURL: modelURL,
            createdAt: Date(),
            generationType: generationType,
            promptText: promptText,
            promptImageData: promptImage?.jpegData(compressionQuality: 0.8),
            generateTexture: generateTexture,
            modelName: modelName,
            fileSize: fileSize
        )
        
        DispatchQueue.main.async {
            self.histories.insert(history, at: 0) // 插入到最前面
            
            // 限制历史记录数量
            if self.histories.count > self.maxHistoryCount {
                self.histories = Array(self.histories.prefix(self.maxHistoryCount))
            }
            
            self.saveHistories()
        }
        
        print("HistoryManager: Added new history - \(modelName)")
    }
    
    func deleteHistory(_ history: GenerationHistory) {
        DispatchQueue.main.async {
            self.histories.removeAll { $0.id == history.id }
            self.saveHistories()
        }
        
        // 在主线程操作完成后删除文件
        DispatchQueue.global(qos: .background).async {
            self.deleteModelFile(at: history.modelURL)
        }
    }
    
    func clearAllHistory() {
        // 获取需要删除的文件列表
        let urlsToDelete = histories.map { $0.modelURL }
        
        DispatchQueue.main.async {
            self.histories.removeAll()
            self.saveHistories()
        }
        
        // 在后台删除所有模型文件
        DispatchQueue.global(qos: .background).async {
            for url in urlsToDelete {
                self.deleteModelFile(at: url)
            }
        }
    }
    
    func updateModelName(historyId: String, newName: String) {
        DispatchQueue.main.async {
            if let index = self.histories.firstIndex(where: { $0.id == historyId }) {
                self.histories[index].modelName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                self.saveHistories()
                print("HistoryManager: Updated model name to '\(newName)'")
            }
        }
    }
    
    func hasHistory() -> Bool {
        return userDefaults.data(forKey: historyKey) != nil
    }
    
    // MARK: - Private Methods
    
    private func loadHistories() {
        guard let data = userDefaults.data(forKey: historyKey) else {
            print("HistoryManager: No saved histories found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let savedHistories = try decoder.decode([GenerationHistory].self, from: data)
            
            DispatchQueue.main.async {
                // 过滤掉文件不存在的记录（但保留Bundle资源）
                self.histories = savedHistories.filter { history in
                    // Bundle资源始终保留
                    if history.modelURL.path.contains(Bundle.main.bundlePath) {
                        return true
                    }
                    // 其他文件检查是否存在
                    return FileManager.default.fileExists(atPath: history.modelURL.path)
                }
                print("HistoryManager: Loaded \(self.histories.count) histories")
            }
        } catch {
            print("HistoryManager: Failed to load histories - \(error)")
        }
    }
    
    private func saveHistories() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(histories)
            userDefaults.set(data, forKey: historyKey)
            print("HistoryManager: Saved \(histories.count) histories")
        } catch {
            print("HistoryManager: Failed to save histories - \(error)")
        }
    }
    
    private func generateModelName(for type: GenerationHistory.GenerationType, demo: Bool?) -> String {
        // 为demo plane特殊处理
        if demo == true && type == .text {
            return "Demo Project (text to 3D)"
        }
        else if demo == true && type == .image {
            return "Demo Project (image to 3D)"
        }
        
        // 生成Project N格式的名称
        let projectNumber = histories.count
        return "Project \(projectNumber)"
    }
    
    private func getFileSize(at url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            print("HistoryManager: Failed to get file size - \(error)")
            return 0
        }
    }
    
    private func deleteModelFile(at url: URL) {
        do {
            // 检查文件是否存在
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("HistoryManager: File does not exist at path: \(url.path)")
                return
            }
            
            // 检查是否是内置资源文件（Bundle资源不应删除）
            if url.path.contains(Bundle.main.bundlePath) {
                print("HistoryManager: Skipping deletion of bundle resource: \(url.lastPathComponent)")
                return
            }
            
            // 删除文件
            try FileManager.default.removeItem(at: url)
            print("HistoryManager: Successfully deleted model file: \(url.lastPathComponent)")
            
        } catch {
            print("HistoryManager: Failed to delete model file at \(url.path) - \(error)")
        }
    }
}

// MARK: - Extensions

extension GenerationHistory {
    static func mock() -> GenerationHistory {
        return GenerationHistory(
            id: UUID().uuidString,
            modelURL: URL(fileURLWithPath: "/tmp/mock.glb"),
            createdAt: Date(),
            generationType: .text,
            promptText: "A cute rabbit eating carrots",
            promptImageData: nil,
            generateTexture: true,
            modelName: "Cute Rabbit",
            fileSize: 1024000
        )
    }
}
