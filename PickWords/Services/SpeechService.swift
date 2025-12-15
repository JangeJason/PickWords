import AVFoundation

/// 单词发音服务
final class SpeechService: ObservableObject {
    static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    private init() {}
    
    /// 朗读英文单词
    func speak(_ text: String, language: String = "en-US") {
        // 如果正在朗读，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9 // 稍慢一点更清晰
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    /// 停止朗读
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
