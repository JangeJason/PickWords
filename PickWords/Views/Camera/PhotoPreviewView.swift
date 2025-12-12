import SwiftUI
import SwiftData

struct PhotoPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    
    let image: UIImage
    let onDismiss: () -> Void
    
    @State private var isExtracting = true
    @State private var extractedImage: UIImage?
    @State private var showCropView = false
    @State private var showRecognitionResult = false
    @State private var recognitionResult: RecognitionResult?
    @State private var isRecognizing = false
    @State private var errorMessage: String?
    @State private var showSaveSuccess = false
    
    var body: some View {
        ZStack {
            // 背景：白色点阵（与首页一致）
            DotPatternBackground()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 主体展示区
                if isExtracting {
                    // 正在提取主体
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppTheme.textSecondary)
                        Text("正在识别物品...")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else if let extracted = extractedImage {
                    // 显示抠出的主体
                    Image(uiImage: extracted)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                } else {
                    // 提取失败，显示原图
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
                
                // 底部控制区
                bottomControls
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            extractSubject()
        }
        .fullScreenCover(isPresented: $showCropView) {
            ImageCropView(image: image) { croppedImage in
                // 用裁剪后的图片重新提取主体
                showCropView = false
                extractSubject(from: croppedImage)
            } onCancel: {
                showCropView = false
            }
        }
        .fullScreenCover(isPresented: $showRecognitionResult) {
            if let result = recognitionResult {
                RecognitionResultView(
                    result: result,
                    originalImage: image,
                    extractedImage: extractedImage,
                    onSave: { collectionId in
                        saveWordCard(result: result, collectionId: collectionId)
                    },
                    onRetry: {
                        showRecognitionResult = false
                        recognitionResult = nil
                    }
                )
            }
        }
        .alert("保存成功", isPresented: $showSaveSuccess) {
            Button("继续拍照") {
                onDismiss()
            }
        } message: {
            Text("单词卡片已保存到词库")
        }
    }
    
    // MARK: - 底部控制按钮
    private var bottomControls: some View {
        VStack(spacing: 0) {
            // 提示文字
            if !isExtracting && extractedImage != nil {
                Text("已识别物品，确认后继续")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 20)
            }
            
            // 按钮区域
            HStack(spacing: 50) {
                // 返回按钮
                Button {
                    onDismiss()
                } label: {
                    Circle()
                        .fill(AppTheme.secondaryBackground)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        )
                }
                
                // 确认按钮
                Button {
                    confirmAndRecognize()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "4ECDC4"), Color(hex: "44A08D")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: Color(hex: "4ECDC4").opacity(0.4), radius: 12, y: 6)
                        
                        if isRecognizing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(isExtracting || isRecognizing)
                .opacity((isExtracting || isRecognizing) ? 0.6 : 1)
                
                // 裁剪按钮
                Button {
                    showCropView = true
                } label: {
                    Circle()
                        .fill(AppTheme.secondaryBackground)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "crop")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        )
                }
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    // MARK: - 提取主体
    private func extractSubject(from sourceImage: UIImage? = nil) {
        let imageToProcess = sourceImage ?? image
        isExtracting = true
        
        Task {
            do {
                let extracted = try await VisionService.shared.extractSubject(from: imageToProcess)
                await MainActor.run {
                    extractedImage = extracted
                    isExtracting = false
                }
            } catch {
                await MainActor.run {
                    extractedImage = nil
                    isExtracting = false
                }
            }
        }
    }
    
    // MARK: - 确认并识别
    private func confirmAndRecognize() {
        isRecognizing = true
        
        Task {
            do {
                let imageToRecognize = extractedImage ?? image
                let result = try await AIService.shared.recognizeImage(imageToRecognize)
                await MainActor.run {
                    recognitionResult = result
                    isRecognizing = false
                    showRecognitionResult = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRecognizing = false
                }
            }
        }
    }
    
    // MARK: - 保存单词卡
    private func saveWordCard(result: RecognitionResult, collectionId: UUID?) {
        let imageToSave = extractedImage ?? image
        guard let imageData = imageToSave.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let wordCard = WordCard(
            imageData: imageData,
            word: result.word,
            phonetic: result.phonetic,
            translation: result.translation,
            exampleSentence: result.exampleSentence,
            exampleTranslation: result.exampleTranslation,
            collectionId: collectionId
        )
        
        modelContext.insert(wordCard)
        
        showRecognitionResult = false
        showSaveSuccess = true
    }
}

// MARK: - 图片裁剪视图
struct ImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var cropRect = CGRect(x: 50, y: 100, width: 250, height: 250)
    @State private var imageSize = CGSize.zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // 标题
                Text("拖动选择目标物品")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                
                Spacer()
                
                // 图片和裁剪框
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .background(
                            GeometryReader { imageGeometry in
                                Color.clear.onAppear {
                                    imageSize = imageGeometry.size
                                }
                            }
                        )
                        .overlay(
                            // 裁剪框
                            CropOverlay(cropRect: $cropRect, bounds: geometry.size)
                        )
                }
                .padding()
                
                Spacer()
                
                // 底部按钮
                HStack(spacing: 50) {
                    Button {
                        onCancel()
                    } label: {
                        Circle()
                            .fill(.gray.opacity(0.6))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.white)
                            )
                    }
                    
                    Button {
                        cropImage()
                    } label: {
                        Circle()
                            .fill(Color(hex: "4ECDC4"))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func cropImage() {
        // 简化版裁剪，实际裁剪需要计算坐标映射
        let cropped = image // 暂时返回原图
        onCrop(cropped)
    }
}

