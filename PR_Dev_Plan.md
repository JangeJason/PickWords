# PickWords 详细开发计划

按 PR (Pull Request) 划分的开发任务清单，每个 PR 保持小而独立，便于代码审查和回滚。

---

## 阶段一：项目初始化

### PR #1: 项目创建与基础配置

**分支**: `feat/project-setup`

**任务清单**:
- [ ] 创建 Xcode 项目 (SwiftUI + SwiftData)
- [ ] 配置项目 Bundle ID: `com.yourname.PickWords`
- [ ] 设置最低支持版本 iOS 17.0
- [ ] 配置 App Icon 占位图
- [ ] 创建基础目录结构

**目录结构**:
```
PickWords/
├── App/
│   └── PickWordsApp.swift
├── Views/
├── Models/
├── Services/
├── Components/
└── Resources/
```

**验收标准**: 项目能在模拟器上运行，显示空白页面

---

### PR #2: 数据模型定义

**分支**: `feat/data-models`

**任务清单**:
- [ ] 创建 `WordCard` 模型
- [ ] 创建 `Collection` 模型
- [ ] 配置 SwiftData ModelContainer

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

**验收标准**: 模型编译通过，App 启动时 SwiftData 容器初始化成功

---

### PR #3: 主导航框架

**分支**: `feat/main-navigation`

**任务清单**:
- [ ] 创建 `MainTabView` 底部 Tab 导航
- [ ] 创建三个占位页面
- [ ] 配置 Tab 图标和标题

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

**验收标准**: App 启动显示底部三个 Tab，可以切换

---

## 阶段二：相机与拍照

### PR #4: 相机权限配置

**分支**: `feat/camera-permission`

**任务清单**:
- [ ] 配置 Info.plist 相机权限描述
- [ ] 配置 Info.plist 相册权限描述
- [ ] 创建权限请求工具类

**Info.plist 配置**:
```xml
<key>NSCameraUsageDescription</key>
<string>PickWords 需要使用相机拍摄物品以识别英文单词</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>PickWords 需要访问相册以保存您的单词卡片</string>
```

**验收标准**: 首次打开相机时弹出权限请求弹窗

---

### PR #5: 相机拍照功能

**分支**: `feat/camera-capture`

**任务清单**:
- [ ] 创建 `CameraView` 使用 UIImagePickerController 或 AVFoundation
- [ ] 实现拍照按钮
- [ ] 拍照后获取 UIImage
- [ ] 创建拍照结果预览页面

**代码文件**:
- `Views/Camera/CameraView.swift` - 相机视图
- `Views/Camera/PhotoPreviewView.swift` - 拍照预览

**UI 设计**:
```
┌─────────────────────────┐
│                         │
│      相机预览区域        │
│                         │
│                         │
├─────────────────────────┤
│     [ 🔘 拍照按钮 ]      │
└─────────────────────────┘
```

**验收标准**: 能拍照并显示拍摄的照片预览

---

## 阶段三：AI 识别核心功能

### PR #6: OpenAI Service 基础设施

**分支**: `feat/openai-service`

**任务清单**:
- [ ] 创建 `OpenAIService` 单例类
- [ ] 实现 API Key 安全存储 (Keychain)
- [ ] 创建 API Key 设置页面
- [ ] 实现基础 HTTP 请求封装

**代码文件**:
- `Services/OpenAIService.swift`
- `Services/KeychainService.swift`
- `Views/Settings/APIKeySettingView.swift`

**API Key 存储流程**:
```
用户输入 API Key → 加密存储到 Keychain → 调用时从 Keychain 读取
```

**验收标准**: 能保存和读取 API Key，API Key 不明文存储

---

### PR #7: GPT-4 Vision 图像识别

**分支**: `feat/vision-recognition`

**任务清单**:
- [ ] 实现图片 Base64 编码
- [ ] 构造 GPT-4 Vision API 请求
- [ ] 定义 AI 返回数据结构
- [ ] 实现 JSON 响应解析

**API 请求 Prompt**:
```
分析这张图片中的主要物体，返回以下 JSON 格式：
{
  "word": "英文单词",
  "phonetic": "音标",
  "translation": "中文释义",
  "exampleSentence": "包含该单词的英文例句",
  "exampleTranslation": "例句的中文翻译"
}
只返回 JSON，不要其他内容。
```

