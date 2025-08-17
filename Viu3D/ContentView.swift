//
//  ContentView.swift
//  Viu3D
//
//  Created by zach duan on 2025/8/5.
//

import SwiftUI

// MARK: - UI Mode Enum
enum UIMode {
    case creation  // 创作界面：没有模型，显示控制面板
    case browsing  // 浏览界面：有模型，显示模型信息面板
}

struct ContentView: View {
    @StateObject private var modelData = ModelData()
    @StateObject private var generationState = GenerationState()
    @StateObject private var historyManager = HistoryManager.shared
    @State private var showingDocumentPicker = false
    @State private var showingModelInfo = false
    @State private var showingHelp = false
    @State private var showingHistory = false
    @State private var selectedFileURL: URL?
    @State private var filePickerError: String?
    @State private var currentHistory: GenerationHistory?
    @State private var uiMode: UIMode = .creation
    
    private var taskManager: GenerationTaskManager {
        GenerationTaskManager(generationState: generationState)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 3D模型视图（仅在浏览模式且有模型时显示）
                if uiMode == .browsing && modelData.modelURL != nil {
                    SceneKitView(modelData: modelData)
                        .clipped()
                        .transition(.opacity)
                } else {
                    // 创作界面的背景
                    Color.clear
                        .ignoresSafeArea(.all)
                }
                
                // 加载指示器
                if modelData.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("加载中...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                }
                
                // 错误提示
                if let errorMessage = modelData.errorMessage ?? filePickerError {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom))
                        
                        Spacer().frame(height: 100)
                    }
                }
                
                // 顶部工具栏
                VStack {
                    HStack {
                        // History Button (替换原来的Viu3D标题)
                        Button(action: { showingHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("AI3D")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(radius: 1)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // 创作按钮（仅在浏览界面显示）
                            Button(action: { switchToCreationMode() }) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
//                            // 帮助按钮
//                            Button(action: { showingHelp = true }) {
//                                Image(systemName: "questionmark.circle")
//                                    .font(.title2)
//                                    .foregroundColor(.white)
//                                    .padding(8)
//                                    .background(Color.orange.opacity(0.3))
//                                    .clipShape(Circle())
//                            }
                        }
                        

                    }
                    .padding(.horizontal)
//                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    Spacer()
                }
                
                // 底部面板区域 - 根据UI模式显示不同面板
                VStack {
                    Spacer()
                    
                    // 生成状态显示（两种模式都显示）
                    if generationState.isGenerating || !generationState.generationStatus.isEmpty || generationState.generationError != nil {
                        GenerationStatusView(generationState: generationState)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // 根据UI模式显示对应的面板
                    if uiMode == .creation {
                        // 创作界面：显示生成输入面板（不可收起）
                        VStack(spacing: 12) {
                            GenerationInputView(
                                generationState: generationState,
                                onGenerate: {
                                    Task {
                                        await taskManager.startGeneration()
                                    }
                                },
                                onFileSelect: {
                                    showingDocumentPicker = true
                                }
                            )
                        }
                        .padding(.horizontal)
                        
                    } else if uiMode == .browsing {
                        // 浏览界面：显示模型信息面板（可滑动收起）
                        EnhancedModelInfoPanel(
                            modelData: modelData,
                            historyManager: historyManager,
                            isExpanded: $showingModelInfo,
                            currentHistory: $currentHistory
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // 手势提示 - 右上角（仅在浏览界面且没有显示其他面板时显示）
                if uiMode == .browsing && !showingHistory && !generationState.isGenerating {
                    VStack {
                        HStack {
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("💡 提示")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("• 拖拽旋转")
                                    .font(.caption2)
                                Text("• 双指缩放")
                                    .font(.caption2)
                                Text("• 双指拖拽移动")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(.trailing)
                        }
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                }
                
                // 历史记录面板 - 左侧滑出 (类似ChatGPT)
                if showingHistory {
                    HStack {
                        HistoryPanel(
                            historyManager: historyManager,
                            isPresented: $showingHistory,
                            onModelSelect: { history in
                                loadHistoryModel(history)
                            }
                        )
                        .frame(width: min(geometry.size.width * 0.85, 350))
                        .transition(.move(edge: .leading))
                        
                        Spacer()
                    }
                    .background(Color.black.opacity(0.3))
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingHistory = false
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .animation(.easeInOut(duration: 0.3), value: showingHistory)
        .animation(.easeInOut(duration: 0.3), value: showingModelInfo)
        .animation(.easeInOut(duration: 0.3), value: generationState.isGenerating)
        .animation(.easeInOut(duration: 0.3), value: uiMode)
        .statusBarHidden()
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(selectedFileURL: $selectedFileURL) { error in
                filePickerError = error
            }
        }
        .sheet(isPresented: $showingHelp) {
            HelpTipsView(isPresented: $showingHelp)
        }
        .onChange(of: selectedFileURL) { newURL in
            if let url = newURL {
                modelData.loadModel(from: url)
                selectedFileURL = nil // 重置选择状态
            }
        }
        .onChange(of: generationState.currentMode) { mode in
            if mode == .file {
                showingDocumentPicker = true
            }
        }
        .onChange(of: modelData.errorMessage) { _ in
            // 自动清除模型加载错误消息
            if modelData.errorMessage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        modelData.errorMessage = nil
                    }
                }
            }
        }
        .onChange(of: filePickerError) { _ in
            // 自动清除文件选择错误消息
            if filePickerError != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        filePickerError = nil
                    }
                }
            }
        }
        .onChange(of: generationState.generationError) { _ in
            // 自动清除生成错误消息
            if generationState.generationError != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        generationState.generationError = nil
                    }
                }
            }
        }
        .onChange(of: generationState.generatedModelURL) { newURL in
            // 加载新生成的模型
            if let url = newURL {
                modelData.loadModel(from: url)
                
                // 添加到历史记录并设置为当前历史
                addToHistory(url: url)
                
                // 切换到浏览界面
                switchToBrowsingMode()
                
                // 清除生成状态，显示新模型
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    generationState.reset()
                }
            }
        }
        .onAppear {
            // 应用启动时添加demo历史记录
            addDemoHistoryIfNeeded()
        }
        .onChange(of: modelData.modelURL) { newURL in
            // 当模型URL变化时，如果是新模型且没有对应的历史记录，更新模型信息面板
            if newURL != nil && uiMode == .browsing {
                showingModelInfo = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadHistoryModel(_ history: GenerationHistory) {
        // 检查文件是否还存在
        guard FileManager.default.fileExists(atPath: history.modelURL.path) else {
            print("ContentView: Model file no longer exists, removing from history")
            historyManager.deleteHistory(history)
            return
        }
        
        modelData.loadModel(from: history.modelURL)
        currentHistory = history
        switchToBrowsingMode()
        showingModelInfo = true // 自动展开模型信息面板
    }
    
    // MARK: - UI Mode Management
    
    private func switchToCreationMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            uiMode = .creation
            showingModelInfo = false
            currentHistory = nil
        }
        modelData.clearModel()
    }
    
    private func switchToBrowsingMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            uiMode = .browsing
        }
    }
    
    private func addDemoHistoryIfNeeded() {
        // 简单逻辑：历史记录为空时添加demo，不为空时不添加
        if !historyManager.hasHistory() {
            if let defaultURL = Bundle.main.url(forResource: "plane", withExtension: "usdz") {
                historyManager.addHistory(
                    modelURL: defaultURL,
                    generationType: .text,
                    promptText: "plane",
                    promptImage: nil,
                    generateTexture: false,
                    demo: true
                )
                print("ContentView: Added demo history for plane.usdz")
            }
        }
    }
    
    private func addToHistory(url: URL) {
        let generationType: GenerationHistory.GenerationType
        let promptText: String?
        let promptImage: UIImage?
        
        switch generationState.currentMode {
        case .text:
            generationType = .text
            promptText = generationState.textInput.isEmpty ? nil : generationState.textInput
            promptImage = nil
        case .image:
            generationType = .image
            promptText = nil
            promptImage = generationState.selectedImage
        case .file:
            generationType = .file
            promptText = nil
            promptImage = nil
        }
        
        historyManager.addHistory(
            modelURL: url,
            generationType: generationType,
            promptText: promptText,
            promptImage: promptImage,
            generateTexture: generationState.generateTexture
        )
        
        // 更新当前历史记录（设置为刚添加的记录）
        DispatchQueue.main.async {
            if let newHistory = self.historyManager.histories.first {
                self.currentHistory = newHistory
            }
        }
    }
}

#Preview {
    ContentView()
}
