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
import WWAppInstallSource

/// WWPrint再包一層 => 容易切換顯不顯示
func myPrint<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
    wwPrint(message, file: file, method: method, line: line, isShow: Constant.isPrint)
}

// MARK: - Utility (單例)
final class Utility: NSObject {
    
    static let shared = Utility()
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    private let feedback = UIImpactFeedbackGenerator._build(style: .medium)
    private var synthesizer = AVSpeechSynthesizer._build()

    private override init() {}
}

// MARK: - AppDelegate (function)
extension Utility {
    
    /// 回復字典檔設定
    func initDictionarySettings() {
        SettingHelper.shared.initSettings()
        NotificationCenter.default._post(name: .refreshViewController)
    }
    
    /// 開始錄音
    func recordWave() {
        
        guard let appDelegate = appDelegate else { return }
        
        _ = appDelegate.recordWave()
        AssistiveTouchHelper.shared.hiddenAction(true)
    }
    
    /// 停止錄音
    func stopRecording() {
        
        guard let appDelegate = appDelegate else { return }
        
        _ = appDelegate.stopRecordingWave()
        AssistiveTouchHelper.shared.hiddenAction(false)
    }
    
    /// [強制改變裝置的方向](https://johnchihhonglin.medium.com/限制某個頁面的螢幕旋轉方向-8c7235d5a774)
    /// - Parameters:
    ///   - orientation: UIInterfaceOrientationMask
    ///   - rotateOrientation: UIInterfaceOrientation
    /// - Returns: Bool
    func screenOrientation(lock orientation: UIInterfaceOrientationMask, rotate rotateOrientation: UIInterfaceOrientation) -> Bool {
        
        guard let appDelegate = appDelegate else { return false }

        let isSuccess = appDelegate._orientation(lock: orientation, rotate: rotateOrientation)
        return isSuccess
    }
}

// MARK: - ShortcutItem
extension Utility {
    
    /// 產生版本號的ShortcutItem
    /// - Parameter application: UIApplication
    /// - Returns: UIApplicationShortcutItem
    func appVersionShortcutItem(with application: UIApplication) -> UIApplicationShortcutItem {
        
        let version = Bundle.main._appVersion()
        let installType = WWAppInstallSource.shared.detect() ?? .Simulator
        let info = UIDevice._systemInformation()
        let icon = UIApplicationShortcutIcon(type: .confirmation)
        let title = "v\(version.app) (\(version.build))"
        let subtitle = "\(info.name) \(info.version) by \(installType.rawValue)"
        let shortcutItem = UIApplicationShortcutItem._build(localizedTitle: title, localizedSubtitle: subtitle, icon: icon)
        
        return shortcutItem
    }
    
    /// 產生該上次使用時間的ShortcutItem
    /// - Parameter application: UIApplication
    /// - Returns: UIApplicationShortcutItem
    func appLaunchTimeShortcutItem(with application: UIApplication) -> UIApplicationShortcutItem {
        
        let icon = UIApplicationShortcutIcon(type: .time)
        let title = "上次使用時間"
        let subtitle = "\(Date()._localTime(timeZone: .current))"
        let shortcutItem = UIApplicationShortcutItem._build(localizedTitle: title, localizedSubtitle: subtitle, icon: icon)
        
        return shortcutItem
    }
}

// MARK: - AssistiveTouch
extension Utility {
    
    /// 顯示調整聲音畫面 (音量  / 語速)
    func adjustmentSoundType(_ soundType: VolumeViewController.AdjustmentSoundType) {
        
        guard let appDelegate = appDelegate,
              let target = appDelegate.window?.rootViewController
        else {
            return
        }
        
        AssistiveTouchHelper.shared.hiddenAction(true)
        presentVolumeViewController(target: target, soundType: soundType)
    }
    
    /// 彈出畫筆工作列
    func pencelToolPicker() {
        NotificationCenter.default._post(name: .displayCanvasView, object: nil)
    }
    
    /// 彈出錄音界面
    func recording() {
        
        guard let appDelegate = appDelegate,
              let target = appDelegate.window?.rootViewController
        else {
            return
        }
        
        _ = presentViewController(target: target, identifier: "TalkingViewController")
    }
    
