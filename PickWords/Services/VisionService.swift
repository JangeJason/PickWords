import Foundation
import UIKit
import Vision
import CoreImage

/// Apple Vision 本地图像处理服务
final class VisionService {
    static let shared = VisionService()
    
    private init() {}
    
    /// 主体抠图 - 使用 iOS 17+ 的 Subject Lifting API
    /// 如果直接提取失败，会先尝试裁剪到显著区域再提取
    @available(iOS 17.0, *)
    func extractSubject(from image: UIImage) async throws -> UIImage {
        // 先将图片转为正确方向的版本
        let normalizedImage = normalizeImageOrientation(image)
        
        // 首先尝试直接提取
        if let result = try? await performSubjectExtraction(from: normalizedImage) {
            return result
        }
        
        // 如果失败，尝试先裁剪到显著区域再提取
        if let croppedImage = await cropToSalientRegion(normalizedImage),
           let result = try? await performSubjectExtraction(from: croppedImage) {
            return result
        }
        
        // 都失败了，返回原图
        throw VisionError.noSubjectFound
    }
    
    /// 执行主体提取
    @available(iOS 17.0, *)
    private func performSubjectExtraction(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw VisionError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = request.results?.first as? VNInstanceMaskObservation,
                      !result.allInstances.isEmpty else {
                    continuation.resume(throwing: VisionError.noSubjectFound)
                    return
                }
                
                do {
                    // 生成蒙版
                    let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: VNImageRequestHandler(cgImage: cgImage))
                    
                    // 应用蒙版
                    let ciImage = CIImage(cgImage: cgImage)
                    let maskImage = CIImage(cvPixelBuffer: mask)
                    
                    guard let filter = CIFilter(name: "CIBlendWithMask") else {
                        continuation.resume(throwing: VisionError.imageProcessingFailed)
                        return
                    }
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    filter.setValue(maskImage, forKey: kCIInputMaskImageKey)
                    filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
                    
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
    
    /// 裁剪到显著区域（用于远距离拍摄时先放大目标区域）
    private func cropToSalientRegion(_ image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        return await withCheckedContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                guard error == nil,
                      let result = request.results?.first as? VNSaliencyImageObservation,
                      let salientObjects = result.salientObjects,
                      !salientObjects.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // 找到最大的显著区域
                var combinedRect = salientObjects[0].boundingBox
                for obj in salientObjects {
                    combinedRect = combinedRect.union(obj.boundingBox)
                }
                
                // 扩大区域（留一些边距）
                let padding: CGFloat = 0.1
                let expandedRect = CGRect(
                    x: max(0, combinedRect.origin.x - padding),
                    y: max(0, combinedRect.origin.y - padding),
                    width: min(1.0 - max(0, combinedRect.origin.x - padding), combinedRect.width + padding * 2),
                    height: min(1.0 - max(0, combinedRect.origin.y - padding), combinedRect.height + padding * 2)
                )
                
                // 转换为像素坐标（Vision 坐标系 y 轴是反的）
                let imageWidth = CGFloat(cgImage.width)
                let imageHeight = CGFloat(cgImage.height)
                
                let cropRect = CGRect(
                    x: expandedRect.origin.x * imageWidth,
                    y: (1 - expandedRect.origin.y - expandedRect.height) * imageHeight,
                    width: expandedRect.width * imageWidth,
                    height: expandedRect.height * imageHeight
                )
                
                // 裁剪图片
                guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
                continuation.resume(returning: croppedImage)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// 修正图片方向
    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
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
