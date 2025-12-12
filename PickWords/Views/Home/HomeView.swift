import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordCard.createdAt, order: .reverse) private var allWordCards: [WordCard]
    
    @State private var showCamera = false
    @State private var selectedCard: WordCard?
    
    // 今日的单词
    private var todayWordCards: [WordCard] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allWordCards.filter { card in
            calendar.isDate(card.createdAt, inSameDayAs: today)
        }
    }
    
    var body: some View {
        ZStack {
            // 背景 - 浅灰色点阵
            DotPatternBackground()
            
            VStack(spacing: 0) {
                // 顶部区域
                headerView
                
                // 内容区域 - 今日单词
                contentView
                
                Spacer()
                
                // 底部相机按钮
                cameraButton
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
        .sheet(item: $selectedCard) { card in
            WordCardDetailView(wordCard: card)
        }
    }
    
    // MARK: - 顶部区域
    private var headerView: some View {
        HStack {
            Spacer()
            
            // 中间 - 日期和今日单词数
            VStack(spacing: 6) {
                Text(formattedDate)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text("今日收录 \(todayWordCards.count) 个单词")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // 右侧 - 用户头像
            userAvatar
                .padding(.trailing, 20)
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: Date())
    }
    
    // 用户头像
    private var userAvatar: some View {
        Circle()
            .fill(AppTheme.lavender.opacity(0.3))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.lavender)
            )
    }
    
    // MARK: - 内容区域
    private var contentView: some View {
        ScrollView {
            if todayWordCards.isEmpty {
                emptyStateView
            } else {
                wordCardsGrid
            }
        }
    }
    
    // 空状态
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 100)
            
            Text("📷")
                .font(.system(size: 60))
            
            Text("今天还没有收录单词")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            
            Text("点击下方相机按钮开始")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
        }
    }
    
    // 单词网格
    private var wordCardsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ],
            spacing: 30
        ) {
            ForEach(todayWordCards) { card in
                StickerWordCard(wordCard: card)
                    .onTapGesture {
                        selectedCard = card
                    }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - 底部相机按钮
    private var cameraButton: some View {
        Button {
            showCamera = true
        } label: {
            ZStack {
                // 外圈
                Circle()
                    .fill(AppTheme.pink)
                    .frame(width: 70, height: 70)
                    .shadow(color: AppTheme.pink.opacity(0.4), radius: 12, y: 6)
                
                // 相机图标
                Image(systemName: "camera.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - 贴纸样式单词卡片
struct StickerWordCard: View {
    let wordCard: WordCard
    
    var body: some View {
        VStack(spacing: 8) {
            // 物品轮廓图 - 贴纸效果
            if let uiImage = UIImage(data: wordCard.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 140)
                    // 白色描边效果
                    .background(
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .colorMultiply(.white)
                            .blur(radius: 2)
                            .offset(x: 0, y: 0)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            
            // 英文单词 - 贴纸标签样式
            Text(wordCard.word)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "1E3A5F"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                )
        }
    }
}

// MARK: - 点阵背景
struct DotPatternBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let dotSpacing: CGFloat = 20
            let dotSize: CGFloat = 2
            
            Canvas { context, size in
                let rows = Int(size.height / dotSpacing) + 1
                let cols = Int(size.width / dotSpacing) + 1
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * dotSpacing
                        let y = CGFloat(row) * dotSpacing
                        
                        let rect = CGRect(
                            x: x - dotSize / 2,
                            y: y - dotSize / 2,
                            width: dotSize,
                            height: dotSize
                        )
                        
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(Color.gray.opacity(0.15))
                        )
                    }
                }
            }
        }
        .background(Color(hex: "F5F5F7"))
        .ignoresSafeArea()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: WordCard.self, inMemory: true)
}
