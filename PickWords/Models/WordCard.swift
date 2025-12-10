import SwiftData
import Foundation

@Model
final class WordCard {
    var id: UUID
    
    /// 原始照片数据
    @Attribute(.externalStorage)
    var imageData: Data
    
    /// 带单词贴纸的照片数据
    @Attribute(.externalStorage)
    var stickerImageData: Data?
    
    /// 英文单词
    var word: String
    
    /// 音标，如 /ˈkɒfi/
    var phonetic: String
    
    /// 中文释义
    var translation: String
    
    /// 英文例句
    var exampleSentence: String
    
    /// 例句中文翻译
    var exampleTranslation: String
    
    /// 所属收藏集 ID
    var collectionId: UUID?
    
    /// 创建时间
    var createdAt: Date
    
    init(
        imageData: Data,
        word: String,
        phonetic: String,
        translation: String,
        exampleSentence: String,
        exampleTranslation: String,
        collectionId: UUID? = nil
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.word = word
        self.phonetic = phonetic
        self.translation = translation
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.collectionId = collectionId
        self.createdAt = Date()
    }
}
