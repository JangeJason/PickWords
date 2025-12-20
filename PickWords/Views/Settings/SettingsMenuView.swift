import SwiftUI
import SwiftData

struct SettingsMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAPISettings = false
    @State private var showCollections = false
    @State private var showReviewList = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // API 设置
                    SettingsMenuItem(
                        icon: "key.fill",
                        iconColor: .orange,
                        title: "API 设置",
                        subtitle: "配置通义千问 API Key"
                    ) {
                        showAPISettings = true
                    }
                    
                    // 单词收藏夹
                    SettingsMenuItem(
                        icon: "folder.fill",
                        iconColor: AppTheme.lavender,
                        title: "单词收藏夹",
                        subtitle: "管理你的单词收藏集"
                    ) {
                        showCollections = true
                    }
                    
                    // 单词复习
                    SettingsMenuItem(
                        icon: "book.fill",
                        iconColor: AppTheme.pink,
                        title: "单词复习",
                        subtitle: "按日期复习收录的单词"
                    ) {
                        showReviewList = true
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.pink)
                }
            }
            .sheet(isPresented: $showAPISettings) {
                APIKeySettingView()
            }
            .sheet(isPresented: $showCollections) {
                CollectionListView()
            }
            .sheet(isPresented: $showReviewList) {
                DailyReviewListView()
            }
        }
    }
}

// MARK: - 设置菜单项
struct SettingsMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(iconColor)
                    )
                
                // 文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }
}

// MARK: - 按日期复习列表
struct DailyReviewListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordCard.createdAt, order: .reverse) private var allWordCards: [WordCard]
    
    // 按日期分组的单词
    private var groupedByDate: [(date: Date, cards: [WordCard])] {
        let calendar = Calendar.current
        var groups: [Date: [WordCard]] = [:]
        
        for card in allWordCards {
            let dayStart = calendar.startOfDay(for: card.createdAt)
            if groups[dayStart] != nil {
                groups[dayStart]?.append(card)
            } else {
                groups[dayStart] = [card]
            }
        }
        
        return groups.map { (date: $0.key, cards: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                if groupedByDate.isEmpty {
                    VStack(spacing: 16) {
                        Text("📚")
                            .font(.system(size: 60))
                        Text("还没有收录的单词")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(groupedByDate, id: \.date) { group in
                                NavigationLink {
                                    DailyReviewView(date: group.date, wordCards: group.cards)
                                } label: {
                                    DailyReviewRow(date: group.date, count: group.cards.count)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("单词复习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.pink)
                }
            }
        }
    }
}

// MARK: - 日期行
struct DailyReviewRow: View {
    let date: Date
    let count: Int
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(dateString)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    // 今天标签
                    if isToday {
                        Text("今天")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(AppTheme.pink)
                            )
                    }
                }
                
                Text("\(count) 个单词")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - 日期复习详情页
struct DailyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let wordCards: [WordCard]
    
    @State private var currentIndex = 0
    @State private var showAnswer = false
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 进度
                HStack {
                    Text("\(currentIndex + 1) / \(wordCards.count)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    // 进度条
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.lavender.opacity(0.2))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(AppTheme.pink)
                                .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(wordCards.count), height: 6)
                        }
                    }
                    .frame(width: 120, height: 6)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 卡片
                if currentIndex < wordCards.count {
                    let card = wordCards[currentIndex]
                    
                    VStack(spacing: 24) {
                        // 图片
                        if let uiImage = UIImage(data: card.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                        }
                        
                        // 中文释义（默认显示）
                        HStack {
                            Text("💭")
                            Text(card.translation)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        
                        // 答案区域（英文、音标、例句）
                        if showAnswer {
                            VStack(spacing: 12) {
                                Divider()
                                
                                // 英文单词 + 发音按钮
                                HStack(alignment: .top, spacing: 12) {
                                    Text(card.word)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.pink)
                                        .lineLimit(nil)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Button {
                                        SpeechService.shared.speak(card.word)
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(AppTheme.pink)
                                            .padding(8)
                                            .background(AppTheme.pink.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                    .padding(.top, 4)
                                }
                                
                                // 音标
                                Text(card.phonetic)
                                    .font(.system(size: 17, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                
                                Divider()
                                
                                // 例句
                                Text(card.exampleSentence)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                Text(card.exampleTranslation)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                                    .multilineTextAlignment(.center)

                                if !card.verbPhrases.isEmpty {
                                    Divider()

                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(card.verbPhrases.prefix(3), id: \.self) { item in
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.phrase)
                                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                                    .foregroundStyle(AppTheme.textPrimary)

                                                Text(item.translation)
                                                    .font(.system(size: 13, design: .rounded))
                                                    .foregroundStyle(AppTheme.textSecondary)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: AppTheme.pink.opacity(0.1), radius: 16, y: 8)
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // 底部按钮
                HStack(spacing: 40) {
                    if showAnswer {
                        // 上一个
                        Button {
                            if currentIndex > 0 {
                                withAnimation {
                                    currentIndex -= 1
                                    showAnswer = false
                                }
                            }
                        } label: {
                            Circle()
                                .fill(AppTheme.lavender.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(AppTheme.lavender)
                                )
                        }
                        .disabled(currentIndex == 0)
                        .opacity(currentIndex == 0 ? 0.5 : 1)
                        
                        // 下一个
                        Button {
                            if currentIndex >= wordCards.count - 1 {
                                dismiss()
                            } else {
                                withAnimation {
                                    currentIndex += 1
                                    showAnswer = false
                                }
                            }
                        } label: {
                            Circle()
                                .fill(AppTheme.pink)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: currentIndex >= wordCards.count - 1 ? "arrow.uturn.left" : "arrow.right")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(.white)
                                )
                        }
                    } else {
                        // 显示答案
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showAnswer = true
                            }
                        } label: {
                            Text("显示答案")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(AppTheme.pink)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(dateString)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsMenuView()
        .modelContainer(for: WordCard.self, inMemory: true)
}
