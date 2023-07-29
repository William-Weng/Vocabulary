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

// MARK: - Utility (function)
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
    
    /// 計算下滑到底更新的距離百分比 for 快速搜尋單字小幫手 (UIRefreshControl的另一邊)
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - tableView: UITableView
    /// - Returns: CGFloat
    func updateSearchHeightPercent(with scrollView: UIScrollView) -> CGFloat {
        
        var percent = (scrollView.contentOffset.y + scrollView.bounds.height - scrollView.contentSize.height) / Constant.updateSearchScrolledHeight
        
        if (scrollView.frame.height > scrollView.contentSize.height) {
            percent = scrollView.contentOffset.y / Constant.updateSearchScrolledHeight
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
        let gap = 16.0
        
        titleView.sizeToFit()
        titleView.textAlignment = .center
        titleView.frame = CGRect(origin: titleView.frame.origin, size: CGSize(width: titleView.frame.width + gap, height: titleView.frame.height + gap))
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
    
    /// 下滑到底更新的顯示Title
    /// - Parameters:
    ///   - percent: CGFloat
    ///   - isNeededUpdate: Bool
    /// - Returns: String
    func updateActivityViewIndicatorTitle(with percent: CGFloat, isNeededUpdate: Bool) -> String {
        
        if (!isNeededUpdate) { return Constant.noDataUpdate }
        
        var _percent = percent
        if (percent > 1.0) { _percent = 1.0 }
        
        let title = String(format: "%.2f", _percent * 100)
        return "\(title) %"
    }
    
    /// 更新下滑更新的高度基準值
    /// - Parameter percent: KeyWindow高度的25%
    func updateScrolledHeightSetting(percent: CGFloat = 0.25) {
        guard let keyWindow = UIWindow._keyWindow(hasScene: false) else { return }
        Constant.updateScrolledHeight = keyWindow.frame.height * percent
    }
    
    /// 資料庫備份路徑
    /// - Parameter dateFormat: "yyyy-MM-dd HH:mm:ss ZZZ"
    /// - Returns: URL?
    func databaseBackupUrl(_ dateFormat: String = "yyyy-MM-dd HH:mm:ss ZZZ") -> URL? {
        let url = Constant.backupDirectory?._appendPath("\(Date()._localTime(dateFormat: dateFormat, timeZone: .current)).\(Constant.databaseFileExtension)")
        return url
    }
}

// MARK: - SearchWordViewController / SearchVocabularyViewController
extension Utility {
    
    /// 設定搜尋的類型按鈕 => 單字 / 字義
    /// - Parameters:
    ///   - title: String
    ///   - backgroundColor: UIColor
    /// - Returns: UIButton
    func searchTypeButtonMaker(with type: Constant.SearchType, backgroundColor: UIColor) -> UIButton {
        
        let button = UIButton()
        
        button.backgroundColor = type.backgroundColor()
        button.setTitle("  \(type)  ", for: .normal)
        button.layer._maskedCorners(radius: 8.0)
        
        return button
    }
    
    /// 切換搜尋類型的相關動作
    /// - Parameters:
    ///   - searchBar: UISearchBar
    ///   - searchType: Constant.SearchType
    func switchSearchTypeAction(_ searchBar: UISearchBar, for searchType: Constant.SearchType) {
        
        guard let leftButton = searchBar.searchTextField.leftView as? UIButton else { return }
        
        leftButton.setTitle("  \(searchType)  ", for: .normal)
        leftButton.backgroundColor = searchType.backgroundColor()
        searchBar.placeholder = "請輸入需要搜尋的\(searchType)"
    }
    
    /// 取得單字列表 for 分類
    /// - Parameters:
    ///   - text: String
    ///   - searchType: Constant.SearchType
    ///   - tableName: Constant.VoiceCode
    ///   - offset: Int
    /// - Returns: [[String : Any]]
    func vocabularyListArrayMaker(like text: String, searchType: Constant.SearchType, for tableName: Constant.VoiceCode, offset: Int) -> [[String : Any]] {
        
        let dictionary: [[String : Any]]
        
        switch searchType {
        case .word:
            dictionary = API.shared.searchList(like: text, searchType: searchType, for: Constant.currentTableName, offset: offset)
            
        case .interpret:
            
            let array = API.shared.searchList(like: text, searchType: searchType, for: Constant.currentTableName, count: nil, offset: 0)
            let words = array.compactMap { $0._jsonClass(for: Vocabulary.self)?.word }
            
            dictionary = API.shared.searchWordListDetail(in: words, for: Constant.currentTableName, offset: offset)
        }
        
        return dictionary
    }
}