    /// 分享(備份)Database
    /// - Parameter sender: UIBarButtonItem
    func shareDatabase() {
        
        guard let appDelegate = appDelegate,
              let target = appDelegate.window?.rootViewController,
              let fileURL = Constant.database?.fileURL
        else {
            return
        }
        
        let activityViewController = UIActivityViewController._build(activityItems: [fileURL], sourceView: target.view)
        
        AssistiveTouchHelper.shared.hiddenAction(true)
        target.present(activityViewController, animated: true)
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            AssistiveTouchHelper.shared.hiddenAction(false)
        }
    }
    
    /// 跟AI對話
    func chat() {
        
        guard let appDelegate = appDelegate,
              let target = appDelegate.window?.rootViewController,
              let viewController = UIStoryboard(name: "Sub", bundle: nil).instantiateViewController(withIdentifier: "TalkNavigationController") as? UINavigationController
        else {
            return
        }
        
        AssistiveTouchHelper.shared.hiddenAction(true)
        target.present(viewController, animated: true)
    }
    
    /// 下載備份的Database
    func downloadDatabase(delegate: (any UIDocumentPickerDelegate)?) {
        
        guard let appDelegate = appDelegate,
              let target = appDelegate.window?.rootViewController
        else {
            return
        }
        
        let documentPickerViewController = UIDocumentPickerViewController._build(delegate: delegate, allowedUTIs: [.item])
        
        AssistiveTouchHelper.shared.hiddenAction(true)
        target.present(documentPickerViewController, animated: true)
    }
    
    /// 下載資料庫的相關處理
    /// - Parameters:
    ///   - controller: UIDocumentPickerViewController
    ///   - urls: [URL]
    func downloadDocumentAction(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let appDelegate = appDelegate,
              let target = appDelegate.window?.rootViewController
        else {
            return
        }
        
        guard let databaseUrl = Constant.database?.fileURL,
              let fileUrl = urls.first,
              let backupUrl = Utility.shared.databaseBackupUrl()
        else {
            downloadDocumentHint(target: target, title: "備份路徑錯誤", message: nil); return
        }
        
        var result = FileManager.default._moveFile(at: databaseUrl, to: backupUrl)
        
        switch result {
        case .failure(let error): downloadDocumentHint(target: target, title: "錯誤", message: "\(error)")
        case .success(let isSuccess):
            
            if (!isSuccess) { downloadDocumentHint(target: target, title: "備份失敗", message: nil); return }
            
            result = FileManager.default._moveFile(at: fileUrl, to: databaseUrl)
            
            switch result {
            case .failure(let error): downloadDocumentHint(target: target, title: "錯誤", message: "\(error)")
            case .success(let isSuccess):
                
                if (!isSuccess) { downloadDocumentHint(target: target, title: nil, message: "更新失敗"); return }
                
                downloadDocumentHint(target: target, title: "備份 / 更新成功", message: "\(backupUrl.lastPathComponent)") {
                    SettingHelper.shared.initDatabase()
                    NotificationCenter.default._post(name: .refreshViewController)
                }
            }
        }
    }
    
    /// 下載資料庫檔案提示框
    /// - Parameters:
    ///   - target: UIViewController
    ///   - title: String?
    ///   - message: String?
    ///   - barButtonItem: UIBarButtonItem?
    ///   - action: (() -> Void)?
    func downloadDocumentHint(target: UIViewController, title: String?, message: String?, barButtonItem: UIBarButtonItem? = nil, action: (() -> Void)? = nil) {
        
        let alertController = UIAlertController._build(title: title, message: message)
        let action = UIAlertAction(title: "確認", style: .cancel) {  _ in action?() }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = barButtonItem
        
        target.present(alertController, animated: true)
    }
}

// MARK: - SettingsJSON設定檔相關
extension Utility {
    
    /// 解析完整的SettingsJSON的設定檔
    /// - Returns: [String: Any]?
    func parseSettingsDictionary(with filename: String) -> [String: Any]? {
        
        guard var jsonString = parseDefaultSettingsJSON(with: filename) else { return nil }
        if let _jsonString = parseUserSettingsJSON(with: filename) { jsonString = _jsonString }
        
        return jsonString._jsonObject() as? [String: Any]
    }
    
