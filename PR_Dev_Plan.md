# PickWords 详细开发计划

按 PR (Pull Request) 划分的开发任务清单，每个 PR 保持小而独立，便于代码审查和回滚。

## 技术栈

| 功能 | 技术方案 |
|------|----------|
| 框架 | SwiftUI + SwiftData |
| AI 识别 | 通义千问 VL (qwen-vl-plus) |
| 主体抠图 | Apple Vision Framework (iOS 17+) |
| API Key 存储 | Keychain |
| 最低版本 | iOS 17.0 |

---

## 阶段一：项目初始化 ✅

### PR #1: 项目创建与基础配置 ✅

**分支**: `feat/project-setup`

**任务清单**:
- [x] 创建 Xcode 项目 (SwiftUI + SwiftData)
- [x] 配置项目 Bundle ID: `com.jangejason.PickWords`
- [x] 设置最低支持版本 iOS 17.0
- [x] 配置 App Icon 占位图
- [x] 创建基础目录结构

**目录结构**:
```
PickWords/
├── App/
│   └── PickWordsApp.swift
├── Views/
├── Models/
├── Services/
├── Config/
├── Components/
└── Resources/
```

**验收标准**: ✅ 项目能在模拟器上运行

---

### PR #2: 数据模型定义 ✅

**分支**: `feat/data-models`

**任务清单**:
- [x] 创建 `WordCard` 模型
- [x] 创建 `Collection` 模型
- [x] 配置 SwiftData ModelContainer

**代码文件**:

`Models/WordCard.swift`:
```swift
import SwiftData
import Foundation

@Model
final class WordCard {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    @Attribute(.externalStorage) var stickerImageData: Data?
    var word: String              // 英文单词
    var phonetic: String          // 音标 如 /ˈkɒfi/
    var translation: String       // 中文释义
    var exampleSentence: String   // 英文例句
    var exampleTranslation: String // 例句中文翻译
    var collectionId: UUID?       // 所属收藏集
    var createdAt: Date
    
    init(imageData: Data, word: String, phonetic: String, 
         translation: String, exampleSentence: String, 
         exampleTranslation: String, collectionId: UUID? = nil) {
        self.id = UUID()
        self.imageData = imageData
        self.word = word
        self.phonetic = phonetic
        self.translation = translation
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.collectionId = collectionId
        self.createdAt = Date()
    }
}
```

`Models/Collection.swift`:
```swift
import SwiftData
import Foundation

@Model
final class Collection {
    var id: UUID
    var name: String          // 如 "我的厨房"
    var icon: String          // emoji 图标
    var createdAt: Date
    
    init(name: String, icon: String = "📁") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.createdAt = Date()
    }
}
```

**验收标准**: ✅ 模型编译通过，SwiftData 容器初始化成功

---

### PR #3: 主导航框架 ✅

**分支**: `feat/main-navigation`

**任务清单**:
- [x] 创建 `MainTabView` 底部 Tab 导航
- [x] 创建三个 Tab 页面
- [x] 配置 Tab 图标和标题

**Tab 结构**:
| Tab | 图标 | 标题 | 对应页面 |
|-----|------|------|----------|
| 1 | camera.fill | 拍照 | CameraView |
| 2 | rectangle.stack.fill | 卡片 | CardListView |
| 3 | folder.fill | 收藏 | CollectionListView |

**代码文件**:

`Views/MainTabView.swift`:
```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CameraPlaceholderView()
                .tabItem {
                    Label("拍照", systemImage: "camera.fill")
                }
            
            CardListPlaceholderView()
                .tabItem {
                    Label("卡片", systemImage: "rectangle.stack.fill")
                }
            
            CollectionListPlaceholderView()
                .tabItem {
                    Label("收藏", systemImage: "folder.fill")
                }
        }
    }
}
```

**验收标准**: ✅ App 启动显示底部三个 Tab，可以切换

---

## 阶段二：相机与拍照 ✅

### PR #4: 相机权限配置 ✅

**分支**: `feat/camera-permission`

**任务清单**:
- [x] 配置相机权限描述
- [x] 配置相册权限描述

**验收标准**: ✅ 首次打开相机时弹出权限请求弹窗

---

### PR #5: 相机拍照功能 ✅

**分支**: `feat/camera-capture`

**任务清单**:
- [x] 创建 `CameraView` 使用系统相机
- [x] 实现拍照和从相册选择
- [x] 创建拍照结果预览页面 `PhotoPreviewView`

**代码文件**:
- `Views/Camera/CameraView.swift`
- `Views/Camera/PhotoPreviewView.swift`

**验收标准**: ✅ 能拍照并显示拍摄的照片预览

---

## 阶段三：AI 识别核心功能 ✅

### PR #6: AI Service 基础设施 ✅

**分支**: `feat/gemini-service`

**任务清单**:
- [x] 创建 `AIService` 单例类（通义千问 VL）
- [x] 实现 API Key 安全存储 (Keychain)
- [x] 创建 API Key 设置页面
- [x] 支持内置 API Key（Config/Secrets.swift）

**代码文件**:
- `Services/AIService.swift` - 通义千问 VL API 调用
- `Services/KeychainService.swift` - API Key 安全存储
- `Services/VisionService.swift` - Apple Vision 主体抠图
- `Views/Settings/APIKeySettingView.swift`
- `Config/Secrets.swift` - 内置 API Key（gitignore）