**响应数据模型**:
```swift
struct AIRecognitionResult: Codable {
    let word: String
    let phonetic: String
    let translation: String
    let exampleSentence: String
    let exampleTranslation: String
}
```

**验收标准**: 传入图片能返回识别结果（单词、音标、释义、例句）

---

### PR #8: 识别结果展示页

**分支**: `feat/recognition-result-view`

**任务清单**:
- [ ] 创建识别结果展示页面
- [ ] 显示加载状态（识别中...）
- [ ] 显示识别结果卡片
- [ ] 添加"保存"和"重拍"按钮

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

**验收标准**: 拍照后显示 AI 识别结果，可保存或重拍

---

### PR #9: 单词贴纸生成

**分支**: `feat/word-sticker`

**任务清单**:
- [ ] 创建 `WordStickerView` 贴纸组件
- [ ] 实现贴纸样式（圆角背景 + 单词文字）
- [ ] 实现照片 + 贴纸合成
- [ ] 保存合成后的图片

**贴纸样式**:
```
┌──────────────┐
│  ☕ Coffee   │  ← 半透明背景 + 白色文字
└──────────────┘
```

**代码文件**:
- `Components/WordStickerView.swift`
- `Services/ImageService.swift` - 图片合成逻辑

**验收标准**: 照片上能叠加单词贴纸，并保存合成图

---

### PR #10: 保存单词卡片

**分支**: `feat/save-word-card`

**任务清单**:
- [ ] 实现 WordCard 保存到 SwiftData
- [ ] 保存原图和带贴纸图
- [ ] 保存成功后跳转到卡片列表
- [ ] 添加保存成功 Toast 提示

**验收标准**: 识别结果能保存到本地数据库，卡片列表能显示

---

## 阶段四：单词卡片管理

### PR #11: 卡片列表页面

**分支**: `feat/card-list`

**任务清单**:
- [ ] 创建 `CardListView`
- [ ] 使用 SwiftData @Query 获取所有卡片
- [ ] 实现卡片网格布局 (2列)
- [ ] 显示缩略图和单词

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

**验收标准**: 能显示所有已保存的单词卡片网格

---

### PR #12: 卡片详情页

**分支**: `feat/card-detail`

**任务清单**:
- [ ] 创建 `CardDetailView`
- [ ] 显示大图 + 完整单词信息
- [ ] 显示例句
- [ ] 添加删除按钮
- [ ] 添加编辑收藏集按钮

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

**验收标准**: 点击卡片能进入详情页，能删除卡片

---

### PR #13: 闪卡复习模式

**分支**: `feat/flashcard-review`

**任务清单**:
- [ ] 创建 `FlashcardView`
- [ ] 实现卡片翻转动画（正面图片，背面单词）
- [ ] 实现左右滑动切换卡片
- [ ] 显示进度 (3/12)

**交互设计**:
```
点击卡片 → 翻转显示答案
左滑 → 下一张
右滑 → 上一张
```

**验收标准**: 能以闪卡形式复习单词，支持翻转和滑动

---

## 阶段四·优化：AI 与体验打磨（新增）

> 说明：下面这些 PR 是在 **M3（卡片管理）已基本可用** 的基础上，对 AI 调用、贴纸效果和整体体验做的一轮增强。可以与后续收藏集功能穿插开发。

### PR #21: AI 服务命名与文档对齐

**分支**: `chore/ai-service-rename`

**任务清单**:
- [ ] 将 `GeminiService` 等命名统一为更通用且与供应商一致的名称（如 `AIService` 或 `QwenService`），同时更新单例、API Key 相关命名。
- [ ] 同步更新 `README.md` / `DEVELOPMENT_PLAN.md` / 本文件中的描述，使其与实际使用的多模态大模型（当前为通义千问 Qwen‑VL）一致。
- [ ] 更新 `Config/Secrets.swift.template` 中字段名和注释说明，避免“Gemini/OpenAI”等历史命名混用。

**验收标准**: 项目编译通过；AI 相关类型/字段命名与实际供应商一致，文档描述不再混乱。

---

### PR #22: AI 调用健壮性与错误体验优化

