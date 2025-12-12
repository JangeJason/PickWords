import SwiftUI
import SwiftData

struct WordCardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordCard.createdAt, order: .reverse) private var wordCards: [WordCard]
    
    @State private var selectedCard: WordCard?
    @State private var showFlashcardReview = false
    
    var body: some View {
        NavigationStack {
            Group {
                if wordCards.isEmpty {
                    emptyStateView
                } else {
                    cardListView
                }
            }
            .navigationTitle("我的单词")
            .toolbar {
                if !wordCards.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showFlashcardReview = true
                        } label: {
                            Image(systemName: "rectangle.stack")
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedCard) { card in
            WordCardDetailView(wordCard: card)
        }
        .fullScreenCover(isPresented: $showFlashcardReview) {
            FlashcardReviewView(wordCards: wordCards)
        }
    }
    
    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("还没有单词卡片")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("拍摄物品开始学习英语单词")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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

// MARK: - 单词卡片 Cell
struct WordCardCell: View {
    let wordCard: WordCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图片
            if let uiImage = UIImage(data: wordCard.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 120)
            }
            
            // 文字信息
            VStack(alignment: .leading, spacing: 4) {
                Text(wordCard.word)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(wordCard.translation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
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
