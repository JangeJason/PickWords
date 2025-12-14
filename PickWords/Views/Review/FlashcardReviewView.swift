import SwiftUI
import SwiftData

struct FlashcardReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let wordCards: [WordCard]
    
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 可爱粉色背景
                AppTheme.background
                    .ignoresSafeArea()
                
                if wordCards.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 24) {
                        // 进度指示
                        progressView
                        
                        // 闪卡
                        flashcardView
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation.width
                                    }
                                    .onEnded { value in
                                        handleSwipe(value.translation.width)
                                    }
                            )
                        
                        // 操作提示
                        instructionView
                        
                        // 导航按钮
                        navigationButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("✨ 闪卡复习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.pink)
                    }
                }
            }
        }
        .tint(AppTheme.pink)
    }
    
    // MARK: - 空状态
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "rectangle.stack.badge.plus",
            title: "没有单词可复习",
            message: "拍摄物品添加单词后再来复习"
        )
    }
    
    // MARK: - 进度
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("✨")
                Text("\(currentIndex + 1) / \(wordCards.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("✨")
            }
            
            ProgressView(value: Double(currentIndex + 1), total: Double(wordCards.count))
                .tint(AppTheme.pink)
                .scaleEffect(y: 1.5)
        }
    }
    
    // MARK: - 闪卡
    private var flashcardView: some View {
        let card = wordCards[currentIndex]
        
        return ZStack {
            // 背面（单词信息）
            cardBack(for: card)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // 正面（图片）
            cardFront(for: card)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .offset(x: dragOffset)
        .rotation3DEffect(
            .degrees(Double(dragOffset) / 20),
            axis: (x: 0, y: 0, z: 1)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFlipped)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .onTapGesture {
            withAnimation {
                isFlipped.toggle()
            }
        }
    }
    
    // MARK: - 卡片正面（中文释义）
    private func cardFront(for card: WordCard) -> some View {
        VStack(spacing: 24) {
            // 图片
            if let uiImage = UIImage(data: card.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // 中文释义
            HStack {
                Text("💭")
                Text(card.translation)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            
            Spacer()
            
            HStack {
                Text("👆")
                Text("点击翻转查看英文")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXLarge))
        .shadow(color: AppTheme.pink.opacity(0.2), radius: 15, y: 8)
    }
    
    // MARK: - 卡片背面（英文单词信息）
    private func cardBack(for card: WordCard) -> some View {
        VStack(spacing: 16) {
            // 英文单词
            Text(card.word)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.pink)
            
            // 音标
            Text(card.phonetic)
                .font(.system(size: 18, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            
            Divider()
                .background(AppTheme.lavender)
                .padding(.horizontal, 40)
            
            // 例句
            VStack(spacing: 8) {
                Text(card.exampleSentence)
                    .font(.system(size: 15, design: .rounded))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text(card.exampleTranslation)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXLarge))
        .shadow(color: AppTheme.lavender.opacity(0.3), radius: 15, y: 8)
    }
    
    // MARK: - 操作提示
    private var instructionView: some View {
        HStack(spacing: 40) {
            VStack(spacing: 4) {
                Text("⬅️")
                    .font(.system(size: 24))
                Text("上一张")
                    .font(.system(size: 12, design: .rounded))
            }
            .foregroundStyle(AppTheme.textSecondary)
            
            VStack(spacing: 4) {
                Text("👆")
                    .font(.system(size: 24))
                Text("翻转")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(AppTheme.pink)
            
            VStack(spacing: 4) {
                Text("➡️")
                    .font(.system(size: 24))
                Text("下一张")
                    .font(.system(size: 12, design: .rounded))
            }
            .foregroundStyle(AppTheme.textSecondary)
        }
    }
    
    // MARK: - 导航按钮
    private var navigationButtons: some View {
        HStack(spacing: 24) {
            Button {
                goToPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 56, height: 56)
                    .background(AppTheme.lavender.opacity(0.3))
                    .foregroundStyle(AppTheme.lavender)
                    .clipShape(Circle())
            }
            .disabled(currentIndex == 0)
            .opacity(currentIndex == 0 ? 0.4 : 1)
            
            Button {
                goToNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 56, height: 56)
                    .background(AppTheme.pink)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.pink.opacity(0.4), radius: 8, y: 4)
            }
            .disabled(currentIndex == wordCards.count - 1)
            .opacity(currentIndex == wordCards.count - 1 ? 0.5 : 1)
        }
    }
    
    // MARK: - 手势处理
    private func handleSwipe(_ translation: CGFloat) {
        if translation < -100 {
            // 左滑 - 下一张
            goToNext()
        } else if translation > 100 {
            // 右滑 - 上一张
            goToPrevious()
        }
        dragOffset = 0
    }
    
    private func goToNext() {
        if currentIndex < wordCards.count - 1 {
            withAnimation {
                currentIndex += 1
                isFlipped = false
            }
        }
    }
    
    private func goToPrevious() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
                isFlipped = false
            }
        }
    }
}

// MARK: - 从单词列表进入复习的入口视图
struct FlashcardEntryView: View {
    @Query(sort: \WordCard.createdAt, order: .reverse) private var allCards: [WordCard]
    @State private var showReview = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 统计卡片
                statsCard
                
                // 开始复习按钮
                Button {
                    showReview = true
                } label: {
                    Label("开始复习", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(allCards.isEmpty)
                .opacity(allCards.isEmpty ? 0.5 : 1)
                
                Spacer()
            }
            .padding()
            .navigationTitle("闪卡复习")
            .fullScreenCover(isPresented: $showReview) {
                FlashcardReviewView(wordCards: allCards)
            }
        }
    }
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
            
            Text("\(allCards.count)")
                .font(.system(size: 48, weight: .bold))
            
            Text("张单词卡片")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    FlashcardEntryView()
        .modelContainer(for: WordCard.self, inMemory: true)
}
