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
            Group {
                if collections.isEmpty {
                    emptyStateView
                } else {
                    collectionListView
                }
            }
            .navigationTitle("场景收藏")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
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

// MARK: - 收藏集行
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
        HStack(spacing: 12) {
            Text(collection.icon)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                
                Text("\(wordCards.count) 个单词")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 创建收藏集
struct CreateCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedEmoji = "📁"
    
    private let emojis = ["📁", "🍳", "🛒", "✈️", "🏠", "🏢", "🎮", "📚", "🎵", "🏃", "🍔", "☕️", "🌳", "🚗", "👕", "💻"]
    
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
                
                Section {
                    HStack {
                        Text(selectedEmoji)
                            .font(.largeTitle)
                        Text(name.isEmpty ? "收藏集名称" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } header: {
                    Text("预览")
                }
            }
            .navigationTitle("新建收藏集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("创建") {
                        createCollection()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
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
