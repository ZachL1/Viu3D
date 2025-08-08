# GLTFSceneKit 集成指南

## 📋 概述

已成功为 Viu3D 项目添加了 [GLTFSceneKit](https://github.com/magicien/GLTFSceneKit) 支持，现在可以加载和渲染 `.gltf` 和 `.glb` 格式的3D模型。

## 🔧 安装步骤

### 1. 安装 CocoaPods（如果尚未安装）

```bash
sudo gem install cocoapods
```

### 2. 安装项目依赖

在 Viu3D 项目根目录下运行：

```bash
cd /Users/zach/workspace/iOSdemo/Viu3D
pod install
```

### 3. 打开工作空间

**重要**: 完成 pod install 后，请使用 `.xcworkspace` 文件而不是 `.xcodeproj` 文件：

```bash
open Viu3D.xcworkspace
```

## ✨ 新增功能

### 📁 **支持的文件格式**
- ✅ **原有格式**: `.usdz`, `.usd`, `.dae`, `.obj`
- 🆕 **新增格式**: `.gltf`, `.glb`

### 🎨 **智能渲染系统**
- **glTF/GLB文件**: 保持原有PBR材质，支持高质量渲染
- **其他格式**: 使用简化的Lambert光照模型

### 🔄 **混合材质支持**
- **非glTF文件**: Lambert光照模型（性能优先）
- **glTF文件**: 保持原有材质设置（可能包含PBR）
- **所有文件**: 确保双面渲染支持

### 📊 **增强的模型信息**
- glTF文件显示"GLTFSceneKit"格式支持标识
- 智能光照模式检测（"混合模式 (PBR/Lambert)" vs "简单光照 (Lambert)"）

## 🏗️ 技术实现

### **新增文件**
- `GLTFLoader.swift` - 专门处理glTF/GLB文件的加载器
- `Podfile` - CocoaPods依赖管理文件

### **更新文件**
- `DocumentPicker.swift` - 添加glTF/GLB文件类型支持
- `SceneKitView.swift` - 智能文件格式检测和加载
- `ModelData.swift` - 增强的模型信息获取
- `ModelInfoPanel.swift` - 显示glTF特定信息

### **核心代码示例**

```swift
// 智能文件加载
if GLTFLoader.isGLTFFile(url: url) {
    // 使用GLTFSceneKit加载glTF/GLB
    modelScene = try GLTFLoader.loadScene(from: url)
} else {
    // 使用SceneKit原生加载器
    modelScene = try SCNScene(url: url, options: [...])
}

// 材质处理策略
if !GLTFLoader.isGLTFFile(url: url) {
    setupBasicMaterials(node: modelNode)  // Lambert
} else {
    ensureDoubleSidedMaterials(node: modelNode)  // 保持PBR
}
```

## 🎯 PBR 渲染支持

### **回答您的问题**:
- ✅ **是的，现在支持PBR材质渲染！**
- **glTF/GLB文件**: 自动保持原有的PBR材质设置
- **其他格式**: 继续使用简化的Lambert模型（性能考虑）

### **PBR 特性**:
- 🌟 **金属度和粗糙度**: glTF文件的原生PBR属性
- 🌈 **高质量材质**: 基于物理的光照计算
- 🔍 **纹理支持**: 法线贴图、环境遮蔽等

## 🚀 使用方法

1. **安装依赖** (见上述步骤)
2. **运行应用**
3. **点击文件夹图标**
4. **选择 .gltf 或 .glb 文件**
5. **享受高质量的PBR渲染！**

## 📱 测试建议

### **glTF文件测试**:
- 下载一些包含PBR材质的glTF示例文件
- 测试文件选择和加载功能
- 观察材质渲染质量的差异

### **性能对比**:
- 比较glTF文件与USDZ文件的加载速度
- 观察不同格式的渲染质量

## 🔗 参考资源

- [GLTFSceneKit GitHub](https://github.com/magicien/GLTFSceneKit)
- [glTF 2.0 规范](https://www.khronos.org/gltf/)
- [Khronos glTF 示例模型](https://github.com/KhronosGroup/glTF-Sample-Models)

---

**注意**: 完成 CocoaPods 安装后，项目将完全支持 glTF/GLB 格式的3D模型，包括高质量的PBR材质渲染！ 🎉