import Foundation
import UIKit

/// AI 识别结果
struct RecognitionResult: Codable {
    let word: String              // 英文单词
    let phonetic: String          // 音标
    let translation: String       // 中文释义
    let exampleSentence: String   // 英文例句
    let exampleTranslation: String // 例句中文翻译
}

/// 通义千问 VL 服务
final class GeminiService {
    static let shared = GeminiService()
    
    private let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    
    private init() {}
    
    /// 检查是否已配置 API Key（内置或用户配置）
    var isConfigured: Bool {
        getAPIKey() != nil
    }
    
    /// 获取 API Key（优先使用内置，其次使用用户配置）
    private func getAPIKey() -> String? {
        // 优先使用内置 Key
        let builtInKey = Secrets.geminiAPIKey
        if !builtInKey.isEmpty && builtInKey != "YOUR_API_KEY_HERE" {
            return builtInKey
        }
        // 其次使用用户配置的 Key
        return KeychainService.shared.getGeminiAPIKey()
    }
    
    /// 识别图片中的物体并返回单词信息
    func recognizeImage(_ image: UIImage) async throws -> RecognitionResult {
        guard let apiKey = getAPIKey() else {
            throw AIError.apiKeyNotConfigured
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw AIError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // 构建请求
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let prompt = """
        你是一个英语单词学习助手。请识别图片中的**实际物品**（如耳机、杯子、手机等），而不是物品上的图案、logo或卡通形象。

        规则：
        1. 重点识别物品本身是什么，忽略装饰性元素
        2. 如果物品有特殊主题（如卡通主题），可以在单词中体现，格式如 "themed earbuds"
        3. 单词应该是日常实用的英语词汇

        请返回以下 JSON 格式（只返回 JSON，不要其他内容）：
        {
            "word": "英文单词或短语（描述物品本身）",
            "phonetic": "音标（国际音标格式）",
            "translation": "中文释义",
            "exampleSentence": "一个使用该单词的英文例句",
            "exampleTranslation": "例句的中文翻译"
        }
        """
        
        let requestBody: [String: Any] = [
            "model": "qwen-vl-plus",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            // 尝试解析错误信息
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // 解析响应（OpenAI 兼容格式）
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError
        }
        
        // 提取 JSON（处理可能的 markdown 代码块）
        let jsonString = extractJSON(from: content)
        
        guard let jsonData = jsonString.data(using: .utf8),
              let result = try? JSONDecoder().decode(RecognitionResult.self, from: jsonData) else {
            print("解析失败，原始响应: \(content)")
            throw AIError.parseError
        }
        
        return result
    }
    
    /// 从文本中提取 JSON
    private func extractJSON(from text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除 markdown 代码块标记
        if result.hasPrefix("```json") {
            result = String(result.dropFirst(7))
        } else if result.hasPrefix("```") {
            result = String(result.dropFirst(3))
        }
        
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// AI 错误类型
enum AIError: LocalizedError {
    case apiKeyNotConfigured
    case imageProcessingFailed
    case networkError
    case apiError(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "API Key 未配置"
        case .imageProcessingFailed:
            return "图片处理失败"
        case .networkError:
            return "网络连接失败"
        case .apiError(let message):
            return "API 错误: \(message)"
        case .parseError:
            return "响应解析失败"
        }
    }
}
