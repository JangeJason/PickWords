import SwiftUI
import SwiftData

struct PhotoPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    
    let image: UIImage
    let onDismiss: () -> Void
    
    @State private var isAnalyzing = false
    @State private var analysisStatus = ""
    @State private var recognitionResult: RecognitionResult?
    @State private var extractedImage: UIImage?  // 抠图后的主体
    @State private var errorMessage: String?
    @State private var showResult = false
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 照片预览
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
                
                // 底部操作栏
                VStack(spacing: 16) {
                    if isAnalyzing {
                        // 分析中状态
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(analysisStatus)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else if let error = errorMessage {
                        // 错误状态
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("重试") {
                                analyzeImage()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else {
                        // 操作按钮
                        HStack(spacing: 20) {
                            // 重拍按钮
                            Button {
                                onDismiss()
                            } label: {
                                Label("重拍", systemImage: "arrow.counterclockwise")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.gray.opacity(0.15))
                                    .foregroundStyle(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            // 识别按钮
                            Button {
                                analyzeImage()
                            } label: {
                                Label("识别", systemImage: "sparkles")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("照片预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let result = recognitionResult {
                    RecognitionResultView(
                        result: result,
                        originalImage: image,
                        extractedImage: extractedImage,
                        onSave: {
                            saveWordCard(result: result)
                        },
                        onRetry: {
                            showResult = false
                            recognitionResult = nil
                            extractedImage = nil
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
    }
    
    private func saveWordCard(result: RecognitionResult) {
        // 优先使用抠图后的图片，否则使用原图
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
            exampleTranslation: result.exampleTranslation
        )
        
        modelContext.insert(wordCard)
        
        showResult = false
        showSaveSuccess = true
    }
    
    private func analyzeImage() {
        isAnalyzing = true
        errorMessage = nil
        analysisStatus = "正在提取主体..."
        
        Task {
            do {
                // 第一步：抠图提取主体
                var imageToRecognize = image
                do {
                    let extracted = try await VisionService.shared.extractSubject(from: image)
                    imageToRecognize = extracted
                    await MainActor.run {
                        extractedImage = extracted
                        analysisStatus = "AI 正在识别..."
                    }
                } catch {
                    // 抠图失败，使用原图继续识别
                    print("抠图失败，使用原图: \(error.localizedDescription)")
                    await MainActor.run {
                        extractedImage = nil
                        analysisStatus = "AI 正在识别..."
                    }
                }
                
                // 第二步：AI 识别
                let result = try await GeminiService.shared.recognizeImage(imageToRecognize)
                await MainActor.run {
                    recognitionResult = result
                    isAnalyzing = false
                    showResult = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }
}

// MARK: - 识别结果视图
struct RecognitionResultView: View {
    let result: RecognitionResult
    let originalImage: UIImage
    let extractedImage: UIImage?
    let onSave: () -> Void
    let onRetry: () -> Void
    
    // 显示的图片：优先显示抠图后的主体
    private var displayImage: UIImage {
        extractedImage ?? originalImage
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 图片（抠图后的主体或原图）
                    ZStack {
                        // 棋盘格背景（显示透明区域）
                        if extractedImage != nil {
                            CheckerboardBackground()
                        }
                        
                        Image(uiImage: displayImage)
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // 抠图提示
                    if extractedImage != nil {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.green)
                            Text("已智能提取主体")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // 单词卡片
                    VStack(spacing: 16) {
                        // 单词和音标
                        VStack(spacing: 8) {
                            Text(result.word)
                                .font(.system(size: 36, weight: .bold))
                            
                            Text(result.phonetic)
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
                        Text(result.translation)
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
                        Text(result.exampleSentence)
                            .font(.body)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(result.exampleTranslation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // 按钮
                    HStack(spacing: 16) {
                        Button {
                            onRetry()
                        } label: {
                            Label("重拍", systemImage: "arrow.counterclockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.gray.opacity(0.15))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            onSave()
                        } label: {
                            Label("保存", systemImage: "square.and.arrow.down")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("识别结果")
            .navigationBarTitleDisplayMode(.inline)
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
