import SwiftData
import Foundation

@Model
final class Collection {
    var id: UUID
    
    /// 收藏集名称，如 "我的厨房"
    var name: String
    
    /// Emoji 图标
    var icon: String
    
    /// 创建时间
    var createdAt: Date
    
    init(name: String, icon: String = "📁") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.createdAt = Date()
    }
}
