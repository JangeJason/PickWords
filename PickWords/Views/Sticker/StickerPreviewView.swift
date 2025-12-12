import SwiftUI
import Photos

struct StickerPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let originalImage: UIImage
    let word: String
    let phonetic: String
    let translation: String
    
    @State private var selectedStyle: StickerService.StickerStyle = .classic
    @State private var stickerImage: UIImage?
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 预览图
                if let image = stickerImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                        .padding(.horizontal)
                } else {
                    ProgressView()
                        .frame(height: 300)
                }
                
                // 样式选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("贴纸样式")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(StickerService.StickerStyle.allCases, id: \.self) { style in
                                StyleButton(
                                    style: style,
                                    isSelected: selectedStyle == style
                                ) {
                                    selectedStyle = style
                                    generateSticker()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // 保存按钮
                Button {
                    saveToAlbum()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text("保存到相册")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSaving || stickerImage == nil)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("生成贴纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateSticker()
            }
            .alert("保存成功", isPresented: $showSaveSuccess) {
                Button("好的") {
                    dismiss()
                }
            } message: {
                Text("图片已保存到相册")
            }
            .alert("保存失败", isPresented: $showSaveError) {
                Button("好的") {}
            } message: {
                Text("请确保已授权访问相册")
            }
        }
    }
    
    private func generateSticker() {
        stickerImage = StickerService.shared.generateStickerImage(
            originalImage: originalImage,
            word: word,
            phonetic: phonetic,
            translation: translation,
            style: selectedStyle
        )
    }
    
    private func saveToAlbum() {
        guard let image = stickerImage else { return }
        
        isSaving = true
        
        // 请求相册权限
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    isSaving = false
                    showSaveSuccess = true
                } else {
                    isSaving = false
                    showSaveError = true
                }
            }
        }
    }
}

// MARK: - 样式按钮
struct StyleButton: View {
    let style: StickerService.StickerStyle
    let isSelected: Bool
    let action: () -> Void
    
    private var styleColor: Color {
        switch style {
        case .classic: return .black
        case .modern: return .white
        case .minimal: return .blue
        case .colorful: return .orange
        }
    }
    
    private var textColor: Color {
        switch style {
        case .modern: return .black
        default: return .white
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(styleColor)
                    .frame(width: 60, height: 40)
                    .overlay(
                        Text("Aa")
                            .font(.headline)
                            .foregroundStyle(textColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? .blue : .clear, lineWidth: 3)
                    )
                
                Text(style.rawValue)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
        }
    }
}

#Preview {
    StickerPreviewView(
        originalImage: UIImage(systemName: "photo")!,
        word: "Coffee",
        phonetic: "/ˈkɒfi/",
        translation: "咖啡"
    )
}
