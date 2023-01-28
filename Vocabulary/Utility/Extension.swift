//
//  Extension.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import AVKit
import SafariServices

// MARK: - Collection (override class function)
extension Collection {

    /// [為Array加上安全取值特性 => nil](https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings)
    subscript(safe index: Index) -> Element? { return indices.contains(index) ? self[index] : nil }
}

// MARK: - Dictionary (class function)
extension Dictionary {
    
    /// Dictionary => JSON Data
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Returns: Data?
    func _jsonData(options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        return JSONSerialization._data(with: self, options: options)
    }
    
    /// Dictionary => JSON Data => T
    /// - Parameter type: 要轉換成的Dictionary類型
    /// - Returns: T?
    func _jsonClass<T: Decodable>(for type: T.Type) -> T? {
        let dictionary = self._jsonData()?._class(type: type.self)
        return dictionary
    }
}

// MARK: - String (class function)
extension String {

    /// [國家地區代碼](https://zh.wikipedia.org/wiki/國家地區代碼)
    /// - [顏文字：AA => 🇦🇦 / TW => 🇹🇼](https://lets-emoji.com/)
    /// - Returns: String
    func _flagEmoji() -> String {
        
        let characterA: (ascii: String, unicode: UInt32, error: String) = ("A", 0x1F1E6, "？")
        var unicodeString = ""
        
        for scalar in unicodeScalars {
            
            guard let asciiA = characterA.ascii.unicodeScalars.first,
                  let unicodeWord = UnicodeScalar(characterA.unicode + scalar.value - asciiA.value)
            else {
                unicodeString += characterA.error.description; continue
            }
            
            let wordRange = Int(unicodeWord.value) - Int(characterA.unicode) + 1
            
            switch wordRange {
            case 1...26: unicodeString += "\(unicodeWord)"
            default: unicodeString += characterA.error
            }
        }
        
        return unicodeString
    }
    
    /// URL編碼 (百分比)
    /// - 是在哈囉 => %E6%98%AF%E5%9C%A8%E5%93%88%E5%9B%89
    /// - Parameter characterSet: 字元的判斷方式
    /// - Returns: String?
    func _encodingURL(characterSet: CharacterSet = .urlQueryAllowed) -> String? { return addingPercentEncoding(withAllowedCharacters: characterSet) }
}

// MARK: - Data (class function)
extension Data {
    
    /// Data => Class
    /// - Parameter type: 要轉型的Type => 符合Decodable
    /// - Returns: T => 泛型
    func _class<T: Decodable>(type: T.Type) -> T? {
        
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "UTC")

        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return try? decoder.decode(type.self, from: self)
    }
}

// MARK: - Date (class function)
extension Date {
    
    /// 將UTC時間 => 該時區的時間
    /// - 2020-07-07 16:08:50 +0800
    /// - Parameters:
    ///   - dateFormat: 時間格式
    ///   - identifier: 區域辨識
    /// - Returns: String?
    func _localTime(with dateFormat: String = "yyyy-MM-dd HH:mm:ss", timeZone identifier: String = "UTC") -> String {
        
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "\(dateFormat)"
        dateFormatter.timeZone = TimeZone(identifier: identifier)
        
        return dateFormatter.string(from: self)
    }
}

// MARK: - URL (static function)
extension URL {
    
    /// 將URL標準化 (百分比)
    /// - 是在哈囉 => %E6%98%AF%E5%9C%A8%E5%93%88%E5%9B%89
    /// - Parameters:
    ///   - string: url字串
    ///   - characterSet: 字元的判斷方式
    /// - Returns: URL?
    static func _standardization(string: String, characterSet: CharacterSet = .urlQueryAllowed) -> URL? {
        
        var url: URL?
        url = URL(string: string)
        
        guard url == nil,
              let encodeString = string._encodingURL(characterSet: characterSet)
        else {
            return url
        }
        
        return URL(string: encodeString)
    }
}

// MARK: - JSONSerialization (static function)
extension JSONSerialization {
    
    /// [JSONObject => JSON Data](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-jsonserialization-印出美美縮排的-json-308c93b51643)
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Parameters:
    ///   - object: Any
    ///   - options: JSONSerialization.WritingOptions
    /// - Returns: Data?
    static func _data(with object: Any, options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: options)
        else {
            return nil
        }
        
        return data
    }
}

