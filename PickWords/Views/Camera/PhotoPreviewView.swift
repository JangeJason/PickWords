import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    @State private var isAnalyzing = false
    @State private var recognitionResult: RecognitionResult?
    @State private var errorMessage: String?
    @State private var showResult = false
    
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
                            Text("AI 正在识别...")
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
                        image: image,
                        onSave: {
                            // TODO: PR #10 实现保存到数据库
                            showResult = false
                            onDismiss()
                        },
                        onRetry: {
                            showResult = false
                            recognitionResult = nil
                        }
                    )
                }
            }
        }
    }
    
    private func analyzeImage() {
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await GeminiService.shared.recognizeImage(image)
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
    let image: UIImage
    let onSave: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 图片
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
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

#Preview {
    PhotoPreviewView(image: UIImage(systemName: "photo")!) {
        print("Dismissed")
    }
}
