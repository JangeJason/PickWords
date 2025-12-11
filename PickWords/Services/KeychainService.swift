import Foundation
import Security

/// Keychain 安全存储服务
final class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.jangejason.PickWords"
    
    private init() {}
    
    // MARK: - API Key 存储
    
    private let geminiAPIKeyAccount = "gemini_api_key"
    
    /// 保存 Gemini API Key
    func saveGeminiAPIKey(_ apiKey: String) -> Bool {
        return save(key: geminiAPIKeyAccount, value: apiKey)
    }
    
    /// 获取 Gemini API Key
    func getGeminiAPIKey() -> String? {
        return get(key: geminiAPIKeyAccount)
    }
    
    /// 删除 Gemini API Key
    func deleteGeminiAPIKey() -> Bool {
        return delete(key: geminiAPIKeyAccount)
    }
    
    // MARK: - 通用 Keychain 操作
    
    private func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // 先删除旧值
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    @discardableResult
    private func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
