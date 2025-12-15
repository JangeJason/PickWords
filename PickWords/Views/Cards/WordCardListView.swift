import SwiftUI
import SwiftData

struct WordCardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordCard.createdAt, order: .reverse) private var wordCards: [WordCard]
    
    @State private var selectedCard: WordCard?
    @State private var showFlashcardReview = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 可爱粉色背景
                AppTheme.background
                    .ignoresSafeArea()
                
                if wordCards.isEmpty {
                    emptyStateView
                } else {
                    cardListView
                }
            }
            .navigationTitle("🌸 我的单词本")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !wordCards.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showFlashcardReview = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("复习")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryGradient)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .tint(AppTheme.pink)
        .sheet(item: $selectedCard) { card in
            WordCardDetailView(wordCard: card)
        }
        .fullScreenCover(isPresented: $showFlashcardReview) {
            FlashcardReviewView(wordCards: wordCards)
        }
    }
    
    // MARK: - 空状态
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "rectangle.stack.badge.plus",
            title: "还没有单词卡片",
            message: "拍摄物品开始学习英语单词"
        )
    }
    
    // MARK: - 卡片列表
    private var cardListView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(wordCards) { card in
                    WordCardCell(wordCard: card)
                        .onTapGesture {
                            selectedCard = card
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteCard(card)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private func deleteCard(_ card: WordCard) {
        modelContext.delete(card)
    }
}

// MARK: - 可爱单词卡片 Cell
struct WordCardCell: View {
    let wordCard: WordCard
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 图片区域
            ZStack(alignment: .topTrailing) {
                if let uiImage = UIImage(data: wordCard.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 130)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppTheme.lavender.opacity(0.3))
                        .frame(height: 130)
                        .overlay(
                            Text("🖼️")
                                .font(.system(size: 40))
                        )
                }
                
                // 可爱装饰角标
                Text("✨")
                    .font(.system(size: 16))
                    .padding(6)
                    .background(Circle().fill(.white.opacity(0.9)))
                    .offset(x: -8, y: 8)
            }
            .clipShape(
                RoundedCorner(radius: AppTheme.cornerRadiusLarge, corners: [.topLeft, .topRight])
            )
            
            // 文字信息区域
            VStack(alignment: .leading, spacing: 6) {
                Text(wordCard.word)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("💭")
                        .font(.system(size: 12))
                    Text(wordCard.translation)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
        .shadow(color: AppTheme.pink.opacity(0.15), radius: 8, y: 4)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// 圆角辅助
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 可爱单词卡片详情
struct WordCardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let wordCard: WordCard
    
    @State private var showStickerPreview = false
    @State private var showCollectionPicker = false
    @Query(sort: \Collection.createdAt, order: .reverse) private var collections: [Collection]
    
    private var currentCollection: Collection? {
        collections.first { $0.id == wordCard.collectionId }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 图片卡片
                        VStack {
                            if let uiImage = UIImage(data: wordCard.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 220)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXLarge))
                        .shadow(color: AppTheme.pink.opacity(0.15), radius: 12, y: 6)
                        
                        // 单词卡片内容
                        VStack(spacing: 20) {
                            // 单词和音标
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Text(wordCard.word)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.pink)
                                    
                                    // 发音按钮
                                    Button {
                                        SpeechService.shared.speak(wordCard.word)
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(AppTheme.pink)
                                            .padding(8)
                                            .background(AppTheme.pink.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                                
                                Text(wordCard.phonetic)
                                    .font(.system(size: 17, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            
                            Divider()
                                .background(AppTheme.lavender.opacity(0.5))
                            
                            // 中文释义
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("💭")
                                    Text("释义")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Text(wordCard.translation)
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Divider()
                                .background(AppTheme.lavender.opacity(0.5))
                            
                            // 例句
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("📝")
                                    Text("例句")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Text(wordCard.exampleSentence)
                                    .font(.system(size: 16, design: .rounded))
                                    .italic()
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(wordCard.exampleTranslation)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Divider()
                                .background(AppTheme.lavender.opacity(0.5))
                            
                                // 收藏夹
                            HStack {
                                Text("📁")
                                Text("收藏夹")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Button {
                                    showCollectionPicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        if let collection = currentCollection {
                                            Text(collection.icon)
                                            Text(collection.name)
                                                .font(.system(size: 13, design: .rounded))
                                        } else {
                                            Text("未分类")
                                                .font(.system(size: 13, design: .rounded))
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                    }
                                    .foregroundStyle(AppTheme.pink)
                                }
                            }
                            
                            Divider()
                                .background(AppTheme.lavender.opacity(0.5))
                            
                            // 创建时间
                            HStack {
                                Text("📅")
                                Text("添加时间")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text(wordCard.createdAt, style: .date)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .padding(20)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                    
                        // 生成贴纸按钮
                        Button {
                            showStickerPreview = true
                        } label: {
                            HStack {
                                Text("🎨")
                                Text("生成单词贴纸")
                            }
                        }
                        .buttonStyle(CuteButtonStyle())
                    }
                    .padding()
                }
            }
            .navigationTitle("✨ 单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.pink)
                    }
                }
            }
            .sheet(isPresented: $showStickerPreview) {
                if let uiImage = UIImage(data: wordCard.imageData) {
                    StickerPreviewView(
                        originalImage: uiImage,
                        word: wordCard.word,
                        phonetic: wordCard.phonetic,
                        translation: wordCard.translation
                    )
                }
            }
            .sheet(isPresented: $showCollectionPicker) {
                CollectionPickerSheet(wordCard: wordCard)
            }
        }
        .tint(AppTheme.pink)
    }
}

// MARK: - 收藏夹选择器
struct CollectionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let wordCard: WordCard
    
    @Query(sort: \Collection.createdAt, order: .reverse) private var collections: [Collection]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                if collections.isEmpty {
                    VStack(spacing: 16) {
                        Text("📁")
                            .font(.system(size: 50))
                        Text("暂无收藏夹")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("请先在收藏夹页面创建")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                    }
                } else {
                    List {
                        // 不归类选项
                        Button {
                            wordCard.collectionId = nil
                            dismiss()
                        } label: {
                            HStack {
                                Text("📋")
                                    .font(.system(size: 24))
                                Text("不归类")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                if wordCard.collectionId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppTheme.pink)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // 收藏夹列表
                        ForEach(collections) { collection in
                            Button {
                                wordCard.collectionId = collection.id
                                dismiss()
                            } label: {
                                HStack {
                                    Text(collection.icon)
                                        .font(.system(size: 24))
                                    Text(collection.name)
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    if wordCard.collectionId == collection.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AppTheme.pink)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("📁 选择收藏夹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.pink)
                }
            }
        }
        .tint(AppTheme.pink)
    }
}

#Preview {
    WordCardListView()
        .modelContainer(for: WordCard.self, inMemory: true)
}