**验收标准**: ✅ 能保存和读取 API Key

---

### PR #7: 图像识别 + 主体抠图 ✅

**分支**: `feat/gemini-service`

**任务清单**:
- [x] Apple Vision 主体抠图（extractSubject）
- [x] 图片方向修正（normalizeImageOrientation）
- [x] 通义千问 VL API 图像识别
- [x] JSON 响应解析

**识别流程**:
```
拍照 → Apple Vision 抠图 → 通义千问识别 → 返回结果
```

**响应数据模型**:
```swift
struct RecognitionResult: Codable {
    let word: String
    let phonetic: String
    let translation: String
    let exampleSentence: String
    let exampleTranslation: String
}
```

**验收标准**: ✅ 拍照后能抠图并识别出单词

---

### PR #8: 识别结果展示 + 保存 ✅

**分支**: `feat/gemini-service`

**任务清单**:
- [x] 创建识别结果展示页面 `RecognitionResultView`
- [x] 显示抠图后的主体（棋盘格透明背景）
- [x] 显示单词、音标、释义、例句
- [x] 保存单词卡片到 SwiftData
- [x] 创建单词列表页面 `WordCardListView`

**UI 设计**:
```
┌─────────────────────────┐
│      [拍摄的照片]        │
├─────────────────────────┤
│  Coffee    /ˈkɒfi/      │
│  ☕ 咖啡                 │
├─────────────────────────┤
│  例句:                   │
│  I need a cup of coffee │
│  to wake me up.         │
│  我需要一杯咖啡来提神。   │
├─────────────────────────┤
│  [重拍]      [保存]      │
└─────────────────────────┘
```

**验收标准**: ✅ 拍照后显示 AI 识别结果，可保存或重拍

---

## 阶段四：单词卡片管理 ✅

### PR #9: 卡片列表页面 ✅

**分支**: `feat/gemini-service`

**任务清单**:
- [x] 创建 `WordCardListView`
- [x] 使用 SwiftData @Query 获取所有卡片
- [x] 实现卡片网格布局 (2列)
- [x] 显示缩略图和单词
- [x] 长按删除卡片

**UI 设计**:
```
┌─────────────────────────┐
│  我的单词卡 (12)         │
├───────────┬─────────────┤
│ [图片]    │ [图片]      │
│ Coffee    │ Chair       │
├───────────┼─────────────┤
│ [图片]    │ [图片]      │
│ Book      │ Cup         │
└───────────┴─────────────┘
```

**验收标准**: ✅ 能显示所有已保存的单词卡片网格

---

### PR #10: 卡片详情页 ✅

**分支**: `feat/gemini-service`

**任务清单**:
- [x] 创建 `WordCardDetailView`
- [x] 显示大图 + 完整单词信息
- [x] 显示例句
- [x] 显示创建时间

**UI 设计**:
```
┌─────────────────────────┐
│        [大图]           │
├─────────────────────────┤
│  Coffee     /ˈkɒfi/     │
│  咖啡                   │
├─────────────────────────┤
│  📝 例句                │
│  I need a cup of coffee │
│  to wake me up.         │
│  我需要一杯咖啡来提神。   │
├─────────────────────────┤
│  📁 收藏集: 我的厨房     │
├─────────────────────────┤
│  [🗑️ 删除]              │
└─────────────────────────┘
```

**验收标准**: ✅ 点击卡片能进入详情页

---

## 阶段五：待开发功能

### PR #11: 闪卡复习模式

**分支**: `feat/flashcard-review`

**任务清单**:
- [ ] 创建 `FlashcardView`
- [ ] 实现卡片翻转动画
- [ ] 实现左右滑动切换
- [ ] 显示进度

**验收标准**: 能以闪卡形式复习单词

---

### PR #12: 场景收藏集

**分支**: `feat/collection`

**任务清单**:
- [ ] 创建 `CollectionListView`
- [ ] 创建/编辑/删除收藏集
- [ ] 保存单词时选择收藏集
- [ ] 收藏集详情页

**验收标准**: 能按场景分类单词

---

### PR #13: 单词贴纸生成

**分支**: `feat/word-sticker`

**任务清单**:
- [ ] 创建贴纸组件
- [ ] 照片 + 贴纸合成
- [ ] 保存合成图片

**验收标准**: 照片上能叠加单词贴纸

---

### PR #14: UI 优化

**分支**: `feat/ui-polish`

**任务清单**:
- [ ] 统一配色方案
- [ ] 页面转场动画
- [ ] 空状态提示优化

**验收标准**: UI 整体美观

---

## 当前进度

```
✅ 已完成                         ⏳ 待开发
─────────────────────────────────────────────
PR#1-#3: 项目初始化               PR#11: 闪卡复习
PR#4-#5: 相机拍照                 PR#12: 场景收藏
PR#6-#8: AI识别+抠图+保存         PR#13: 单词贴纸
PR#9-#10: 卡片列表+详情           PR#14: UI优化
```

---

## 里程碑

| 里程碑 | 状态 | 成果 |
|--------|------|------|
| M1: 可拍照 | ✅ | 能拍照预览 |
| M2: AI 识别 | ✅ | 能识别并保存单词 |
| M3: 卡片管理 | ✅ | 能浏览卡片详情 |
| M4: 收藏集 | ⏳ | 能按场景分类 |
| M5: 完善 | ⏳ | 可用版本 |

---

*最后更新: 2025年12月*