// MARK: - AVSpeechSynthesizer (static function)
extension AVSpeechSynthesizer {
    
    /// 產生AVSpeechSynthesizer
    /// - Parameter delegate: AVSpeechSynthesizerDelegate
    static func _build(delegate: AVSpeechSynthesizerDelegate? = nil) -> AVSpeechSynthesizer {
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = delegate
        
        return synthesizer
    }
}

// MARK: - AVSpeechSynthesizer (class function)
extension AVSpeechSynthesizer {
    
    /// [讀出文字 / 文字發聲](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/讓開不了口的-app-開口說話-48c674f8f69e)
    /// - Parameters:
    ///   - string: 要讀出的文字
    ///   - voice: 使用的聲音語言
    ///   - rate: 語度 (0% ~ 100%)
    ///   - pitchMultiplier: 音調 (50% ~ 200%)
    ///   - volume: 音量 (0% ~ 100%)
    func _speak(string: String, voice: Constant.VoiceCode = .english, rate: Float = 0.5, pitchMultiplier: Float = 1.5, volume: Float = 0.5) {
        
        let utterance = AVSpeechUtterance._build(string: string, voice: voice)
        utterance.rate = rate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.volume = volume

        self.speak(utterance)
    }
}

// MARK: - AVSpeechUtterance (static function)
extension AVSpeechUtterance {
    
    /// 產生AVSpeechUtterance
    /// - Parameters:
    ///   - string: 要讀的文字
    ///   - voice: 使用的聲音語言
    /// - Returns: AVSpeechUtterance
    static func _build(string: String, voice: Constant.VoiceCode = .english) -> AVSpeechUtterance {

        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: voice.code())

        return utterance
    }
}

// MARK: - AVAudioPlayer (static function)
extension AVAudioPlayer {
    
    /// [產生AVAudioPlayer](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-avplayer-播放-app-裡的-mp3-檔-20c4633c4a03)
    /// - Parameters:
    ///   - audioURL: 音樂檔的路徑
    ///   - fileTypeHint: [音樂檔類型 => .mp3](https://tw.allsaintsetna.org/118500-how-to-play-a-sound-HZPJUV)
    /// - Returns: AVAudioPlayer?
    static func _build(audioURL: URL, fileTypeHint: AVFileType = .mp3, delegate: AVAudioPlayerDelegate? = nil) -> AVAudioPlayer? {
        
        let audioPlayer = try? AVAudioPlayer(contentsOf: audioURL, fileTypeHint: fileTypeHint.rawValue)
        audioPlayer?.delegate = delegate
        
        return audioPlayer
    }
}

// MARK: - URL (class function)
extension URL {
    
    /// 在APP內部開啟URL (SafariViewController) => window.webkit.messageHandlers.LinkUrl.postMessage("https://www.google.com")
    /// - Parameter urlString: URL網址
    func _openUrlWithInside(delegate: (UIViewController & SFSafariViewControllerDelegate)) -> SFSafariViewController {
        
        let safariViewController = SFSafariViewController(url: self)
        
        safariViewController.delegate = delegate
        safariViewController.modalPresentationStyle = .overCurrentContext
        safariViewController.modalTransitionStyle = .crossDissolve
        
        delegate.present(safariViewController, animated: true)
        
        return safariViewController
    }
}

// MARK: - UIView (class function)
extension UIImageView {
    
    /// [播放GIF圖片 - 本地圖片](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-cganimateimageaturlwithblock-播放-gif-4780071b835e)
    /// - Parameters:
    ///   - url: [URL](https://developer.apple.com/documentation/imageio/3333271-cganimateimageaturlwithblock)
    ///   - options: CFDictionary?
    ///   - result: Result<Bool, Error>
    /// - Returns: [OSStatus?](https://www.osstatus.com/)
    func _GIF(url: URL, options: CFDictionary? = nil, result: ((Result<Constant.GIFImageInformation, Error>) -> Void)?) -> OSStatus? {
        
        let cfUrl = url as CFURL
        let status = CGAnimateImageAtURLWithBlock(cfUrl, options) { (index, cgImage, pointer) in
            self.image = UIImage(cgImage: cgImage)
            result?(.success((index, cgImage, pointer)))
        }
        
        return status
    }
}

// MARK: - UIApplication (class function)
extension UIApplication {
    
