# PickWords 开发计划书

## 项目概述

**项目名称**: PickWords  
**平台**: iOS (iPhone)  
**目标用户**: 个人使用  
**参考应用**: CapWords  
**核心理念**: 最小可用产品 (MVP)，只实现必要功能

## 核心功能

### 1. 拍照识物学单词 (Snap & Learn) ⭐ 杀手级功能

| 特性 | 描述 |
|------|------|
| **操作方式** | 打开 App 启动相机，对准任何实物拍照 |
| **AI 识别** | 通过 AI 图像识别技术，分析照片中的物体 |
| **即时翻译** | 将识别物体翻译为英语（后期可扩展其他语言） |
| **单词贴纸** | 直接在照片上生成"单词贴纸"，单词与实物建立视觉关联 |

**视觉化记忆**: 不是冷冰冰的单词列表，而是让单词"长"在实物上，利用视觉记忆强化学习效果。

### 2. 生成实景单词卡片 (Visual Flashcards)

| 特性 | 描述 |
|------|------|
| **自动生成卡片** | 将拍摄的照片制作成精美的双语单词卡片 |
| **卡片内容** | 单词 + 音标 + 中文释义 |
| **AI 例句** | AI 根据画面内容生成地道的例句 |

**语境学习**: 例如拍一杯咖啡，生成"喝咖啡提神"相关例句，在语境中学习单词用法。

### 3. 场景化分类与收藏 (Scene Collections)

| 特性 | 描述 |
|------|------|
| **场景收藏集** | 按生活足迹分类，而非字母 A-Z |
| **自定义分类** | 创建如"我的厨房"、"超市购物"、"旅行途中"等收藏集 |
| **认知友好** | 符合人类认知习惯，适合学习生活常用词汇 |

## 功能优先级

| 优先级 | 功能 | MVP 阶段 |
|--------|------|----------|
| P0 | 拍照 + AI 识别物体 | ✅ |
| P0 | 照片上生成单词贴纸 | ✅ |
| P0 | 单词卡片（单词 + 音标 + 释义） | ✅ |
| P0 | 场景收藏集管理 | ✅ |
| P1 | AI 生成例句 | ✅ |
| P1 | 卡片浏览/复习 | ✅ |
| P2 | 从相册选择照片 | 后期 |
| P2 | 多语言支持 | 后期 |

## 技术方案

### 开发框架

- **语言**: Swift
- **UI 框架**: SwiftUI
- **最低支持版本**: iOS 16.0

### AI 能力方案

由于需要 **物体识别 + 翻译 + 例句生成** 三项 AI 能力，推荐使用多模态大模型：

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| ✅ **OpenAI GPT-4 Vision** | 识别精准、可生成例句、一站式解决 | 需 API 费用 | ⭐⭐⭐⭐⭐ |
| ✅ **Claude Vision** | 同上，识别效果好 | 需 API 费用 | ⭐⭐⭐⭐⭐ |
| Apple Vision + 翻译 API | 免费离线 | 无法生成例句、识别精度有限 | ⭐⭐ |

**推荐方案**: 使用 **OpenAI GPT-4 Vision API**

- 一次 API 调用可完成：物体识别 → 英文单词 → 中文释义 → 音标 → 例句
- 个人使用成本极低（约 $0.01-0.03/次）
- 后期可轻松切换其他大模型

### 数据模型

```swift
// 单词卡片
struct WordCard {
    id: UUID
    imageData: Data           // 原始照片
    stickerImageData: Data?   // 带贴纸的照片
    word: String              // 英文单词
    phonetic: String          // 音标
    translation: String       // 中文释义
    exampleSentence: String   // AI 生成例句
    exampleTranslation: String // 例句中文翻译
    collectionId: UUID?       // 所属收藏集
    createdAt: Date
}

// 场景收藏集
struct Collection {
    id: UUID
    name: String              // 如 "我的厨房"
    icon: String              // emoji 图标
    createdAt: Date
}
```

### 数据存储

- **方案**: SwiftData (iOS 17+)
- **图片存储**: 本地文件系统 + 路径引用

