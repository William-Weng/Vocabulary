//
//  Utility.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import AVFoundation
import UIKit
import WWHUD

// MARK: - Utility (單例)
final class Utility: NSObject {
    
    enum HudGifType: String {
        
        case success = "Success.gif"
        case fail = "Fail.gif"
        case reading = "Reading.gif"
        case working = "Working.gif"
        case studing = "Studing.gif"
        case search = "Search.gif"
        case nice = "Nice.gif"
    }
    
    enum Music: String, CaseIterable {
        
        case 夏の霧 = "夏の霧.m4a"
        case TheBeatOfNature = "TheBeatOfNature.mp3"
        case 桜雲 = "桜雲.m4a"
        case 靜音 = ""
        
        /// 音樂檔案路徑
        /// - Returns: URL?
        func fileURL() -> URL? { return Bundle.main.url(forResource: self.rawValue, withExtension: nil) }
        
        /// 音樂檔案類型
        /// - Returns: AVFileType
        func fileType() -> AVFileType {
            
            guard let components = Optional.some(self.rawValue.components(separatedBy: ".")),
                  components.count > 1,
                  let extensionName = components.last
            else {
                return .mp3
            }
            
            if (extensionName.lowercased() == "mp3") { return .mp3 }
            if (extensionName.lowercased() == "m4a") { return .m4a }
            
            return .mp3
        }
    }
    
    static let shared = Utility()
    
    private static let synthesizer = AVSpeechSynthesizer._build()
    
    private override init() {}
}

// MARK: - Utility (class function)
extension Utility {
    
    /// [播放HUD](https://augmentedcode.io/2019/09/01/animating-gifs-and-apngs-with-cganimateimageaturlwithblock-in-swift/)
    /// - Parameter type: Utility.HudGifType
    func flashHUD(with type: Utility.HudGifType) {
        guard let gifUrl = Bundle.main.url(forResource: type.rawValue, withExtension: nil) else { return }
        WWHUD.shared.flash(effect: .gif(url: gifUrl, options: nil), height: 256.0, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil)
    }
    
    /// [讀出文字 / 文字發聲](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/讓開不了口的-app-開口說話-48c674f8f69e)
    /// - Parameters:
    ///   - string: 要讀出的文字
    ///   - voice: 使用的聲音語言
    ///   - rate: 語度 (0% ~ 100%)
    ///   - pitchMultiplier: 音調 (50% ~ 200%)
    ///   - volume: 音量 (0% ~ 100%)
    func speak(string: String, voice: Constant.VoiceCode = .english, rate: Float = 0.4, pitchMultiplier: Float = 1.5, volume: Float = 1.0) {
        Self.synthesizer._speak(string: string, voice: voice, rate: rate, pitchMultiplier: pitchMultiplier, volume: volume)
    }
}
