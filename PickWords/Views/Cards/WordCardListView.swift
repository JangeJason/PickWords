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

// MARK: - 单词卡片详情
struct WordCardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let wordCard: WordCard
    
    @State private var showStickerPreview = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 图片
                    if let uiImage = UIImage(data: wordCard.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 单词卡片内容
                    VStack(spacing: 16) {
                        // 单词和音标
                        VStack(spacing: 8) {
                            Text(wordCard.word)
                                .font(.system(size: 36, weight: .bold))
                            
                            Text(wordCard.phonetic)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        // 中文释义
                        HStack {
                            Text("释义")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Text(wordCard.translation)
                            .font(.title2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                        
                        // 例句
                        HStack {
                            Text("例句")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Text(wordCard.exampleSentence)
                            .font(.body)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(wordCard.exampleTranslation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                        
                        // 创建时间
                        HStack {
                            Text("添加时间")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(wordCard.createdAt, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // 生成贴纸按钮
                    Button {
                        showStickerPreview = true
                    } label: {
                        Label("生成单词贴纸", systemImage: "photo.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
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
        }
    }
}

#Preview {
    WordCardListView()
        .modelContainer(for: WordCard.self, inMemory: true)
}
