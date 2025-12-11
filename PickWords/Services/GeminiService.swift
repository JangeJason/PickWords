import Foundation
import UIKit

/// Gemini API 识别结果
struct RecognitionResult: Codable {
    let word: String              // 英文单词
    let phonetic: String          // 音标
    let translation: String       // 中文释义
    let exampleSentence: String   // 英文例句
    let exampleTranslation: String // 例句中文翻译
}

/// Gemini 1.5 Flash 服务
final class GeminiService {
    static let shared = GeminiService()
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    private init() {}
    
    /// 检查是否已配置 API Key（内置或用户配置）
    var isConfigured: Bool {
        getAPIKey() != nil
    }
    
    /// 获取 API Key（优先使用内置，其次使用用户配置）
    private func getAPIKey() -> String? {
        // 优先使用内置 Key
        let builtInKey = Secrets.geminiAPIKey
        if !builtInKey.isEmpty {
            return builtInKey
        }
        // 其次使用用户配置的 Key
        return KeychainService.shared.getGeminiAPIKey()
    }
    
    /// 识别图片中的物体并返回单词信息
    func recognizeImage(_ image: UIImage) async throws -> RecognitionResult {
        guard let apiKey = getAPIKey() else {
            throw GeminiError.apiKeyNotConfigured
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // 构建请求
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        分析这张图片中最主要的物体，返回以下 JSON 格式（只返回 JSON，不要其他内容）：
        {
          "word": "英文单词（小写）",
          "phonetic": "音标（如 /ˈkɒfi/）",
          "translation": "中文释义",
          "exampleSentence": "包含该单词的英文例句",
          "exampleTranslation": "例句的中文翻译"
        }
        
        要求：
        1. 识别图片中最显眼的物体
        2. 例句要贴合图片场景，自然地道
        3. 只返回 JSON，不要 markdown 代码块
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 1024
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // 解析响应
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        // 清理 JSON 字符串（移除可能的 markdown 代码块标记）
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 解析结果
        guard let resultData = cleanedText.data(using: .utf8) else {
            throw GeminiError.parseError
        }
        
        let result = try JSONDecoder().decode(RecognitionResult.self, from: resultData)
        return result
    }
}

// MARK: - 错误类型

enum GeminiError: LocalizedError {
    case apiKeyNotConfigured
    case imageProcessingFailed
    case networkError
    case apiError(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "请先配置 Gemini API Key"
        case .imageProcessingFailed:
            return "图片处理失败"
        case .networkError:
            return "网络请求失败"
        case .apiError(let message):
            return "API 错误: \(message)"
        case .parseError:
            return "解析响应失败"
        }
    }
}
