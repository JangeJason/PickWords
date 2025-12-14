import SwiftUI
import PhotosUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var capturedImage: UIImage?
    @State private var showPreview = false
    @State private var showPhotoPicker = false
    @State private var captureButtonScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 全屏相机预览
            CameraPreviewView(capturedImage: $capturedImage)
                .ignoresSafeArea()
            
            // 覆盖层 UI
            VStack {
                // 顶部日期
                topDateView
                
                Spacer()
                
                // 取景框
                viewfinderFrame
                
                Spacer()
                
                // 底部按钮区
                bottomControls
            }
        }
        .statusBar(hidden: true)
        .onChange(of: capturedImage) { _, newValue in
            if newValue != nil {
                showPreview = true
            }
        }
        .fullScreenCover(isPresented: $showPreview) {
            if let image = capturedImage {
                PhotoPreviewView(image: image) {
                    capturedImage = nil
                    showPreview = false
                    dismiss() // 返回主页
                }
            }
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
    }
    
    // MARK: - 顶部日期
    private var topDateView: some View {
        Text(formattedDate)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            .padding(.top, 60)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: Date())
    }
    
    // MARK: - 取景框
    private var viewfinderFrame: some View {
        VStack(spacing: 20) {
            // 四角取景框
            ZStack {
                // 左上角
                CornerBracket()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .position(x: 40, y: 40)
                
                // 右上角
                CornerBracket()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(90))
                    .position(x: 260, y: 40)
                
                // 左下角
                CornerBracket()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .position(x: 40, y: 310)
                
                // 右下角
                CornerBracket()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(180))
                    .position(x: 260, y: 310)
            }
            .frame(width: 300, height: 350)
            
            // 提示文字
            Text("请将物品置于框内")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
    }
    
    // MARK: - 底部控制按钮
    private var bottomControls: some View {
        HStack(spacing: 60) {
            // 关闭按钮
            Button {
                dismiss()
            } label: {
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    )
            }
            
            // 拍摄按钮
            Button {
                capturePhoto()
            } label: {
                ZStack {
                    // 外圈
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 75, height: 75)
                    
                    // 内圈渐变
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFD6E8"),
                                    Color(hex: "C8F7DC"),
                                    Color(hex: "D4E5FF")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 62, height: 62)
                }
                .scaleEffect(captureButtonScale)
            }
            
            // 相册按钮
            Button {
                showPhotoPicker = true
            } label: {
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    )
            }
        }
        .padding(.bottom, 50)
    }
    
    // 拍照动作
    private func capturePhoto() {
        // 按钮动画
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            captureButtonScale = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                captureButtonScale = 1.0
            }
        }
        
        // 发送拍照通知
        NotificationCenter.default.post(name: .capturePhoto, object: nil)
    }
}

// MARK: - 角框形状
struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // L 形角框
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        return path
    }
}

// MARK: - 相机预览
struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraPreviewView
        
        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }
        
        func didCapturePhoto(_ image: UIImage) {
            parent.capturedImage = image
        }
    }
}

// MARK: - 相机控制器协议
protocol CameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
}

// MARK: - 相机控制器
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        
        // 监听拍照通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(capturePhoto),
            name: .capturePhoto,
            object: nil
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera),
              let session = captureSession else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        photoOutput = AVCapturePhotoOutput()
        if let output = photoOutput, session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        if let layer = previewLayer {
            view.layer.addSublayer(layer)
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    deinit {
        captureSession?.stopRunning()
        NotificationCenter.default.removeObserver(self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didCapturePhoto(image)
        }
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let capturePhoto = Notification.Name("capturePhoto")
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
