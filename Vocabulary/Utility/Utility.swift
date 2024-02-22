//
//  Utility.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import AVFoundation
import UIKit
import WWPrint
import WWHUD
import WWFloatingViewController

/// WWPrint再包一層 => 容易切換顯不顯示
func myPrint<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
    wwPrint(message, file: file, method: method, line: line, isShow: Constant.isPrint)
}

// MARK: - Utility (單例)
final class Utility: NSObject {
    
    static let shared = Utility()
    
    private let feedback = UIImpactFeedbackGenerator._build(style: .medium)
    private var synthesizer = AVSpeechSynthesizer._build()

    private override init() {}
}

// MARK: - 資料庫相關 (function)
extension Utility {
    
    /// 切換字典檔
    /// - Parameter info: Settings.GeneralInformation
    func changeDictionary(with info: Settings.GeneralInformation) {
                
        Constant.tableName = info.key
        Constant.tableNameIndex = tableNameIndex(info.key)
        
        initDictionarySettings()
    }
    
    /// 回復字典檔設定
    func initDictionarySettings() {
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        delegate.initSettings()
        NotificationCenter.default._post(name: .refreshViewController)
    }
    
    /// 搜尋字典檔的index
    /// - Parameters:
    ///   - tableName: String
    ///   - `default`: Int
    /// - Returns: Int
    func tableNameIndex(_ tableName: String?, `default`: Int = 0) -> Int {
        
        guard let tableName = tableName,
              let index = Constant.SettingsJSON.generalInformations.first(where: { $0.key.capitalized == tableName.capitalized })?.value
        else {
            return `default`
        }
        
        return index
    }
    
    /// 資料庫備份路徑
    /// - Parameter dateFormat: "yyyy-MM-dd HH:mm:ss ZZZ"
    /// - Returns: URL?
    func databaseBackupUrl(_ dateFormat: String = "yyyy-MM-dd HH:mm:ss ZZZ") -> URL? {
        let url = Constant.backupDirectory?._appendPath("\(Date()._localTime(dateFormat: dateFormat, timeZone: .current)).\(Constant.databaseFileExtension)")
        return url
    }
}

// MARK: - 提示相關 (function)
extension Utility {
    
    /// [顯示HUD](https://augmentedcode.io/2019/09/01/animating-gifs-and-apngs-with-cganimateimageaturlwithblock-in-swift/)
    /// - Parameter type: [Constant.AnimationGifType](https://www.swiftjectivec.com/animating-images-using-image-io/)
    func flashHUD(with type: Constant.AnimationGifType) {
        
        guard let gifUrl = type.fileURL(with: .animation),
              FileManager.default._fileExists(with: gifUrl).isExist
        else {
            WWHUD.shared.flash(effect: .default, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil); return
        }
        
        let options = [kCGImageAnimationStartIndex: 0] as? CFDictionary
        WWHUD.shared.flash(effect: .gif(url: gifUrl, options: options), height: 256.0, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil)
    }
    
    /// 播放HUD
    /// - Parameter type: Constant.AnimationGifType
    func diplayHUD(with type: Constant.AnimationGifType) {
        
        guard let gifUrl = type.fileURL(with: .animation),
              FileManager.default._fileExists(with: gifUrl).isExist
        else {
            WWHUD.shared.flash(effect: .default, backgroundColor: .black.withAlphaComponent(0.3), animation: 0.75, completion: nil); return
        }
        
        WWHUD.shared.display(effect: .gif(url: gifUrl, options: nil), height: 256.0, backgroundColor: .black.withAlphaComponent(0.3))
    }
    
    /// 停止HUD
    func dismissHUD() {
        WWHUD.shared.dismiss(completion: nil)
    }
    
    /// WWToast的顏色 / 高度設定
    /// - Parameter viewController: UIViewController?
    /// - Returns: (backgroundColor: UIColor, height: CGFloat)
    func toastSetting(for viewController: UIViewController?) -> (backgroundColor: UIColor, height: CGFloat) {
                
        let setting: (backgroundColor: UIColor, height: CGFloat) = (#colorLiteral(red: 0, green: 0.5690457821, blue: 0.5746168494, alpha: 1), viewController?.navigationController?._navigationBarHeight(for: UIWindow._keyWindow(hasScene: false)) ?? .zero)
        
        return setting
    }
    
    /// 產生WWFloatingViewController
    /// - Parameters:
    ///   - target: UIViewController & WWFloatingViewDelegate
    ///   - currentView: UIView?
    func presentSearchVocabularyViewController(target: UIViewController & WWFloatingViewDelegate, currentView: UIView?) {
        
        let floatingViewController = WWFloatingView.shared.maker()
        floatingViewController.configure(animationDuration: Constant.delay, backgroundColor: .black.withAlphaComponent(0.1), multiplier: 0.8, completePercent: 0.5, currentView: currentView)
        floatingViewController.myDelegate = target
        
        target.present(floatingViewController, animated: false)
    }
}

// MARK: - 發音相關 (function)
extension Utility {
    