**分支**: `feat/ai-error-handling`

**任务清单**:
- [ ] 按 dashscope compatible 模式的实际响应结构，正确解析 `choices[0].message.content`（支持数组形式，从中提取 `type == "text"` 的内容）。
- [ ] 增强 `extractJSON(from:)`，支持去除 ```json/``` 包裹、宽松提取大括号之间的 JSON 文本，对模型输出“小跑题”有一定容错。
- [ ] 在 `PhotoPreviewView` 中根据不同 `AIError`（如 API Key 未配置、网络错误、解析错误）展示差异化提示和重试建议。
- [ ] 在 DEBUG 环境下打印原始内容，便于调试 prompt 和解析逻辑。

**验收标准**: 常见异常场景下，用户可以看到明确原因和下一步提示，不再只得到“解析失败”这类模糊错误。

---

### PR #23: 单词贴纸合成与展示完善

**分支**: `feat/word-sticker-enhanced`

**任务清单**:
- [ ] 新增 `Components/WordStickerView.swift`，负责渲染圆角背景 + 单词/emoji 的贴纸组件。
- [ ] 新增或完善 `Services/ImageService.swift`：接收原始 `UIImage` 与识别结果，结合 `VisionService` 检测主体/显著区域，计算贴纸位置并合成新图。
- [ ] 修改 `PhotoPreviewView.saveWordCard`：在保存时尝试生成贴纸版图片，成功则写入 `WordCard.stickerImageData`，失败时回退为仅保存原图。
- [ ] 修改 `WordCardCell` / `WordCardDetailView`：优先展示 `stickerImageData`，没有时使用原始 `imageData`。

**验收标准**: 新保存的卡片在列表和详情中都能看到“单词贴在物体上”的图片，Vision 失败不会影响主流程。

---

### PR #24: 收藏集列表与详情 UI 落地

**分支**: `feat/collections-ui`

**任务清单**:
- [ ] 创建 `CollectionListView`，使用 `@Query` 显示所有 `Collection`，展示名称、emoji 和卡片数量。
- [ ] 实现“新建收藏集”入口（简单弹窗输入名称与 emoji 文本即可）。
- [ ] 创建 `CollectionDetailView`，展示该收藏集下的所有 `WordCard`，复用现有卡片网格组件。
- [ ] 在 `MainTabView` 中用 `CollectionListView` 替换占位的 `CollectionListPlaceholderView`。

**验收标准**: “收藏” Tab 不再是占位视图，用户可以创建简单的收藏集并查看其中的卡片。

---

### PR #25: 卡片归类与筛选打通

**分支**: `feat/card-collection-link`

**任务清单**:
- [ ] 在识别结果保存流程中（`RecognitionResultView`），增加“选择收藏集”步骤，将所选 `Collection.id` 写入 `WordCard.collectionId`。
- [ ] 在 `WordCardDetailView` 中展示当前所属收藏集，并提供修改入口（收藏集选择器）。
- [ ] 在 `WordCardListView` 中增加按收藏集筛选能力（例如顶部 SegmentedControl 或工具栏菜单）。

**验收标准**: 新建卡片可以直接归类到收藏集；已有卡片可以修改归属；列表和收藏集详情视图中的数据保持一致。

---

### PR #26: 基础闪卡复习模式实现

**分支**: `feat/flashcard-review-basic`

**任务清单**:
- [ ] 实现 `FlashcardView`，支持左右滑动浏览卡片和点击翻面（图像正面 / 单词+释义反面）。
- [ ] 在“单词” Tab（`WordCardListView`）中添加进入闪卡模式的入口，默认使用当前筛选条件下的卡片集合。
- [ ] 在闪卡视图中显示简单进度指示（如 `3/12`），支持从头到尾浏览一轮。

**验收标准**: 用户可以从列表进入闪卡视图，以“图片+翻面”的形式复习当前词库中的卡片。

---

### PR #27: 视图复用与细节体验优化

**分支**: `chore/ui-refactor-polish`

