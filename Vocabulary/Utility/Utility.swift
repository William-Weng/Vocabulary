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
    
    static let shared = Utility()
    
    private let synthesizer = AVSpeechSynthesizer._build()
    
    private override init() {}
}

// MARK: - Utility (class function)
extension Utility {
    
    /// [顯示HUD](https://augmentedcode.io/2019/09/01/animating-gifs-and-apngs-with-cganimateimageaturlwithblock-in-swift/)
    /// - Parameter type: [Utility.HudGifType](https://www.swiftjectivec.com/animating-images-using-image-io/)
    func flashHUD(with type: Constant.HudGifType) {
        
        guard let gifUrl = type.fileURL(),
              FileManager.default._fileExists(with: gifUrl).isExist
        else {
            WWHUD.shared.flash(effect: .default, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil); return
        }
        
        let options = [kCGImageAnimationStartIndex: 0] as? CFDictionary
        WWHUD.shared.flash(effect: .gif(url: gifUrl, options: options), height: 256.0, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil)
    }
    
    /// [播放HUD](https://augmentedcode.io/2019/09/01/animating-gifs-and-apngs-with-cganimateimageaturlwithblock-in-swift/)
    func diplayHUD(with type: Constant.HudGifType) {

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
        self.synthesizer._speak(string: string, voice: voice, rate: rate, pitchMultiplier: pitchMultiplier, volume: volume)
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
    
    /// 取得被點到的Cell with CellReusable
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: T?
    func didSelectedCell<T: CellReusable>(_ tableView: UITableView, with indexPath: IndexPath) -> T? {
        
        var cell: T?
        
        tableView.visibleCells.forEach { visibleCell in
            guard let visibleCell = visibleCell as? T else { return }
            if (visibleCell.indexPath == indexPath) { cell = visibleCell }
        }
        
        return cell
    }
    
    /// 產生NavigationItem標題的LabelView
    /// - Parameters:
    ///   - text: 標題文字
    ///   - textColor: 文字顏色
    ///   - font: 文字字型
    /// - Returns: UILabel
    func titleLabelMaker(with text: String?, textColor: UIColor = .label, font: UIFont = .systemFont(ofSize: 17.0, weight: .semibold)) -> UILabel {
        
        let label = UILabel()
        
        label.text = text
        label.font = font
        label.textColor = textColor
        
        return label
    }
}