    /// [讀出文字 / 文字發聲](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/讓開不了口的-app-開口說話-48c674f8f69e)
    /// - Parameters:
    ///   - string: 要讀出的文字
    ///   - code: 使用的聲音語言
    ///   - rate: 語速 (0% ~ 100%)
    ///   - pitchMultiplier: 音調 (50% ~ 200%)
    ///   - volume: 音量 (0% ~ 100%)
    ///   - boundary: 停止發聲 (單字 / 立刻停止)
    func speak(string: String, code: String, rate: Float = 0.4, pitchMultiplier: Float = 1.0, volume: Float = 1.0) {
        pauseSpeaking(at: .immediate)
        synthesizer._speak(string: string, code: code, rate: rate, pitchMultiplier: pitchMultiplier, volume: volume)
    }
    
    /// 停止發聲
    /// - Parameters:
    ///   - boundary: 停止發聲 (單字 / 立刻停止)
    func pauseSpeaking(at boundary: AVSpeechBoundary) {
        synthesizer.pauseSpeaking(at: .word)
        synthesizer = AVSpeechSynthesizer._build()
    }
    
    /// 震動功能
    func impactEffect() { feedback._impact() }
    
    /// 判斷是不是Web的網址 (http:// || https://)
    /// - Parameter urlString: String
    /// - Returns: Bool
    func isWebUrlString(_ urlString: String) -> Bool {
        return urlString.hasPrefix("http://") || urlString.hasPrefix("https://")
    }
}

// MARK: - UI相關 (function)
extension Utility {
    
    /// [強制改變裝置的方向](https://johnchihhonglin.medium.com/限制某個頁面的螢幕旋轉方向-8c7235d5a774)
    /// - Parameters:
    ///   - orientation: UIInterfaceOrientationMask
    ///   - rotateOrientation: UIInterfaceOrientation
    /// - Returns: Bool
    func screenOrientation(lock orientation: UIInterfaceOrientationMask, rotate rotateOrientation: UIInterfaceOrientation) -> Bool {
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return false }

        let isSuccess = delegate._orientation(lock: orientation, rotate: rotateOrientation)
        return isSuccess
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
    ///   - gap: CGFloat
    func titleViewSetting(with titleView: UILabel, title: String, count: Int, gap: CGFloat = 16.0) {
        
        let title = "\(title) - \(count)"
        titleViewSetting(titleView, title: title, gap: gap)
    }
    
    /// 設定UILabel標題 for 單字複習
    /// - Parameters:
    ///   - titleView: UILabel
    ///   - title: String
    ///   - count: Int
    ///   - searchWordCount: Int
    ///   - gap: CGFloat
    func titleViewSetting(with titleView: UILabel, title: String, count: Int, searchWordCount: Int, gap: CGFloat = 16.0) {
        
        let title = "\(title) - \(count) / \(searchWordCount)"
        titleViewSetting(titleView, title: title, gap: gap)
    }
    
    /// 設定UILabel標題 for 單字複習
    /// - Parameters:
    ///   - titleView: UILabel
    ///   - title: String
    ///   - gap: CGFloat
    func titleViewSetting(_ titleView: UILabel, title: String, gap: CGFloat = 16.0) {
        
        titleView.sizeToFit()
        titleView.textAlignment = .center
        titleView.frame = CGRect(origin: titleView.frame.origin, size: CGSize(width: titleView.frame.width + gap, height: titleView.frame.height + gap))
        titleView.text = title
    }
    
