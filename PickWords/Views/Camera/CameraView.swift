import SwiftUI
import PhotosUI

struct CameraView: View {
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var showPreview = false
    @State private var showAPIKeySetting = false
    @State private var isAPIKeyConfigured = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // 图标
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                // 标题
                Text("拍照识物")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("拍摄物品，AI 自动识别英文单词")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // API Key 未配置提示
                if !isAPIKeyConfigured {
                    Button {
                        showAPIKeySetting = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("请先配置 API Key")
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                
                Spacer()
                
                // 按钮区域
                VStack(spacing: 16) {
                    // 拍照按钮
                    Button {
                        showCamera = true
                    } label: {
                        Label("拍照", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 从相册选择
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("从相册选择", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.gray.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle("拍照")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAPIKeySetting = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showAPIKeySetting) {
                APIKeySettingView()
            }
            .onAppear {
                isAPIKeyConfigured = GeminiService.shared.isConfigured
            }
            .onChange(of: showAPIKeySetting) { _, newValue in
                if !newValue {
                    // 设置页面关闭后刷新状态
                    isAPIKeyConfigured = GeminiService.shared.isConfigured
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $capturedImage, sourceType: .camera)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: .init(get: { nil }, set: { item in
                Task {
                    if let item = item,
                       let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        capturedImage = uiImage
                    }
                }
            }))
            .onChange(of: capturedImage) { oldValue, newValue in
                if newValue != nil {
                    showPreview = true
                }
            }
            .fullScreenCover(isPresented: $showPreview) {
                if let image = capturedImage {
                    PhotoPreviewView(image: image) {
                        // 关闭预览
                        capturedImage = nil
                        showPreview = false
                    }
                }
            }
        }
    }
}

// MARK: - UIImagePickerController 封装
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CameraView()
}
