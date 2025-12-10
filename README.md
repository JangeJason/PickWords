# PickWords 📸

一款简洁的 iOS 英语单词学习应用。拍摄生活中的物品，AI 自动识别并记录对应的英文单词。

## 功能特性

- 📷 **拍照识别** - 拍摄任意物品，AI 自动识别
- 📝 **单词记录** - 保存图片与对应英文单词
- 📚 **单词列表** - 浏览所有已学习的单词
- 💾 **本地存储** - 数据安全存储在设备本地

## 技术栈

- **语言**: Swift
- **UI**: SwiftUI
- **图像识别**: Apple Vision Framework
- **数据存储**: SwiftData
- **最低版本**: iOS 16.0

## 项目结构

```
PickWords/
├── App/                    # 应用入口
├── Views/                  # 视图层
│   ├── ContentView.swift
│   ├── CameraView.swift
│   ├── WordListView.swift
│   └── WordDetailView.swift
├── Models/                 # 数据模型
│   └── Word.swift
├── Services/               # 业务服务
│   ├── ImageRecognitionService.swift
│   └── DataService.swift
└── Resources/              # 资源文件
```

## 开发环境

- Xcode 15.0+
- macOS 14.0+
- iOS 16.0+ (目标设备)

## 快速开始

1. 克隆项目
```bash
git clone <repository-url>
cd PickWords
```

2. 使用 Xcode 打开项目
```bash
open PickWords.xcodeproj
```

3. 选择目标设备，运行项目

## 权限说明

应用需要以下权限：

| 权限 | 用途 |
|------|------|
| 相机 | 拍摄物品照片进行识别 |
| 相册 | 保存拍摄的照片 |

## 使用说明

1. 打开应用，点击拍照按钮
2. 对准想要学习的物品拍照
3. AI 自动识别物品并显示英文单词
4. 确认保存到单词本
5. 随时在单词列表中查看已学习的单词

## 开发计划

详见 [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md)

## License

MIT License - 仅供个人学习使用

---

*Inspired by CapWords*
