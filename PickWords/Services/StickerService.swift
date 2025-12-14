import UIKit
import SwiftUI

/// 单词贴纸生成服务
final class StickerService {
    static let shared = StickerService()
    
    private init() {}
    
    /// 贴纸样式
    enum StickerStyle: String, CaseIterable {
        case classic = "经典"
        case modern = "现代"
        case minimal = "简约"
        case colorful = "多彩"
    }
    
    /// 生成带贴纸的图片
    func generateStickerImage(
        originalImage: UIImage,
        word: String,
        phonetic: String,
        translation: String,
        style: StickerStyle = .classic
    ) -> UIImage? {
        let imageSize = originalImage.size
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, originalImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制原图
        originalImage.draw(at: .zero)
        
        // 计算贴纸尺寸和位置
        let stickerHeight: CGFloat = imageSize.height * 0.15
        let stickerWidth: CGFloat = imageSize.width * 0.9
        let stickerX: CGFloat = (imageSize.width - stickerWidth) / 2
        let stickerY: CGFloat = imageSize.height - stickerHeight - 20
        let stickerRect = CGRect(x: stickerX, y: stickerY, width: stickerWidth, height: stickerHeight)
        
        // 根据样式绘制贴纸
        drawSticker(in: stickerRect, word: word, phonetic: phonetic, translation: translation, style: style)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func drawSticker(
        in rect: CGRect,
        word: String,
        phonetic: String,
        translation: String,
        style: StickerStyle
    ) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // 获取样式配置
        let config = styleConfig(for: style)
        
        // 绘制背景
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 16)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 4), blur: 10, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        config.backgroundColor.setFill()
        path.fill()
        context.restoreGState()
        
        // 绘制文字
        let padding: CGFloat = 16
        let contentRect = rect.insetBy(dx: padding, dy: padding)
        
        // 单词 - 自适应字体大小
        var wordFontSize = rect.height * 0.35
        var wordFont = UIFont.systemFont(ofSize: wordFontSize, weight: .bold)
        var wordAttributes: [NSAttributedString.Key: Any] = [
            .font: wordFont,
            .foregroundColor: config.textColor
        ]
        var wordSize = word.size(withAttributes: wordAttributes)
        
        // 如果单词太长，缩小字体
        let maxWordWidth = contentRect.width * 0.65
        while wordSize.width > maxWordWidth && wordFontSize > rect.height * 0.2 {
            wordFontSize -= 2
            wordFont = UIFont.systemFont(ofSize: wordFontSize, weight: .bold)
            wordAttributes[.font] = wordFont
            wordSize = word.size(withAttributes: wordAttributes)
        }
        
        let wordRect = CGRect(
            x: contentRect.minX,
            y: contentRect.minY,
            width: maxWordWidth,
            height: wordSize.height
        )
        word.draw(in: wordRect, withAttributes: wordAttributes)
        
        // 音标
        let phoneticFont = UIFont.systemFont(ofSize: rect.height * 0.18, weight: .regular)
        let phoneticAttributes: [NSAttributedString.Key: Any] = [
            .font: phoneticFont,
            .foregroundColor: config.secondaryColor
        ]
        let phoneticRect = CGRect(
            x: contentRect.minX,
            y: wordRect.maxY + 4,
            width: contentRect.width * 0.6,
            height: rect.height * 0.2
        )
        phonetic.draw(in: phoneticRect, withAttributes: phoneticAttributes)
        
        // 中文释义（右侧）
        let translationFont = UIFont.systemFont(ofSize: rect.height * 0.22, weight: .medium)
        let translationAttributes: [NSAttributedString.Key: Any] = [
            .font: translationFont,
            .foregroundColor: config.textColor
        ]
        let translationSize = translation.size(withAttributes: translationAttributes)
        let translationRect = CGRect(
            x: contentRect.maxX - translationSize.width,
            y: contentRect.midY - translationSize.height / 2,
            width: translationSize.width,
            height: translationSize.height
        )
        translation.draw(in: translationRect, withAttributes: translationAttributes)
    }
    
    private func styleConfig(for style: StickerStyle) -> (backgroundColor: UIColor, textColor: UIColor, secondaryColor: UIColor) {
        switch style {
        case .classic:
            return (
                UIColor.white,
                UIColor.black,
                UIColor.darkGray
            )
        case .modern:
            return (
                UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0),
                UIColor.white,
                UIColor.lightGray
            )
        case .minimal:
            return (
                UIColor(red: 1.0, green: 0.75, blue: 0.8, alpha: 1.0), // 粉色
                UIColor.white,
                UIColor.white.withAlphaComponent(0.9)
            )
        case .colorful:
            return (
                UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0), // 淡蓝色
                UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0),
                UIColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 1.0)
            )
        }
    }
    
    /// 保存图片到相册
    func saveToPhotoAlbum(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        completion(true, nil)
    }
}
