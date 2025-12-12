import SwiftUI
import SwiftData

struct CollectionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collection.createdAt, order: .reverse) private var collections: [Collection]
    
    @State private var showCreateSheet = false
    @State private var selectedCollection: Collection?
    @State private var showEditSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 可爱粉色背景
                AppTheme.background
                    .ignoresSafeArea()
                
                if collections.isEmpty {
                    emptyStateView
                } else {
                    collectionListView
                }
            }
            .navigationTitle("📁 场景收藏")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("新建")
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
            .sheet(isPresented: $showCreateSheet) {
                CreateCollectionView()
            }
            .sheet(isPresented: $showEditSheet) {
                if let collection = selectedCollection {
                    EditCollectionView(collection: collection)
                }
            }
        }
        .tint(AppTheme.pink)
    }
    
    // MARK: - 空状态
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "folder.badge.plus",
            title: "还没有收藏集",
            message: "创建收藏集，按场景分类你的单词",
            actionTitle: "创建收藏集"
        ) {
            showCreateSheet = true
        }
    }
    
    // MARK: - 收藏集列表
    private var collectionListView: some View {
        List {
            ForEach(collections) { collection in
                NavigationLink {
                    CollectionDetailView(collection: collection)
                } label: {
                    CollectionRow(collection: collection)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteCollection(collection)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    
                    Button {
                        selectedCollection = collection
                        showEditSheet = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteCollection(_ collection: Collection) {
        modelContext.delete(collection)
    }
}

// MARK: - 可爱收藏集行
struct CollectionRow: View {
    let collection: Collection
    
    @Query private var wordCards: [WordCard]
    
    init(collection: Collection) {
        self.collection = collection
        let collectionId = collection.id
        _wordCards = Query(filter: #Predicate<WordCard> { card in
            card.collectionId == collectionId
        })
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // 可爱图标背景
            ZStack {
                Circle()
                    .fill(AppTheme.lavender.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(collection.icon)
                    .font(.system(size: 26))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                
                HStack(spacing: 4) {
                    Text("📝")
                        .font(.system(size: 11))
                    Text("\(wordCards.count) 个单词")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.lavender)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 可爱创建收藏集
struct CreateCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedEmoji = "📁"
    
    private let emojis = ["📁", "🍳", "🛒", "✈️", "🏠", "🏢", "🎮", "📚", "🎵", "🏃", "🍔", "☕️", "🌳", "🚗", "👕", "💻", "🎀", "🌸", "⭐️", "💖", "🦋", "🌈", "🍰", "🧸"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 预览卡片
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.lavender.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Text(selectedEmoji)
                                    .font(.system(size: 40))
                            }
                            
                            Text(name.isEmpty ? "收藏集名称" : name)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(name.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                        .shadow(color: AppTheme.pink.opacity(0.1), radius: 10, y: 4)
                        
                        // 选择图标
                        VStack(alignment: .leading, spacing: 12) {
                            Text("✨ 选择图标")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.system(size: 28))
                                        .frame(width: 48, height: 48)
                                        .background(selectedEmoji == emoji ? AppTheme.pink.opacity(0.2) : AppTheme.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedEmoji == emoji ? AppTheme.pink : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedEmoji = emoji
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                        
                        // 输入名称
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📝 收藏集名称")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            TextField("输入名称...", text: $name)
                                .font(.system(size: 16, design: .rounded))
                                .padding()
                                .background(AppTheme.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                        
                        // 创建按钮
                        Button {
                            createCollection()
                        } label: {
                            HStack {
                                Text("✨")
                                Text("创建收藏集")
                                Text("✨")
                            }
                        }
                        .buttonStyle(CuteButtonStyle())
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("🌸 新建收藏集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("取消")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .tint(AppTheme.pink)
    }
    
    private func createCollection() {
        let collection = Collection(name: name, icon: selectedEmoji)
        modelContext.insert(collection)
        dismiss()
    }
}

// MARK: - 编辑收藏集
struct EditCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let collection: Collection
    
    @State private var name: String
    @State private var selectedEmoji: String
    
    private let emojis = ["📁", "🍳", "🛒", "✈️", "🏠", "🏢", "🎮", "📚", "🎵", "🏃", "🍔", "☕️", "🌳", "🚗", "👕", "💻"]
    
    init(collection: Collection) {
        self.collection = collection
        _name = State(initialValue: collection.name)
        _selectedEmoji = State(initialValue: collection.icon)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title)
                                .padding(8)
                                .background(selectedEmoji == emoji ? .blue.opacity(0.2) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    selectedEmoji = emoji
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("名称") {
                    TextField("收藏集名称", text: $name)
                }
            }
            .navigationTitle("编辑收藏集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        collection.name = name
        collection.icon = selectedEmoji
        dismiss()
    }
}

// MARK: - 收藏集详情
struct CollectionDetailView: View {
    let collection: Collection
    
    @Query private var wordCards: [WordCard]
    @State private var selectedCard: WordCard?
    
    init(collection: Collection) {
        self.collection = collection
        let collectionId = collection.id
        _wordCards = Query(filter: #Predicate<WordCard> { card in
            card.collectionId == collectionId
        }, sort: \WordCard.createdAt, order: .reverse)
    }
    
    var body: some View {
        Group {
            if wordCards.isEmpty {
                VStack(spacing: 20) {
                    Text(collection.icon)
                        .font(.system(size: 60))
                    
                    Text("暂无单词")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("拍照识别单词时可添加到此收藏集")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(wordCards) { card in
                            CollectionWordCardCell(wordCard: card)
                                .onTapGesture {
                                    selectedCard = card
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("\(collection.icon) \(collection.name)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedCard) { card in
            WordCardDetailSheet(wordCard: card)
        }
    }
}

// MARK: - 收藏集内的单词卡片 Cell
struct CollectionWordCardCell: View {
    let wordCard: WordCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = UIImage(data: wordCard.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(wordCard.word)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(wordCard.translation)
                    .font(.caption)
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

// MARK: - 单词卡片详情 Sheet
struct WordCardDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wordCard: WordCard
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let uiImage = UIImage(data: wordCard.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text(wordCard.word)
                                .font(.system(size: 32, weight: .bold))
                            
                            Text(wordCard.phonetic)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("释义")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(wordCard.translation)
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("例句")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(wordCard.exampleSentence)
                                .font(.body)
                                .italic()
                            Text(wordCard.exampleTranslation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
        }
    }
}

#Preview {
    CollectionListView()
        .modelContainer(for: [Collection.self, WordCard.self], inMemory: true)
}
