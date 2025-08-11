//
//  ContentView.swift
//  Viu3D
//
//  Created by zach duan on 2025/8/5.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var modelData = ModelData()
    @StateObject private var generationState = GenerationState()
    @State private var showingDocumentPicker = false
    @State private var showingModelInfo = false
    @State private var showingHelp = false
    @State private var selectedFileURL: URL?
    @State private var filePickerError: String?
    
    private var taskManager: GenerationTaskManager {
        GenerationTaskManager(generationState: generationState)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 3D模型视图
                SceneKitView(modelData: modelData)
                    .clipped()
                
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
                        Text("Viu3D")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        Spacer()
                        
                        Text("AI 3D Generator")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(radius: 1)
                        
                        Spacer()
                        
                        // 帮助按钮
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.orange.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        // 模型信息按钮
                        Button(action: { showingModelInfo.toggle() }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.green.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
//                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    Spacer()
                }
                
                // 模型信息面板 - 右侧滑出
                if showingModelInfo {
                    HStack {
                        Spacer()
                        
                        VStack {
                            Spacer()
                            
                            ModelInfoPanel(modelData: modelData)
                                .frame(width: min(geometry.size.width * 0.8, 320))
                                .padding(.trailing, 16)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
                
                // 控制面板 - 底部滑出
                VStack {
                    Spacer()
                    
                    if !showingModelInfo {
                        VStack(spacing: 12) {
                            // 生成状态显示
                            GenerationStatusView(generationState: generationState)
                            
                            // 生成输入界面
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
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // 手势提示 - 右上角（仅在没有显示其他面板时显示）
                if !showingModelInfo && !generationState.isGenerating {
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
                        .padding(.top, 120)
                        
                        Spacer()
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
        .animation(.easeInOut(duration: 0.3), value: showingModelInfo)
        .animation(.easeInOut(duration: 0.3), value: generationState.isGenerating)
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
                // 清除生成状态，显示新模型
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    generationState.reset()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