    /// 開啟相關的URL
    /// - Parameters:
    ///   - url: 要開啟的URL
    ///   - options: 細部選項
    ///   - result: Result<Bool, Error>
    func _openURL(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:], result: @escaping (Result<Bool, Error>) -> Void) {
        
        if !canOpenURL(url) { result(.failure(Constant.MyError.notOpenURL)); return }
        
        open(url, options: options) { (isSuccess) in
            result(.success(isSuccess))
        }
    }
}

// MARK: - UINavigationBar (class function)
extension UINavigationBar {
    
    /// [透明背景 (透明底線) => application(_:didFinishLaunchingWithOptions:)](https://sarunw.com/posts/uinavigationbar-changes-in-ios13/)
    func _transparent() {
        self.standardAppearance = UINavigationBarAppearance()._transparent()
    }
    
    /// 背景顏色 + 有沒有底線
    /// - 單一的UINavigationBar
    /// - Parameters:
    ///   - color: 背景顏色
    ///   - image: 底圖
    ///   - hasShadow: 有沒有底線
    func _backgroundColor(_ color: UIColor, image: UIImage = UIImage(), hasShadow: Bool = true) {
        self._backgroundColorForStandard(color, image: image, hasShadow: hasShadow)
        self._backgroundColorForScrollEdge(color, image: image, hasShadow: hasShadow)
    }
    
    /// [背景顏色 + 背景圖片 + 有沒有底線 (滾動時的顏色 => standardAppearance) / iOS15預設是透明的](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/ios-15-navigation-bar-tab-bar-的樣式設定-558f07137b52)
    /// - Parameters:
    ///   - color: [背景顏色](https://stackoverflow.com/questions/69111478/ios-15-navigation-bar-transparent)
    ///   - image: 底圖
    ///   - hasShadow: 有沒有底線
    func _backgroundColorForStandard(_ color: UIColor, image: UIImage = UIImage(), hasShadow: Bool = true) {
        let settings = UINavigationBarAppearance()._transparent()._backgroundColor(color)._backgroundImage(image)._hasShadow(hasShadow)
        self.standardAppearance = settings
    }
    
    /// [背景顏色 + 背景圖片 + 有沒有底線 (滾到低邊的顏色 => scrollEdgeAppearance)](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/ios-15-navigation-bar-tab-bar-的樣式設定-558f07137b52)
    /// - Parameters:
    ///   - color: [背景顏色](https://stackoverflow.com/questions/69111478/ios-15-navigation-bar-transparent)
    ///   - image: 底圖
    ///   - hasShadow: 有沒有底線
    func _backgroundColorForScrollEdge(_ color: UIColor, image: UIImage = UIImage(), hasShadow: Bool = true) {
        let settings = UINavigationBarAppearance()._transparent()._backgroundColor(color)._backgroundImage(image)._hasShadow(hasShadow)
        self.scrollEdgeAppearance = settings
    }
}

// MARK: - UINavigationBarAppearance (class function)
extension UINavigationBarAppearance {
    
    /// 設定背景色透明 - UINavigationBar.appearance()._transparent()
    /// - Returns: UINavigationBarAppearance
    func _transparent() -> Self { configureWithTransparentBackground(); return self }
    
    /// 設定背景色
    /// - Parameter color: 顏色
    /// - Returns: UINavigationBarAppearance
    func _backgroundColor(_ color: UIColor?) -> Self { backgroundColor = color; return self }
    
    /// 設定背景圖片
    /// - Parameter image: UIImage?
    /// - Returns: UINavigationBarAppearance
    func _backgroundImage(_ image: UIImage?) -> Self { backgroundImage = image; return self }

    /// 設定下底線是否透明
    /// - Parameter hasShadow: 是否透明
    /// - Returns: UINavigationBarAppearance
    func _hasShadow(_ hasShadow: Bool = true) -> Self { if (!hasShadow) { shadowColor = nil }; return self }
}

// MARK: - UITabBar (static function)
extension UITabBar {
    
    /// 透明背景 (透明底線)
    /// - application(_:didFinishLaunchingWithOptions:)
    static func _transparent() { self.appearance()._transparent() }
}

// MARK: - UITabBar (class function)
extension UITabBar {
    
    /// 透明背景 (透明底線)
    /// => application(_:didFinishLaunchingWithOptions:)
    func _transparent() {
        
        let transparentBackground = UIImage()
        
        self.isTranslucent = true
        self.backgroundImage = transparentBackground
        self.shadowImage = transparentBackground
    }
    