    /// 我的最愛ICON
    /// - Parameter isFavorite: Bool
    /// - Returns: UIImage
    func favoriteIcon(_ isFavorite: Bool) -> UIImage { return (!isFavorite) ? #imageLiteral(resourceName: "Notice_Off") : #imageLiteral(resourceName: "Notice_On") }
    
    /// 音量ICON
    /// - Parameter isFavorite: Bool
    /// - Returns: UIImage
    func volumeIcon(_ isSuccess: Bool) -> UIImage { return (!isSuccess) ? #imageLiteral(resourceName: "NoVolume") : #imageLiteral(resourceName: "Volume") }
    
    /// 單字翻譯難度ICON
    /// - Parameter isHardWork: Bool
    /// - Returns: UIImage
    func hardWorkIcon(_ isHardWork: Bool) -> UIImage { return (!isHardWork) ? #imageLiteral(resourceName: "HardWork_Off") : #imageLiteral(resourceName: "HardWork_On") }
    
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
    
    /// 字型
    /// - Returns: UIFont?
    /// - Parameters:
    ///   - name: 字型名稱
    ///   - fontSize: CGFloat
    func font(name: String, size: CGFloat = 36.0) -> UIFont? {
        return UIFont(name: name, size: size)
    }
}

// MARK: - 音樂相關 (function)
extension Utility {
    
    /// 要播放的Music列表
    /// - Parameter type: Constant.MusicLoopType
    /// - Returns: [Music]
    func musicList(for type: Constant.MusicLoopType) -> [Music] {
        
        switch type {
        case .mute: return []
        case .infinity: return []
        case .loop: return loopMusics()
        case .shuffle: return shuffleMusics()
        }
    }
    
    /// [隨機播放的Music列表](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/swift-4-2-更方便的亂數-random-function-85fa69a08215)
    /// - Returns: Music?
    func shuffleMusics() -> [Music] {
        guard let filenames = Constant.musicFileList?.shuffled() else { return [] }
        return filenames.map { Music(filename:$0) }
    }
    
    /// 循序播放的Music列表
    /// - Returns: [Music]
    func loopMusics() -> [Music] {
        guard let filenames = Constant.musicFileList?.sorted() else { return [] }
        return filenames.map { Music(filename:$0) }
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
    ///   - info: Settings.GeneralInformation
    ///   - offset: Int
    /// - Returns: [[String : Any]]
    func vocabularyListArrayMaker(like text: String, searchType: Constant.SearchType, info: Settings.GeneralInformation, offset: Int) -> [[String : Any]] {
        
        let dictionary: [[String : Any]]
        
        switch searchType {
        case .word, .alphabet:
            dictionary = API.shared.searchList(like: text, searchType: searchType, info: info, offset: offset)
        
        case .interpret:
            
            let array = API.shared.searchList(like: text, searchType: searchType, info: info, count: nil, offset: 0)
            let words = array.compactMap { $0._jsonClass(for: Vocabulary.self)?.word }
            
            dictionary = API.shared.searchWordListDetail(in: words, info: info, offset: offset)
        }
        
        return dictionary
    }
}

// MARK: - MainTableViewCell
extension Utility {
    
    /// 更新暫存的單字列表資訊
    /// - Parameters:
    ///   - info: Settings.VocabularyLevelInformation
    ///   - indexPath: IndexPath
    func updateLevelDictionary(_ info: Settings.VocabularyLevelInformation, with indexPath: IndexPath) {
        
        guard var dictionary = MainTableViewCell.vocabularyListArray[safe: indexPath.row] else { return }
        
        dictionary["level"] = info.value
        MainTableViewCell.vocabularyListArray[indexPath.row] = dictionary
    }
    
    /// 更新暫存的我的最愛資訊
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavoriteDictionary(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard var dictionary = MainTableViewCell.vocabularyListArray[safe: indexPath.row] else { return }
        
        let favorite = isFavorite._int()
        dictionary["favorite"] = favorite
        
        MainTableViewCell.vocabularyListArray[indexPath.row] = dictionary
    }
    
    /// levelButton文字顏色設定
    /// - Parameters:
    ///   - button: UIButton
    ///   - info: Settings.VocabularyLevelInformation?
    func levelButtonSetting(_ button: UIButton, with info: Settings.VocabularyLevelInformation?) {
        
        button.setTitle(info?.name ?? "一般", for: .normal)
        button.setTitleColor(UIColor(rgb: info?.color ?? "#ffffff"), for: .normal)
        button.backgroundColor = UIColor(rgb: info?.backgroundColor ?? "#000000")
    }
}

// MARK: - Settings.json
extension Utility {
    
    /// 取得字典外語設定字型 (有預設值)
    /// - Parameters:
    ///   - index: Int
    ///   - size: CGFloat
    ///   - default: UIFont
    /// - Returns: UIFont
    func dictionaryFont(with index: Int, size: CGFloat) -> UIFont {
        
        guard let settings = Utility.shared.generalSettings(index: index),
              let font = UIFont(name: settings.font, size: size)
        else {
            return UIFont.systemFont(ofSize: size)
        }
        
        return font
    }
    
    /// 單字記憶頁的Title
    /// - Parameter index: Int
    /// - Returns: String?
    func mainViewContrillerTitle(with index: Int, `default`: String) -> String {
        
        guard let settings = Utility.shared.generalSettings(index: index) else { return `default` }
        return settings.name
    }
    
    /// 取得基本設定 (Settings.json)
    /// - Parameter index: Int
    /// - Returns: Settings.GeneralInformation?
    func generalSettings(index: Int) -> Settings.GeneralInformation? {
        return Constant.SettingsJSON.generalInformations[safe: index]
    }
}
