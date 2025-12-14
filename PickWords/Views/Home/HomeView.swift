import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordCard.createdAt, order: .reverse) private var allWordCards: [WordCard]
    
    @State private var showCamera = false
    @State private var selectedCard: WordCard?
    @State private var selectedDate = Date()
    @State private var showSettings = false
    
    // 选中日期的单词
    private var selectedDateWordCards: [WordCard] {
        let calendar = Calendar.current
        return allWordCards.filter { card in
            calendar.isDate(card.createdAt, inSameDayAs: selectedDate)
        }
    }
    
    // 是否是今天（不能切换到未来）
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    @State private var cameraButtonScale: CGFloat = 1.0
    @State private var cameraButtonRotation: Double = 0
    @State private var pulseAnimation = false
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 背景 - 浅灰色点阵
            DotPatternBackground()
            
            VStack(spacing: 0) {
                // 顶部区域
                headerView
                
                // 内容区域 - 大卡片包装
                cardContentView
                
                Spacer()
                
                // 底部控制区：左箭头 + 相机 + 右箭头
                bottomControlsView
                    .padding(.bottom, 30)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
        .sheet(item: $selectedCard) { card in
            WordCardDetailView(wordCard: card)
        }
        .sheet(isPresented: $showSettings) {
            SettingsMenuView()
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    // MARK: - 顶部区域
    private var headerView: some View {
        HStack(alignment: .top) {
            // 左侧占位（平衡布局）
            Circle()
                .fill(.clear)
                .frame(width: 44, height: 44)
                .padding(.leading, 20)
            
            Spacer()
            
            // 中间 - 日期和今日单词数
            VStack(spacing: 6) {
                Text(formattedDate)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text(dateSummaryText)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // 右侧 - 用户头像
            userAvatar
                .padding(.trailing, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: selectedDate)
    }
    
    // 日期摘要文字
    private var dateSummaryText: String {
        if isToday {
            return "今日收录 \(selectedDateWordCards.count) 个单词"
        } else {
            return "收录了 \(selectedDateWordCards.count) 个单词"
        }
    }
    
    // 用户头像（点击进入设置）
    private var userAvatar: some View {
        Button {
            showSettings = true
        } label: {
            Circle()
                .fill(AppTheme.lavender.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.lavender)
                )
        }
    }
    
    // MARK: - 大卡片内容区域（带丝滑动画）
    private var cardContentView: some View {
        ScrollView {
            if selectedDateWordCards.isEmpty {
                emptyStateView
            } else {
                wordCardsGrid
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .offset(x: cardOffset)
        .opacity(cardOpacity)
        .scaleEffect(cardOpacity == 1 ? 1 : 0.95)
    }
    
    // MARK: - 底部控制区
    private var bottomControlsView: some View {
        HStack(alignment: .bottom, spacing: 40) {
            // 左箭头 - 前一天
            Button {
                goToPreviousDay()
            } label: {
                Circle()
                    .fill(AppTheme.lavender.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.lavender)
                    )
            }
            .disabled(isAnimating)
            .padding(.bottom, 20) // 与相机按钮底部对齐
            
            // 相机按钮
            cameraButton
            
            // 右箭头 - 后一天
            Button {
                goToNextDay()
            } label: {
                Circle()
                    .fill(isToday ? AppTheme.textSecondary.opacity(0.1) : AppTheme.lavender.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isToday ? AppTheme.textSecondary.opacity(0.3) : AppTheme.lavender)
                    )
            }
            .disabled(isToday || isAnimating)
            .padding(.bottom, 20) // 与相机按钮底部对齐
        }
    }
    
    // MARK: - 丝滑切换动画
    private func goToNextDay() {
        guard !isAnimating, !isToday else { return }
        isAnimating = true
        
        // 向左滑出
        withAnimation(.easeInOut(duration: 0.15)) {
            cardOffset = -50
            cardOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // 切换日期
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            cardOffset = 50
            
            // 从右滑入
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                cardOffset = 0
                cardOpacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isAnimating = false
            }
        }
    }
    
    private func goToPreviousDay() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // 向右滑出
        withAnimation(.easeInOut(duration: 0.15)) {
            cardOffset = 50
            cardOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // 切换日期
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            cardOffset = -50
            
            // 从左滑入
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                cardOffset = 0
                cardOpacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isAnimating = false
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
            
            Text(isToday ? "今天还没有收录单词" : "这一天没有收录单词")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            
            if isToday {
                Text("点击下方相机按钮开始")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
            }
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
            ForEach(selectedDateWordCards) { card in
                StickerWordCard(wordCard: card)
                    .onTapGesture {
                        selectedCard = card
                    }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - 底部相机按钮（精美动效）
    private var cameraButton: some View {
        Button {
            // 点击动画
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                cameraButtonScale = 0.85
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    cameraButtonScale = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCamera = true
            }
        } label: {
            ZStack {
                // 外层脉冲光环
                Circle()
                    .stroke(AppTheme.pink.opacity(0.3), lineWidth: 2)
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.6)
                
                // 中层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.pink.opacity(0.3), AppTheme.pink.opacity(0)],
                            center: .center,
                            startRadius: 30,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)
                
                // 主按钮
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.pink, Color(hex: "FF8FAB")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: AppTheme.pink.opacity(0.5), radius: 15, y: 8)
                
                // 内部高光
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: 70, height: 70)
                    .clipShape(
                        Circle()
                            .offset(y: -5)
                    )
                
                // 相机图标
                Image(systemName: "camera.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            }
            .scaleEffect(cameraButtonScale)
        }
        .padding(.bottom, 50)
    }
    
    // 脉冲动画
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
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