    /// 解析預設的SettingsJSON的設定檔
    /// - Parameter filename: String
    /// - Returns: String?
    func parseDefaultSettingsJSON(with filename: String) -> String? {
        
        guard let fileURL = Optional.some(Bundle.main.bundleURL.appendingPathComponent(filename)),
              let jsonString = FileManager.default._readText(from: fileURL)
        else {
            return nil
        }
        
        return jsonString
    }
    
    /// 解析使用者自訂的SettingsJSON的設定檔
    /// - Parameter filename: String
    /// - Returns: String?
    func parseUserSettingsJSON(with filename: String) -> String? {
        
        guard let url = FileManager.default._documentDirectory()?.appendingPathComponent(Constant.settingsJSON),
              let jsonString = FileManager.default._readText(from: url)
        else {
            return nil
        }
        
        return jsonString
    }
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
    func speak(string: String, code: String, rate: Float, pitchMultiplier: Float = 1.0, volume: Float = 1.0) {
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
    
    /// 彈出全畫面透明ViewController
    /// - Parameters:
    ///   - target: UIViewController?
    ///   - identifier: String
    /// - Returns: Bool
    func presentViewController(target: UIViewController?, identifier: String) -> Bool {
        
        guard let target = target,
              let viewController = target.storyboard?.instantiateViewController(identifier: identifier)
        else {
            return false
        }
        
        viewController._transparent(.black.withAlphaComponent(0.3))
        target.present(viewController, animated: false)
        
        return true
    }
    
    /// 顯示調節音量畫面
    /// - Parameters:
    ///   - target: UIViewController?
    ///   - soundType: VolumeViewController.AdjustmentSoundType
    func presentVolumeViewController(target: UIViewController?, soundType: VolumeViewController.AdjustmentSoundType) {
        
        guard let target = target,
              let viewController = UIStoryboard(name: "Sub", bundle: nil).instantiateViewController(withIdentifier: "VolumeViewController") as? VolumeViewController
        else {
            return
        }
        
        viewController.soundType = soundType
        viewController._transparent(.black.withAlphaComponent(0.3))
        target.present(viewController, animated: true)
    }
}

// MARK: - UI相關 (function)
extension Utility {
    
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
    func favoriteIcon(_ isFavorite: Bool) -> UIImage { return (!isFavorite) ? .noticeOff : .noticeOn }
    
    /// 音量ICON
    /// - Parameter isFavorite: Bool
    /// - Returns: UIImage
    func volumeIcon(_ isSuccess: Bool) -> UIImage { return (!isSuccess) ? .noVolume : .volume }
    
    /// 單字翻譯難度ICON
    /// - Parameter isHardWork: Bool
    /// - Returns: UIImage
    func hardWorkIcon(_ isHardWork: Bool) -> UIImage { return (!isHardWork) ? .hardWorkOff : .hardWorkOn }
    
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
    
    /// [設定TabBar顯示與否功能](https://www.jianshu.com/p/4c94fc74f1e6)
    /// - Parameters:
    ///   - isHidden: Bool
    func tabBarHidden(with tabBarController: UITabBarController?, isHidden: Bool) {
        
        guard let tabBarController = tabBarController else { return }
        
        MyTabBarController.isHidden = isHidden
        tabBarController._tabBarHidden(isHidden)
        NotificationCenter.default._post(name: .viewDidTransition, object: isHidden)
    }
    
    /// 取得外部資料夾圖片 (/Image/<image>)
    /// - Parameter name: String
    /// - Returns: UIImage?
    func folderImage(name: String) -> UIImage? {
        
        guard let imageUrl = Constant.FileFolder.images.url()?._appendPath(name),
              let image = UIImage(contentsOfFile: imageUrl.path)
        else {
            return nil
        }
        
        return image
    }
}

// MARK: - 音樂相關 (function)
extension Utility {
    
    /// 要播放的Music列表
    /// - Parameter type: Constant.MusicLoopType
    /// - Returns: [Music]
    func musicList(for type: Constant.MusicLoopType) -> [Music] {
        
        switch type {
        case .stop: return []
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
