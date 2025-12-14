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
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 预览图
                    if let image = stickerImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppTheme.pink.opacity(0.3), radius: 15, y: 8)
                            .padding(.horizontal, 24)
                    } else {
                        ProgressView()
                            .frame(height: 300)
                            .tint(AppTheme.pink)
                    }
                    
                    // 样式选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("✨ 贴纸样式")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
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
                            .padding(.horizontal, 24)
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
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.pink.opacity(0.4), radius: 10, y: 5)
                    }
                    .disabled(isSaving || stickerImage == nil)
                    .opacity(isSaving || stickerImage == nil ? 0.6 : 1)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("🎨 生成贴纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppTheme.pink)
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
        case .classic: return .white
        case .modern: return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .minimal: return Color(red: 1.0, green: 0.75, blue: 0.8)
        case .colorful: return Color(red: 0.7, green: 0.85, blue: 1.0)
        }
    }
    
    private var textColor: Color {
        switch style {
        case .classic: return .black
        case .modern: return .white
        case .minimal: return .white
        case .colorful: return Color(red: 0.2, green: 0.3, blue: 0.5)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(styleColor)
                    .frame(width: 60, height: 44)
                    .overlay(
                        Text("Aa")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(textColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppTheme.pink : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: styleColor == .white ? .black.opacity(0.1) : .clear, radius: 4, y: 2)
                
                Text(style.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? AppTheme.pink : AppTheme.textSecondary)
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
