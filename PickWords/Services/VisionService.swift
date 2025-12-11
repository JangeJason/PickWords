import Foundation
import UIKit
import Vision
import CoreImage

/// Apple Vision 本地图像处理服务
final class VisionService {
    static let shared = VisionService()
    
    private init() {}
    
    /// 主体抠图 - 使用 iOS 17+ 的 Subject Lifting API
    @available(iOS 17.0, *)
    func extractSubject(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw VisionError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = request.results?.first as? VNInstanceMaskObservation else {
                    continuation.resume(throwing: VisionError.noSubjectFound)
                    return
                }
                
                do {
                    // 生成蒙版
                    let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: VNImageRequestHandler(cgImage: cgImage))
                    
                    // 应用蒙版
                    let ciImage = CIImage(cgImage: cgImage)
                    let maskImage = CIImage(cvPixelBuffer: mask)
                    
                    let filter = CIFilter.blendWithMask()
                    filter.inputImage = ciImage
                    filter.maskImage = maskImage
                    filter.backgroundImage = CIImage.empty()
                    
                    guard let outputImage = filter.outputImage else {
                        continuation.resume(throwing: VisionError.imageProcessingFailed)
                        return
                    }
                    
                    let context = CIContext()
                    guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                        continuation.resume(throwing: VisionError.imageProcessingFailed)
                        return
                    }
                    
                    let resultImage = UIImage(cgImage: outputCGImage)
                    continuation.resume(returning: resultImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 检测图片中的主要物体区域
    func detectObjects(in image: UIImage) async throws -> [CGRect] {
        guard let cgImage = image.cgImage else {
            throw VisionError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeAnimalsRequest { request, error in
                if let error = error {
                    // 如果动物检测失败，尝试通用对象检测
                    self.detectGenericObjects(cgImage: cgImage, continuation: continuation)
                    return
                }
                
                let rects = request.results?.compactMap { ($0 as? VNRecognizedObjectObservation)?.boundingBox } ?? []
                
                if rects.isEmpty {
                    self.detectGenericObjects(cgImage: cgImage, continuation: continuation)
                } else {
                    continuation.resume(returning: rects)
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectGenericObjects(cgImage: CGImage, continuation: CheckedContinuation<[CGRect], Error>) {
        // 使用 Saliency 检测主要区域
        let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
            
            guard let result = request.results?.first as? VNSaliencyImageObservation,
                  let salientObjects = result.salientObjects else {
                continuation.resume(returning: [])
                return
            }
            
            let rects = salientObjects.map { $0.boundingBox }
            continuation.resume(returning: rects)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

// MARK: - 错误类型

enum VisionError: LocalizedError {
    case imageProcessingFailed
    case noSubjectFound
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "图片处理失败"
        case .noSubjectFound:
            return "未检测到主体"
        }
    }
}