    /// 設定背景色 (有透明度)
    /// - Parameter color: 背景色
    func _backgroundColor(_ color: UIColor) {
        self._transparent()
        self.backgroundColor = color
    }
}

// MARK: - UITableView (class function)
extension UITableView {
    
    /// 初始化Protocal
    /// - Parameter this: UITableViewDelegate & UITableViewDataSource
    func _delegateAndDataSource(with this: UITableViewDelegate & UITableViewDataSource) {
        self.delegate = this
        self.dataSource = this
    }
    
    /// 取得UITableViewCell
    /// - let cell = tableview._reusableCell(at: indexPath) as MyTableViewCell
    /// - Parameter indexPath: IndexPath
    /// - Returns: 符合CellReusable的Cell
    func _reusableCell<T: CellReusable>(at indexPath: IndexPath) -> T where T: UITableViewCell {
        guard let cell = dequeueReusableCell(withIdentifier: T.identifier, for: indexPath) as? T else { fatalError("UITableViewCell Error") }
        return cell
    }
    
    /// [加強版的reloadData => 動畫完成後](https://cloud.tencent.com/developer/ask/sof/78125)
    /// - Parameter completion: () -> Void)?
    func _reloadData(completion: (() -> Void)?) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        reloadData()
        
        CATransaction.commit()
    }
}

// MARK: - UIRefreshControl (static function)
extension UIRefreshControl {
    
    /// 產生UIRefreshControl
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - action: 向下拉要做什麼？
    ///   - controlEvents: 事件 => 值改變的時候
    /// - Returns: UIRefreshControl
    static func _build(target: Any?, action: Selector, for controlEvents: UIControl.Event = [.valueChanged], tintColor: UIColor = .black, backgroundColor: UIColor? = nil) -> UIRefreshControl {
        
        let refreshControl = UIRefreshControl()
        
        refreshControl.addTarget(target, action: action, for: controlEvents)
        refreshControl.tintColor = tintColor
        refreshControl.backgroundColor = backgroundColor
        
        return refreshControl
    }
}

// MARK: - UICollectionView (static function)
extension UIContextualAction {
    
    /// 產生TableView滑動按鈕
    /// - tableView(_:leadingSwipeActionsConfigurationForRowAt:) / tableView(_:trailingSwipeActionsConfigurationForRowAt:)
    /// - Parameters:
    ///   - title: 標題
    ///   - style: 格式
    ///   - color: 底色
    ///   - image: 背景圖
    ///   - function: 功能
    /// - Returns: UIContextualAction
    static func _build(with title: String? = nil, style: UIContextualAction.Style = .normal, color: UIColor = .gray, image: UIImage? = nil, function: @escaping (() -> Void)) -> UIContextualAction {
        
        let contextualAction = UIContextualAction(style: style, title: title, handler: { (action, view, headler) in
            function()
            headler(true)
        })
        
        contextualAction.backgroundColor = color
        contextualAction.image = image
        
        return contextualAction
    }
}

// MARK: - UIViewController (class function)
extension UIViewController {
    
    /// 設定UIViewController透明背景 (當Alert用)
    /// - Present Modally
    /// - Parameter backgroundColor: 背景色
    func _transparent(_ backgroundColor: UIColor = .clear) {
        self._modalStyle(backgroundColor, transitionStyle: .crossDissolve, presentationStyle: .overCurrentContext)
    }
    
    /// [設定UIViewController透明背景 (當Alert用)](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-view-controller-實現-ios-app-的彈出視窗-d1c78563bcde)
    /// - Parameters:
    ///   - backgroundColor: 背景色
    ///   - transitionStyle: 轉場的Style
    ///   - presentationStyle: 彈出的Style
    func _modalStyle(_ backgroundColor: UIColor = .white, transitionStyle: UIModalTransitionStyle = .coverVertical, presentationStyle: UIModalPresentationStyle = .currentContext) {
        self.view.backgroundColor = backgroundColor
        self.modalPresentationStyle = presentationStyle
        self.modalTransitionStyle = transitionStyle
    }
    
    /// 退鍵盤
    /// - 讓View變成FisrtResponder
    /// - Parameter isEndEditing: 退鍵盤
    func _dismissKeyboard(_ isEndEditing: Bool = true) { view.endEditing(isEndEditing) }
}
