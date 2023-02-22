//
//  Extension.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import AVKit
import SafariServices
import CommonCrypto
import WebKit

// MARK: - Int (class function)
extension Int {
    
    /// [取得亂數](https://appcoda.com.tw/swift-random-number/)
    /// - Parameter range: Range<Int>
    /// - Returns: Int
    static func _random(in range: Range<Int>) -> Int {
      var generator = SystemRandomNumberGenerator()
      let number = Int.random(in: range, using: &generator)
      return number
    }
}

// MARK: - Collection (override class function)
extension Collection {

    /// [為Array加上安全取值特性 => nil](https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings)
    subscript(safe index: Index) -> Element? { return indices.contains(index) ? self[index] : nil }
}

// MARK: - Encodable (class function)
extension Encodable {
    
    /// Class => JSON Data
    /// - Returns: Data?
    func _jsonData() -> Data? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        return jsonData
    }
    
    /// Class => JSON String
    func _jsonString() -> String? {
        guard let jsonData = self._jsonData() else { return nil }
        return jsonData._string()
    }
    
    /// Class => JSON Object
    /// - Returns: Any?
    func _jsonObject() -> Any? {
        guard let jsonData = self._jsonData() else { return nil }
        return jsonData._jsonObject()
    }
}

// MARK: - Array (class function)
extension Array {
    
    /// Array => JSON Data
    /// - ["name","William"] => ["name","William"] => 5b226e616d65222c2257696c6c69616d225d
    /// - Returns: Data?
    func _jsonData(options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        return JSONSerialization._data(with: self, options: options)
    }
    
    /// Array => JSON Object
    /// - Parameters:
    ///   - writingOptions: JSONSerialization.WritingOptions
    ///   - readingOptions: JSONSerialization.ReadingOptions
    /// - Returns: Any?
    func _jsonObject(writingOptions: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions(), readingOptions: JSONSerialization.ReadingOptions = .allowFragments) -> Any? {
        return self._jsonData(options: writingOptions)?._jsonObject(options: readingOptions)
    }
    
    /// Array => JSON String
    /// - Parameters:
    ///   - options: JSONSerialization.WritingOptions
    ///   - encoding: String.Encoding
    /// - Returns: String?
    func _jsonString(options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions(), using encoding: String.Encoding = .utf8) -> String? {
        return self._jsonData(options: options)?._string(using: encoding)
    }
    
    /// [隨機排序](https://blog.csdn.net/weixin_41735943/article/details/85229696)
    /// - Returns: [[Self.Element]?](https://leetcode.com/problems/shuffle-an-array/solutions/127672/shuffle-an-array/)
    func _randomSort() -> [Self.Element]? {
        
        guard self.count != 0 else { return nil }
        
        var array = self
        
        for index in 0..<array.count {
            let randomIndex = Int._random(in: 0..<array.count)
            array.swapAt(index, randomIndex)
        }
        
        return array
    }
}

// MARK: - Array (class function)
extension Array where Self.Element: Hashable {
        
    /// [兩者不重複的值 => 差集](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/collectiontypes/)
    /// - Parameter other: [Element]
    /// - Returns: [Element]
    func _symmetricDifference(with other: [Element]) -> [Element] {
        
        let set = Set(self)
        let otherSet = Set(other)
        
        return Array(set.symmetricDifference(otherSet))
    }
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
    func _flagEmoji() -> Self {
        
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
    func _encodingURL(characterSet: CharacterSet = .urlQueryAllowed) -> Self? { return addingPercentEncoding(withAllowedCharacters: characterSet) }
    
    /// [文字 => SHA1](https://stackoverflow.com/questions/25761344/how-to-hash-nsstring-with-sha1-in-swift)
    /// - Returns: [String](https://emn178.github.io/online-tools/sha1.html)
    func _sha1() -> Self { return self._secureHashAlgorithm(digestLength: CC_SHA1_DIGEST_LENGTH, encode: CC_SHA1) }
    
    /// [修正Sqlite單引號問題 / ' => ''](https://dotblogs.com.tw/shanna/2019/09/08/205706)
    /// - Returns: [String](https://benjr.tw/102928)
    func fixSqliteSingleQuote() -> Self { return self.replacingOccurrences(of: "'", with: "''") }
}

// MARK: - String (private class function)
private extension String {
    
