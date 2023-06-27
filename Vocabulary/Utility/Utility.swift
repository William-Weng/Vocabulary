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
    private let feedback = UIImpactFeedbackGenerator._build(style: .medium)

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
    
    /// 震動功能
    func impactEffect() { feedback._impact() }
    
    /// 判斷是不是Web的網址 (http:// || https://)
    /// - Parameter urlString: String
    /// - Returns: Bool
    func isWebUrlString(_ urlString: String) -> Bool {
        return urlString.hasPrefix("http://") || urlString.hasPrefix("https://")
    }
    
    /// 計算下滑到底更新的距離百分比 (UIRefreshControl的另一邊)
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - navigationController: UINavigationController?
    /// - Returns: CGFloat
    func updateHeightPercent(with scrollView: UIScrollView, navigationController: UINavigationController?) -> CGFloat {
        
        let navigationBarHeight = navigationController?._navigationBarHeight(for: UIWindow._keyWindow(hasScene: false)) ?? .zero
        let offset = scrollView.frame.height + scrollView.contentOffset.y - scrollView.contentSize.height
        var percent = 1.0 - (Constant.updateScrolledHeight - offset) / (Constant.updateScrolledHeight - navigationBarHeight)
        
        if (scrollView.frame.height > (scrollView.contentSize.height + navigationBarHeight)) {
            percent = (scrollView.contentOffset.y + navigationBarHeight) / (Constant.updateScrolledHeight - navigationBarHeight)
        }
        
        return percent
    }
    
    /// 設定UILabel標題
    /// - Parameters:
    ///   - titleView: UILabel
    ///   - title: String
    ///   - count: Int
    func titleViewSetting(with titleView: UILabel, title: String, count: Int) {
        
        let title = "\(title) - \(count)"
        
        titleView.sizeToFit()
        titleView.textAlignment = .center
        titleView.frame = CGRect(origin: titleView.frame.origin, size: CGSize(width: titleView.frame.width + 10, height: titleView.frame.height + 10))
        titleView.text = title
    }
    
    /// 我的最愛ICON
    /// - Parameter isFavorite: Bool
    /// - Returns: UIImage
    func favoriteIcon(_ isFavorite: Bool) -> UIImage {
        return (!isFavorite) ? UIImage(imageLiteralResourceName: "Notice_Off") : UIImage(imageLiteralResourceName: "Notice_On")
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