### 项目结构

```
PickWords/
├── App/
│   └── PickWordsApp.swift
├── Views/
│   ├── MainTabView.swift           # 主 Tab 导航
│   ├── Camera/
│   │   ├── CameraView.swift        # 相机拍照
│   │   └── StickerOverlayView.swift # 单词贴纸叠加层
│   ├── Cards/
│   │   ├── CardListView.swift      # 卡片列表
│   │   ├── CardDetailView.swift    # 卡片详情
│   │   └── FlashcardView.swift     # 闪卡复习
│   └── Collections/
│       ├── CollectionListView.swift # 收藏集列表
│       └── CollectionDetailView.swift
├── Models/
│   ├── WordCard.swift              # 单词卡片模型
│   └── Collection.swift            # 收藏集模型
├── Services/
│   ├── OpenAIService.swift         # GPT-4 Vision API
│   ├── ImageService.swift          # 图片处理/贴纸生成
│   └── DataService.swift           # 数据持久化
├── Components/
│   ├── WordStickerView.swift       # 单词贴纸组件
│   └── WordCardView.swift          # 单词卡片组件
├── Resources/
│   └── Assets.xcassets
└── Info.plist
```

## 开发计划

### 第一阶段：项目搭建（1天）

- [ ] 创建 Xcode 项目，配置 SwiftUI + SwiftData
- [ ] 搭建主 Tab 导航框架
- [ ] 配置相机、相册权限
- [ ] 创建数据模型（WordCard, Collection）

### 第二阶段：拍照识别核心功能（2-3天）

- [ ] 实现相机拍照功能
- [ ] 集成 OpenAI GPT-4 Vision API
- [ ] 实现 AI 返回结果解析（单词/音标/释义/例句）
- [ ] 实现单词贴纸渲染（在照片上叠加单词标签）
- [ ] 保存带贴纸的照片

### 第三阶段：单词卡片功能（2天）

- [ ] 设计单词卡片 UI
- [ ] 实现卡片列表页面
- [ ] 实现卡片详情页（单词、音标、例句展示）
- [ ] 实现简单的闪卡复习模式

### 第四阶段：场景收藏集（1-2天）

- [ ] 实现收藏集创建/编辑/删除
- [ ] 实现卡片归类到收藏集
- [ ] 收藏集详情页（展示该场景下所有卡片）

### 第五阶段：完善与测试（1-2天）

- [ ] UI 美化与动画
- [ ] 功能测试 & Bug 修复
- [ ] 真机测试
- [ ] API Key 安全存储

### 总预计开发时间：7-10 天

## 所需权限

```xml
<!-- Info.plist -->
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄物品以识别英文单词</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以保存和选择照片</string>
```

## 风险与备选方案

| 风险 | 影响 | 备选方案 |
|------|------|----------|
| OpenAI API 费用超预期 | 成本问题 | 切换 Claude API 或本地模型 |
| API 响应速度慢 | 用户体验差 | 添加加载动画、优化提示词 |
| 单词贴纸位置不准确 | 视觉效果差 | 允许用户手动调整贴纸位置 |
| API Key 泄露 | 安全风险 | 使用 Keychain 安全存储 |

## API 费用预估（个人使用）

| 使用频率 | 月调用次数 | 月费用（GPT-4o） |
|----------|------------|------------------|
| 轻度（每天 3 次） | ~90 次 | ~$0.5-1 |
| 中度（每天 10 次） | ~300 次 | ~$2-3 |
| 重度（每天 30 次） | ~900 次 | ~$5-10 |

## 后续迭代方向

1. **相册选图** - 从相册选择已有照片识别
2. **单词发音** - 集成 TTS 朗读单词和例句
3. **多语言支持** - 日语、韩语、法语等
4. **数据导出** - 导出单词本为 CSV/Anki 格式
5. **iCloud 同步** - 多设备数据同步
6. **学习统计** - 记录学习进度和复习曲线
7. **Widget 小组件** - 桌面每日单词提醒

---

*文档创建日期: 2024年12月*