    /// [計算SHA家族的雜湊值](https://zh.wikipedia.org/zh-tw/SHA家族)
    /// - Parameters:
    ///   - digestLength: [雜湊值長度](https://ithelp.ithome.com.tw/articles/10241695)
    ///   - encode: [雜湊函式](https://ithelp.ithome.com.tw/articles/10208884)
    /// - Returns: [String](https://emn178.github.io/online-tools/)
    func _secureHashAlgorithm(digestLength: Int32, encode: (_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?) -> String {
        
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(digestLength))
        
        data.withUnsafeBytes { _ = encode($0.baseAddress, CC_LONG(data.count), &hash) }
        
        let hexBytes = hash.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
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
    
    /// Data => JSON
    /// - 7b2268747470223a2022626f6479227d => {"http": "body"}
    /// - Returns: Any?
    func _jsonObject(options: JSONSerialization.ReadingOptions = .allowFragments) -> Any? {
        let json = try? JSONSerialization.jsonObject(with: self, options: options)
        return json
    }
    
    /// Data => 字串
    /// - Parameter encoding: 字元編碼
    /// - Returns: String?
    func _string(using encoding: String.Encoding = .utf8) -> String? {
        return String(bytes: self, encoding: encoding)
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
    
    /// [增加日期 => 年 / 月 / 日](https://areckkimo.medium.com/用uipageviewcontroller實作萬年曆-76edaac841e1)
    /// - Parameters:
    ///   - component:
    ///   - value: 年(.year) / 月(.month) / 日(.day)
    ///   - calendar: 當地的日曆基準
    /// - Returns: Date?
    func _adding(component: Calendar.Component = .day, value: Int, for calendar: Calendar = .current) -> Date? {
        return calendar.date(byAdding: component, value: value, to: self)
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

// MARK: - URL (class function)
extension URL {
    
    /// 在APP內部開啟URL (SafariViewController) => window.webkit.messageHandlers.LinkUrl.postMessage("https://www.google.com")
    /// - Parameter urlString: URL網址
    func _openUrlWithInside(delegate: (UIViewController & SFSafariViewControllerDelegate)) -> SFSafariViewController {
        
        let safariViewController = SFSafariViewController(url: self)
        
        safariViewController.modalPresentationStyle = .fullScreen
        safariViewController.modalTransitionStyle = .crossDissolve
        safariViewController.delegate = delegate
        
        delegate.present(safariViewController, animated: true)
        
        return safariViewController
    }
    
    /// 加上後面的路徑
    /// - Returns: URL?
    /// - Parameters:
    ///   - path: String
    ///   - isDirectory: Bool
    func _appendPath(_ path: String, isDirectory: Bool = false) -> URL? {
        return self.appendingPathComponent(path, isDirectory: isDirectory)
    }
    
    /// 取得檔案路徑的副檔名
    /// - 大 or 小寫
    /// - Parameter isUppercased: 要轉換成大寫或小寫
    /// - Returns: String
    func _pathExtension(isUppercased: Bool = true) -> String {
        if (isUppercased) { return pathExtension.uppercased() }
        return pathExtension.lowercased()
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
    ///   - string: [要讀出的文字](https://medium.com/彼得潘的-swift-ios-app-開發教室/利用-avspeechsynthesizer-講話-14bc4ca4a3a6)
    ///   - voice: 使用的聲音語言
    ///   - rate: 語度 (0% ~ 100%)
    ///   - pitchMultiplier: 音調 (50% ~ 200%)
    ///   - volume: 音量 (0% ~ 100%)
    func _speak(string: String, voice: Constant.VoiceCode = .english, rate: Float = 0.5, pitchMultiplier: Float = 1.5, volume: Float = 0.5) {
        
        let utterance = AVSpeechUtterance._build(string: string, voice: voice)
        
        utterance.rate = rate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.volume = volume
        utterance.postUtteranceDelay = 1.0
        
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

// MARK: - AVAudioRecorder (static function)
extension AVAudioRecorder {
    
    /// [產生AVAudioRecorder](https://cdfq152313.github.io/post/2016-10-06/)
    /// - Parameters:
    ///   - recordURL: URL
    ///   - audioQuality: 錄音品質
    ///   - bitRate: 音質 (16 bits)
    ///   - channelNumber: 聲道數 (雙聲道)
    ///   - rate: 聲音取樣率 (44100 Hz)
    ///   - delegate: AVAudioRecorderDelegate?
    /// - Returns: AVAudioRecorder?
    static func _build(recordURL: URL, audioQuality: AVAudioQuality = .medium, bitRate: Int = 16, channelNumber: Int = 2, rate: Float = 44100.0, delegate: AVAudioRecorderDelegate? = nil) -> AVAudioRecorder? {
        
        let settings: [String: Any] = [
            AVEncoderAudioQualityKey: audioQuality.rawValue,
            AVEncoderBitRateKey: bitRate,
            AVNumberOfChannelsKey: channelNumber,
            AVSampleRateKey: rate
        ]
        
        guard let format = AVAudioFormat(settings: settings) else { return nil }
        
        let audioRecorder = try? AVAudioRecorder(url: recordURL, format: format)
        audioRecorder?.delegate = delegate
        
        return audioRecorder
    }
}

// MARK: - AVAudioRecorder (class function)
extension AVAudioRecorder {
    
    /// 開始錄音 (.wav) => NSMicrophoneUsageDescription
    /// - Returns: Result<Bool, Error>
    func _record() -> Result<Bool, Error> {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
        }
        catch {
            return .failure(error)
        }
        
        guard self.prepareToRecord(),
              self.record()
        else {
            return .success(false)
        }
        
        return .success(true)
    }
    
    /// 停止錄音
    /// - Returns: Result<Bool, Error>
    func _stop() -> Result<Bool, Error> {
        
        self.stop()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            return .failure(error)
        }
        
        return .success(true)
    }
}

// MARK: - Selector (class function)
extension Selector {
    
    /// [延遲執行函數 => 取消 -> 執行 / @objc function](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-debounce-優化-search-時發送的-request-783dc4261f27)
    /// - Parameters:
    ///   - target: [AnyObject](https://feijunjie.github.io/2019/07/05/20190705-iOS中取消延迟执行函数/)
    ///   - delayTime: [TimeInterval](https://www.jianshu.com/p/346e3ba4970d)
    ///   - object: 要傳過去的值
    func _debounce(target: AnyObject, delayTime: TimeInterval = 0.3, object: Any? = nil) {
        NSObject.cancelPreviousPerformRequests(withTarget: target, selector: self, object: object)
        target.perform(self, with: object, afterDelay: delayTime)
    }
}

// MARK: - Notification (static function)
extension Notification {
    
    /// String => Notification.Name
    /// - Parameter name: key的名字
    /// - Returns: Notification.Name
    static func _name(_ name: String) -> Notification.Name { return Notification.Name(rawValue: name) }
}

// MARK: - NotificationCenter (class function)
extension NotificationCenter {
    
    /// 註冊通知
    /// - Parameters:
    ///   - name: 要註冊的Notification名稱
    ///   - queue: 執行的序列
    ///   - object: 接收的資料
    ///   - handler: 監聽到後要執行的動作
    func _register(name: Constant.NotificationName, queue: OperationQueue = .main, object: Any? = nil, handler: @escaping ((Notification) -> Void)) {
        self.addObserver(forName: name.name(), object: object, queue: queue) { (notification) in handler(notification) }
    }

    
    /// 發出通知
    /// - Parameters:
    ///   - name: 要發出的Notification名稱
    ///   - object: 要傳送的資料
    func _post(name: Constant.NotificationName, object: Any? = nil) { self.post(name: name.name(), object: object) }
    
    /// 移除通知
    /// - Parameters:
    ///   - observer: 要移除的位置
    ///   - name: 要移除的Notification名稱
    ///   - object: 接收的資料
    func _remove(observer: Any, name: Constant.NotificationName, object: Any? = nil) { self._remove(observer: observer, name: name.name()) }
}

// MARK: - NotificationCenter (class function)
private extension NotificationCenter {
    
    /// 註冊通知
    /// - Parameters:
    ///   - name: 要註冊的Notification名稱
    ///   - queue: 執行的序列
    ///   - object: 接收的資料
    ///   - handler: 監聽到後要執行的動作
    func _register(name: Notification.Name, queue: OperationQueue = .main, object: Any? = nil, handler: @escaping ((Notification) -> Void)) {
        self.addObserver(forName: name, object: object, queue: queue) { (notification) in handler(notification) }
    }
    
    
    /// 發出通知
    /// - Parameters:
    ///   - name: 要發出的Notification名稱
    ///   - object: 要傳送的資料
    func _post(name: Notification.Name, object: Any? = nil) { self.post(name: name, object: object) }
    
    /// 移除通知
    /// - Parameters:
    ///   - observer: 要移除的位置
    ///   - name: 要移除的Notification名稱
    ///   - object: 接收的資料
    func _remove(observer: Any, name: Notification.Name, object: Any? = nil) { self.removeObserver(observer, name: name, object: object) }
}

// MARK: - FileManager (class function)
extension FileManager {
    
    /// [取得User的資料夾](https://cdfq152313.github.io/post/2016-10-11/)
    /// - UIFileSharingEnabled = YES => iOS設置iTunes文件共享
    /// - Parameter directory: User的資料夾名稱
    /// - Returns: [URL]
    func _userDirectory(for directory: FileManager.SearchPathDirectory) -> [URL] { return Self.default.urls(for: directory, in: .userDomainMask) }
    
    /// User的「文件」資料夾URL
    /// - => ~/Documents (UIFileSharingEnabled)
    /// - Returns: URL?
    func _documentDirectory() -> URL? { return self._userDirectory(for: .documentDirectory).first }
    
    /// User的「暫存」資料夾
    /// - => ~/tmp
    /// - Returns: URL
    func _temporaryDirectory() -> URL { return self.temporaryDirectory }
    
    /// 新增資料夾
    /// - Parameters:
    ///   - url: 基本資料夾位置
    ///   - path: 資料夾名稱
    /// - Returns: Result<Bool, Error>
    func _createDirectory(with url: URL?, path: String) -> Result<Bool, Error> {
        
        guard let url = url,
              let directoryURL = Optional.some(url.appendingPathComponent(path))
        else {
            return .success(false)
        }
        
        do {
            try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// [讀取資料夾 / 檔案名稱的列表](https://blog.csdn.net/pk_20140716/article/details/54925418)
    /// - ["1.png", "Demo"])
    /// - Parameter url: 要讀取的資料夾路徑
    /// - Returns: [String]?
    func _fileList(with url: URL?) -> Result<[String]?, Error> {
        
        guard let path = url?.path else { return .success(nil) }
        
        do {
            let fileList = try contentsOfDirectory(atPath: path)
            return .success(fileList)
        } catch {
            return .failure(error)
        }
    }
    
    /// 寫入Data - 二進制資料
    /// - Parameters:
    ///   - url: 寫入Data的文件URL
    ///   - data: 要寫入的資料
    /// - Returns: Result<Bool, Error>
    func _writeData(to url: URL?, data: Data?) -> Result<Bool, Error> {
        
        guard let url = url,
              let data = data
        else {
            return .success(false)
        }
        
        do {
            try data.write(to: url)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// 測試該檔案是否存在 / 是否為資料夾
    /// - Parameter url: 檔案的URL路徑
    /// - Returns: Constant.FileInfomation
    func _fileExists(with url: URL?) -> Constant.FileInfomation {
        
        guard let url = url else { return (false, false) }
        
        var isDirectory: ObjCBool = false
        let isExist = fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        return (isExist, isDirectory.boolValue)
    }
    
    /// 移除檔案
    /// - Parameter atURL: URL
    /// - Returns: Result<Bool, Error>
    func _removeFile(at atURL: URL?) -> Result<Bool, Error> {
        
        guard let atURL = atURL else { return .success(false) }
        
        do {
            try removeItem(at: atURL)
            return .success(true)
        } catch  {
            return .failure(error)
        }
    }
}

// MARK: - UIWindow (static function)
extension UIWindow {
    
    /// [取得作用中的KeyWindow](https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0)
    /// - Returns: UIWindow?
    static func _keyWindow() -> UIWindow? {
        let keyWindow = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).compactMap({$0 as? UIWindowScene}).first?.windows.filter({$0.isKeyWindow}).first
        return keyWindow
    }
}

// MARK: - UIButton (class function)
extension UIButton {
    
    /// 按鍵能不能按 / 顏色
    /// - Parameters:
    ///   - isEnabled: Bool
    ///   - backgroundColor: UIColor?
    func _isEnabled(_ isEnabled: Bool, backgroundColor: UIColor?) {
        self.isEnabled = isEnabled
        self.backgroundColor = backgroundColor
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
    
    /// 取得第一個SubView
    /// - Returns: UIView?
    func _rootView() -> UIView? { return subviews.first }
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

// MARK: - UINavigationController (class function)
extension UINavigationController {
    
    /// 取得第一頁的ViewController
    /// - Returns: UIViewController?
    func _rootViewController() -> UIViewController? { return viewControllers.first }
    
    /// 回到RootViewController => 動畫完成後
    /// - Parameter completion: 動畫完成後的動作
    /// - Returns: [UIViewController]?
    func _popToRootViewController(completion: (() -> Void)?) -> [UIViewController]? {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let viewControllers = popToRootViewController(animated: true)
        
        CATransaction.commit()
        
        return viewControllers
    }
}

// MARK: - UITabBarController
extension UITabBarController {
    
    /// [設定TabBar是否顯示](https://stackoverflow.com/questions/41169966/swift-uitabbarcontroller-hide-with-animation)
    /// - Parameters:
    ///   - hidden: [Bool](https://www.appcoda.com.tw/interactive-animation-uiviewpropertyanimator/)
    ///   - animated: 使用動畫
    ///   - duration: 動畫時間
    ///   - curve: 動畫類型
    func _tabBarHidden(_ isHidden: Bool, animated: Bool = true, duration: TimeInterval = 0.1, curve: UIView.AnimationCurve = .linear) {
        
        let viewHeight = self.view.frame.size.height
        var tabBarFrame = self.tabBar.frame
        
        tabBarFrame.origin.y = !isHidden ? viewHeight - tabBarFrame.size.height : viewHeight
        
        if (!animated) { self.tabBar.frame = tabBarFrame; return }
        
        UIViewPropertyAnimator(duration: duration, curve: curve) { [weak self] in
            guard let this = self else { return }
            this.tabBar.frame = tabBarFrame
        }.startAnimation()
    }
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

// MARK: - UIScrollView (class function)
extension UIScrollView {
    
    /// [取得ScrollView滾動的方向](https://cloud.tencent.com/developer/ask/sof/28254)
    /// - Returns: Constant.ScrollDirection
    func _direction() -> Constant.ScrollDirection {
        
        let postion = panGestureRecognizer.translation(in: self)
        
        if postion.y > 0 { return .up }
        if postion.y < 0 { return .down }
        if postion.x < 0 { return .left }
        if postion.x > 0 { return .right }
        
        return .none
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
    /// - Parameter completion: (() -> Void)?
    func _reloadData(completion: (() -> Void)? = nil) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        reloadData()
        
        CATransaction.commit()
    }
    
    /// 加強版的insertRows(at:with:)
    /// - Parameters:
    ///   - indexPaths: [IndexPath]
    ///   - animation: UITableView.RowAnimation
    ///   - animated: 動畫開關
    func _insertRows(at indexPaths: [IndexPath], animation: UITableView.RowAnimation, animated: Bool) {
        
        UIView.setAnimationsEnabled(animated)
        insertRows(at: indexPaths, with: .none)
        UIView.setAnimationsEnabled(true)
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
    
    /// 退鍵盤
    /// - 讓View變成FisrtResponder
    /// - Parameter isEndEditing: 退鍵盤
    func _dismissKeyboard(_ isEndEditing: Bool = true) { view.endEditing(isEndEditing) }
    
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
}

// MARK: - WKWebView (static function)
extension WKWebView {
    
    /// 產生WKWebView (WKNavigationDelegate & WKUIDelegate)
    /// - Parameters:
    ///   - delegate: WKNavigationDelegate & WKUIDelegate
    ///   - frame: WKWebView的大小
    ///   - canOpenWindows: [window.open(url)](https://www.jianshu.com/p/561307f8aa9e) for  [webView(_:createWebViewWith:for:windowFeatures:)](https://developer.apple.com/documentation/webkit/wkuidelegate/1536907-webview)
    ///   - configuration: WKWebViewConfiguration
    ///   - contentInsetAdjustmentBehavior: scrollView是否為全畫面
    /// - Returns: WKWebView
    static func _build(delegate: (WKNavigationDelegate & WKUIDelegate)?, frame: CGRect, canOpenWindows: Bool = false, configuration: WKWebViewConfiguration = WKWebViewConfiguration(), contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .never) -> WKWebView {
        
        let webView = WKWebView(frame: frame, configuration: configuration)
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = canOpenWindows
        
        webView.backgroundColor = .white
        webView.navigationDelegate = delegate
        webView.uiDelegate = delegate
        webView.scrollView.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
        
        return webView
    }
}

// MARK: - WKWebView (class function)
extension WKWebView {
    
    /// 載入WebView網址
    func _load(urlString: String?, cachePolicy: URLRequest.CachePolicy = .reloadIgnoringCacheData, timeoutInterval: TimeInterval) -> WKNavigation? {
        
        guard let urlString = urlString,
              let url = URL(string: urlString),
              let urlRequest = Optional.some(URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval))
        else {
            return nil
        }
        
        return self.load(urlRequest)
    }
    
    /// [網址讀取進度條設定](https://juejin.cn/post/6894106901186330632) => 回傳值要接起來
    /// - Parameters:
    ///   - height: 進度條的位置高度
    ///   - thickness: 進度條的厚度
    ///   - trackTintColor: 進度條的背景色
    ///   - progressTintColor: 進度條的前景色
    /// - Returns: NSKeyValueObservation?
    func _estimatedProgress(with height: CGFloat, thickness: CGFloat = 5.0, trackTintColor: UIColor? = .clear, progressTintColor: UIColor? = .systemBlue) -> NSKeyValueObservation? {
        
        let progressView = UIProgressView(frame: CGRect(x: 0, y: height, width: self.bounds.width, height: thickness))
        progressView.progress = 0
        progressView.trackTintColor = trackTintColor
        progressView.progressTintColor = progressTintColor
        
        self.addSubview(progressView)
        
        let observation = self.observe(\.estimatedProgress, options: [.new]) { [weak self] (_, _)  in
            guard let this = self else { return }
            progressView.progress = Float(this.estimatedProgress)
        }
        
        return observation
    }
}
