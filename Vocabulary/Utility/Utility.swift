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
        case review = "Review.gif"
        case nice = "Nice.gif"
        case speak = "Speak.gif"
        case shudder = "Shudder.gif"
        case solution = "Solution.gif"
        case sentence = "Sentence.gif"
        case others = "Others.gif"
        case download = "Download.gif"
        
        /// 檔案路徑
        /// - Returns: URL?
        func fileURL() -> URL? {
            let backgroundFolderUrl = Constant.animationFolderUrl
            return backgroundFolderUrl?._appendPath(self.rawValue)
        }
    }
    
    static let shared = Utility()
    
    private static let synthesizer = AVSpeechSynthesizer._build()
    
    private override init() {}
}

// MARK: - Utility (class function)
extension Utility {
    
    /// [顯示HUD](https://augmentedcode.io/2019/09/01/animating-gifs-and-apngs-with-cganimateimageaturlwithblock-in-swift/)
    /// - Parameter type: Utility.HudGifType
    func flashHUD(with type: Utility.HudGifType) {
        
        guard let gifUrl = type.fileURL(),
              FileManager.default._fileExists(with: gifUrl).isExist
        else {
            WWHUD.shared.flash(effect: .default, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil); return
        }
        
        WWHUD.shared.flash(effect: .gif(url: gifUrl, options: nil), height: 256.0, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil)
    }
    
    /// [播放HUD](https://augmentedcode.io/2019/09/01/animating-gifs-and-apngs-with-cganimateimageaturlwithblock-in-swift/)
    func diplayHUD(with type: Utility.HudGifType) {

        guard let gifUrl = type.fileURL(),
              FileManager.default._fileExists(with: gifUrl).isExist
        else {
            WWHUD.shared.flash(effect: .default, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil); return
        }
        
        WWHUD.shared.display(effect: .gif(url: gifUrl, options: nil), height: 256.0, backgroundColor: .black.withAlphaComponent(0.3))
    }
    
    /// [讀出文字 / 文字發聲](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/讓開不了口的-app-開口說話-48c674f8f69e)
    /// - Parameters:
    ///   - string: 要讀出的文字
    ///   - voice: 使用的聲音語言
    ///   - rate: 語速 (0% ~ 100%)
    ///   - pitchMultiplier: 音調 (50% ~ 200%)
    ///   - volume: 音量 (0% ~ 100%)
    func speak(string: String, voice: Constant.VoiceCode = .english, rate: Float = 0.4, pitchMultiplier: Float = 1.5, volume: Float = 1.0) {
        Self.synthesizer._speak(string: string, voice: voice, rate: rate, pitchMultiplier: pitchMultiplier, volume: volume)
    }
    
    /// 判斷是不是Web的網址 (http:// || https://)
    /// - Parameter urlString: String
    /// - Returns: Bool
    func isWebUrlString(_ urlString: String) -> Bool {
        return urlString.hasPrefix("http://") || urlString.hasPrefix("https://")
    }
}

// MARK: - 選單
extension Utility {
    
    /// 單字等級選單
    /// - Parameters:
    ///   - target: UIViewController
    ///   - vocabularyList: VocabularyList?
    ///   - popoverItem: UIBarButtonItem?
    func levelMenu(target: UIViewController, vocabularyList: VocabularyList?, popoverItem: UIBarButtonItem? = nil) {
        
        guard let vocabularyList = vocabularyList else { return }
        
        let alertController = UIAlertController(title: "請選擇等級", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        Vocabulary.Level.allCases.forEach { level in
            
            let action = UIAlertAction(title: level.value(), style: .default) { _ in
                let isSuccess = API.shared.updateLevelToList(vocabularyList.id, level: level, for: Constant.currentTableName)
                if (!isSuccess) { Utility.shared.flashHUD(with: .fail) }
            }
            
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = popoverItem
        
        target.present(alertController, animated: true, completion: nil)
    }
}
