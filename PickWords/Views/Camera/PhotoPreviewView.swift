import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    @State private var isAnalyzing = false
    
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
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("AI 正在识别...")
                                .foregroundStyle(.secondary)
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
        }
    }
    
    private func analyzeImage() {
        isAnalyzing = true
        
        // TODO: PR #7 中实现 AI 识别
        // 模拟识别延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isAnalyzing = false
            // 暂时只显示提示
        }
    }
}

#Preview {
    PhotoPreviewView(image: UIImage(systemName: "photo")!) {
        print("Dismissed")
    }
}