// MARK: - 裁剪框覆盖层
struct CropOverlay: View {
    @Binding var cropRect: CGRect
    let bounds: CGSize
    
    var body: some View {
        ZStack {
            // 暗色遮罩
            Rectangle()
                .fill(.black.opacity(0.5))
                .mask(
                    Rectangle()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .frame(width: cropRect.width, height: cropRect.height)
                                .position(x: cropRect.midX, y: cropRect.midY)
                                .blendMode(.destinationOut)
                        )
                )
            
            // 裁剪框边框
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white, lineWidth: 2)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let newX = min(max(cropRect.width / 2, cropRect.midX + value.translation.width), bounds.width - cropRect.width / 2)
                    let newY = min(max(cropRect.height / 2, cropRect.midY + value.translation.height), bounds.height - cropRect.height / 2)
                    cropRect = CGRect(
                        x: newX - cropRect.width / 2,
                        y: newY - cropRect.height / 2,
                        width: cropRect.width,
                        height: cropRect.height
                    )
                }
        )
    }
}

// MARK: - 识别结果视图（贴纸动画版）
struct RecognitionResultView: View {
    let result: RecognitionResult
    let originalImage: UIImage
    let extractedImage: UIImage?
    let onSave: (UUID?) -> Void
    let onRetry: () -> Void
    
    // 动画状态
    @State private var wordLabelOffset: CGFloat = 100
    @State private var wordLabelOpacity: Double = 0
    @State private var stickerOffset: CGFloat = 150
    @State private var contentOpacity: Double = 0
    @State private var showContent = false
    
    private var displayImage: UIImage {
        extractedImage ?? originalImage
    }
    
    var body: some View {
        ZStack {
            // 背景：白色点阵
            DotPatternBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // 物品单词贴纸组合
                VStack(spacing: -15) {
                    // 物品贴纸（带白边）
                    objectSticker
                    
                    // 单词标签贴纸（带白边）
                    wordLabelSticker
                        .offset(y: wordLabelOffset)
                        .opacity(wordLabelOpacity)
                }
                .offset(y: stickerOffset)
                
                // 音标
                Text(result.phonetic)
                    .font(.system(size: 18, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.top, 30)
                    .opacity(contentOpacity)
                
                // 例句区域
                exampleSection
                    .opacity(contentOpacity)
                
                Spacer()
                
                // 底部按钮
                bottomButtons
                    .opacity(contentOpacity)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - 物品贴纸（异型，无底片）
    private var objectSticker: some View {
        ZStack {
            // 白边效果：稍大一点的白色轮廓
            Image(uiImage: displayImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .colorMultiply(.white)
                .blur(radius: 2)
                .scaleEffect(1.03)
            
            // 主体图片
            Image(uiImage: displayImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
        }
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }
    
    // MARK: - 单词标签贴纸
    private var wordLabelSticker: some View {
        Text(result.word)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: "4A5568"))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
    }
    
    // MARK: - 例句区域
    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 中文释义
            HStack {
                Text("📖")
                Text(result.translation)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(AppTheme.lavender)
            
            // 英文例句
            Text(result.exampleSentence)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .italic()
            
            // 中文翻译
            Text(result.exampleTranslation)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .padding(.top, 30)
    }
    
    // MARK: - 底部按钮
    private var bottomButtons: some View {
        HStack(spacing: 60) {
            // 返回按钮
            Button {
                onRetry()
            } label: {
                Circle()
                    .fill(AppTheme.secondaryBackground)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    )
            }
            
            // 保存按钮
            Button {
                onSave(nil)
            } label: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.pink, Color(hex: "FF8FAB")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: AppTheme.pink.opacity(0.4), radius: 12, y: 6)
            }
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - 动画序列
    private func startAnimations() {
        // 第一步：单词标签贴上来
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            wordLabelOffset = 0
            wordLabelOpacity = 1
        }
        
        // 第二步：整个贴纸向上移动
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7)) {
            stickerOffset = 0
        }
        
        // 第三步：显示其他内容
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            contentOpacity = 1
            showContent = true
        }
    }
}

// MARK: - 收藏集选择器
struct CollectionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedId: UUID?
    
    @Query(sort: \Collection.createdAt, order: .reverse) private var collections: [Collection]
    
    var body: some View {
        NavigationStack {
            List {
                // 不选择收藏集
                Button {
                    selectedId = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("📋")
                            .font(.title2)
                        Text("不归类")
                        Spacer()
                        if selectedId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .foregroundStyle(.primary)
                
                // 收藏集列表
                ForEach(collections) { collection in
                    Button {
                        selectedId = collection.id
                        dismiss()
                    } label: {
                        HStack {
                            Text(collection.icon)
                                .font(.title2)
                            Text(collection.name)
                            Spacer()
                            if selectedId == collection.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("选择收藏集")
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

// MARK: - 棋盘格背景（显示透明区域）
struct CheckerboardBackground: View {
    let size: CGFloat = 10
    
    var body: some View {
        Canvas { context, canvasSize in
            let rows = Int(canvasSize.height / size) + 1
            let cols = Int(canvasSize.width / size) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let isWhite = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * size,
                        y: CGFloat(row) * size,
                        width: size,
                        height: size
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isWhite ? .white : .gray.opacity(0.3))
                    )
                }
            }
        }
    }
}

#Preview {
    PhotoPreviewView(image: UIImage(systemName: "photo")!) {
        print("Dismissed")
    }
}