**任务清单**:
- [ ] 抽取复用组件（如 `WordCardContentView`），统一 `RecognitionResultView` 与 `WordCardDetailView` 内部“单词 + 音标 + 释义 + 例句”的展示逻辑。
- [ ] 为删除卡片等危险操作增加确认弹窗，避免误删。
- [ ] 在 `CameraView` 中增加一个“最近卡片缩略图”或快捷入口，快速跳转到最新保存的单词卡片（可选）。
- [ ] 清理不再使用的占位视图和重复代码，保持视图层整洁。

**验收标准**: 相关视图代码更易维护，重复 UI 减少，交互细节更可靠友好。

---

## 阶段五：场景收藏集

### PR #14: 收藏集列表页

**分支**: `feat/collection-list`

**任务清单**:
- [ ] 创建 `CollectionListView`
- [ ] 显示所有收藏集
- [ ] 显示每个收藏集的卡片数量
- [ ] 添加"新建收藏集"按钮

**UI 设计**:
```
┌─────────────────────────┐
│  我的收藏集              │
├─────────────────────────┤
│  🍳 我的厨房    (8张)    │
├─────────────────────────┤
│  🛒 超市购物    (15张)   │
├─────────────────────────┤
│  ✈️ 旅行途中    (6张)    │
├─────────────────────────┤
│      [+ 新建收藏集]      │
└─────────────────────────┘
```

**验收标准**: 能显示收藏集列表，能看到每个收藏集的卡片数

---

### PR #15: 创建/编辑收藏集

**分支**: `feat/collection-crud`

**任务清单**:
- [ ] 创建新建收藏集弹窗
- [ ] 实现 emoji 选择器
- [ ] 实现收藏集名称输入
- [ ] 实现编辑和删除收藏集

**验收标准**: 能创建、编辑、删除收藏集

---

### PR #16: 收藏集详情页

**分支**: `feat/collection-detail`

**任务清单**:
- [ ] 创建 `CollectionDetailView`
- [ ] 显示该收藏集下的所有卡片
- [ ] 复用卡片网格组件

**验收标准**: 点击收藏集能查看该场景下的所有单词卡片

---

### PR #17: 卡片归类功能

**分支**: `feat/card-categorize`

**任务清单**:
- [ ] 保存单词时可选择收藏集
- [ ] 卡片详情页可修改所属收藏集
- [ ] 实现收藏集选择器组件

**验收标准**: 保存卡片时能选择收藏集，已有卡片能修改归类

---

## 阶段六：完善与优化

### PR #18: UI 美化

**分支**: `feat/ui-polish`

**任务清单**:
- [ ] 统一配色方案
- [ ] 添加页面转场动画
- [ ] 优化卡片样式
- [ ] 添加空状态提示（无卡片时）

**验收标准**: UI 整体美观协调

---

### PR #19: 错误处理与加载状态

**分支**: `feat/error-handling`

**任务清单**:
- [ ] 添加网络请求错误提示
- [ ] 添加 API Key 无效提示
- [ ] 添加识别失败重试按钮
- [ ] 优化加载动画

**验收标准**: 各种异常情况有友好提示

---

### PR #20: 设置页面

**分支**: `feat/settings`

**任务清单**:
- [ ] 创建设置入口（Tab 或导航栏）
- [ ] API Key 管理
- [ ] 关于页面
- [ ] 清除数据选项

**验收标准**: 能在设置中管理 API Key

---

## PR 依赖关系图

```
PR#1 → PR#2 → PR#3
         ↓
       PR#4 → PR#5
                ↓
       PR#6 → PR#7 → PR#8 → PR#9 → PR#10
                                      ↓
                              PR#11 → PR#12 → PR#13
                                      ↓
                              PR#14 → PR#15 → PR#16 → PR#17
                                                        ↓
                                               PR#18 → PR#19 → PR#20
```

---

## 里程碑

| 里程碑 | 包含 PR | 预计完成 | 可交付成果 |
|--------|---------|----------|------------|
| M1: 可拍照 | #1-#5 | Day 2 | 能拍照预览 |
| M2: AI 识别 | #6-#10 | Day 5 | 能识别并保存单词 |
| M3: 卡片管理 | #11-#13 | Day 7 | 能浏览和复习卡片 |
| M4: 收藏集 | #14-#17 | Day 9 | 能按场景分类 |
| M5: 完善 | #18-#20 | Day 10 | 可用版本 |

---

*最后更新: 2024年12月*
