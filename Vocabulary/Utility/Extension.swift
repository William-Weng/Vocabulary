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
import PencilKit
import WebKit
import WWNetworking

// MARK: - Bool (function)
extension Bool {
    
    /// 將布林值轉成Int (true => 1 / false => 0)
    /// - Returns: Int
    func _int() -> Int { return Int(truncating: NSNumber(value: self)) }
}

// MARK: - Int (function)
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

// MARK: - Array (function)
extension Array {
    
    /// 彈出開頭第一個
    /// - Returns: Element?
    mutating func _popFirst() -> Element? {
        return isEmpty ? nil : removeFirst()
    }
}

// MARK: - UIColr (init function)
extension UIColor {
    
    /// UIColor(red: 255, green: 255, blue: 255, alpha: 255)
    /// - Parameters:
    ///   - red: 紅色 => 0~255
    ///   - green: 綠色 => 0~255
    ///   - blue: 藍色 => 0~255
    ///   - alpha: 透明度 => 0~255
    convenience init(red: Int, green: Int, blue: Int, alpha: Int) { self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha) / 255.0) }
    
    /// UIColor(red: 255, green: 255, blue: 255)
    /// - Parameters:
    ///   - red: 紅色 => 0~255
    ///   - green: 綠色 => 0~255
    ///   - blue: 藍色 => 0~255
    convenience init(red: Int, green: Int, blue: Int) { self.init(red: red, green: green, blue: blue, alpha: 255) }
    
    /// UIColor(rgb: 0xFFFFFF)
    /// - Parameter rgb: 顏色色碼的16進位值數字
    convenience init(rgb: Int) { self.init(red: (rgb >> 16) & 0xFF, green: (rgb >> 8) & 0xFF, blue: rgb & 0xFF) }
    
    /// UIColor(rgba: 0xFFFFFFFF)
    /// - Parameter rgba: 顏色的16進位值數字
    convenience init(rgba: Int) { self.init(red: (rgba >> 24) & 0xFF, green: (rgba >> 16) & 0xFF, blue: (rgba >> 8) & 0xFF, alpha: (rgba) & 0xFF) }
    
    /// UIColor(rgb: #FFFFFF)
    /// - Parameter rgb: 顏色的16進位值字串
    convenience init(rgb: String) {
        
        let ruleRGB = "^#[0-9A-Fa-f]{6}$"
        let predicateRGB = Constant.Predicate.matches(regex: ruleRGB).build()
        
        guard predicateRGB.evaluate(with: rgb),
              let string = rgb.split(separator: "#").last,
              let number = Int.init(string, radix: 16)
        else {
            self.init(red: 0, green: 0, blue: 0, alpha: 0); return
        }
        
        self.init(rgb: number)
    }
}

// MARK: - CGColor (function)
extension CGColor {
    
    /// [取得顏色的RGBA值 => 0% ~ 100%](https://stackoverflow.com/questions/28644311/how-to-get-the-rgb-code-int-from-an-uicolor-in-swift)
    /// - Returns: Constant.RGBAInformation?
    func _rgba() -> Constant.RGBAInformation? {
        
        guard let components = components,
              !components.isEmpty
        else {
            return nil
        }
        
        guard let red = components[safe: 0],
              let green = components[safe: 1],
              let blue = components[safe: 2],
              let alpha = components[safe: 3]
        else {
            return nil
        }
        
        return (red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// RGB => HexString
    /// - (0.0, 1.0, 0.0, 1.0) => (#00FF00FF)
    /// - Parameters:
    ///   - colorSpace: [色域](http://m.pjtime.com/2021/10/m282732658448.shtml)
    ///   - intent: CGColorRenderingIntent
    ///   - options: CFDictionary? = nil
    /// - Returns: String?
    func _hexString(by colorSpace: CGColorSpace? = .init(name: CGColorSpace.sRGB), intent: CGColorRenderingIntent = .defaultIntent, options: CFDictionary? = nil) -> String? {
        
        guard let colorSpace = colorSpace,
              let cgColor = convertColorSpace(colorSpace, intent: intent, options: options),
              let colorRGBA = cgColor._rgba()
        else {
            return nil
        }
        
        let multiplier = CGFloat(255.999999)
        let red = Int(colorRGBA.red * multiplier)
        let green = Int(colorRGBA.green * multiplier)
        let blue = Int(colorRGBA.blue * multiplier)
        let alpha = Int(colorRGBA.alpha * multiplier)
        
        if (colorRGBA.alpha == 1.0) { return String(format: "#%02lX%02lX%02lX", red, green, blue) }
        return String(format: "#%02lX%02lX%02lX%02lX", String(format: "#%02lX%02lX%02lX", red, green, blue, alpha))
    }
    
    /// [色域轉換](https://stackoverflow.com/questions/74608754/convert-display-p3-to-esrgb-by-hex-color-in-ios-swift)
    /// - Parameters:
    ///   - colorSpace: [DisplayP3 -> SRGB](https://colorgeek.co/2022/08/04/what_is_p3_color/)
    ///   - intent: CGColorRenderingIntent
    ///   - options: CFDictionary?
    /// - Returns: CGColor?
    func convertColorSpace(_ colorSpace: CGColorSpace? = .init(name: CGColorSpace.sRGB), intent: CGColorRenderingIntent = .defaultIntent, options: CFDictionary? = nil) -> CGColor? {
        
        guard let colorSpace = colorSpace,
              let cgColor = converted(to: colorSpace, intent: intent, options: options)
        else {
            return nil
        }
        
        return cgColor
    }
}

// MARK: - TimeInterval (function)
extension TimeInterval {
 
    /// [秒 => 時間 (210.2799sec => 3 minutes, 30 seconds)](https://stackoverflow.com/questions/26794703/swift-integer-conversion-to-hours-minutes-seconds)
    /// - Parameter unitsStyle: 輸出的方式 => .full
    /// - Parameter allowedUnits: 想要看的單位 => [.hour, .minute, .second]
    /// - Parameter behavior: 處理0的顯示問題
    /// - Parameter localeIdentifier: 語言代號 => en-US
    /// - Returns: String?
    func _time(unitsStyle: DateComponentsFormatter.UnitsStyle = .full, allowedUnits: NSCalendar.Unit = [.hour, .minute, .second], behavior: DateComponentsFormatter.ZeroFormattingBehavior = .default, localeIdentifier: String = "en-US") -> String? {
        
        let calendar = Calendar._build(localeIdentifier: localeIdentifier)
        let formatter = DateComponentsFormatter()
        
        formatter.calendar = calendar
        formatter.allowedUnits = allowedUnits
        formatter.unitsStyle = unitsStyle
        formatter.zeroFormattingBehavior = behavior
        
        return formatter.string(from: self)
    }
}

// MARK: - Calendar (static function)
extension Calendar {
    
    /// 產生本地端的日曆
    /// - Parameter localeIdentifier: [語言代號 (zh-Hant-TW)](http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
    /// - Returns: Calendar
    static func _build(localeIdentifier: String = "en-US") -> Self {
        
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: localeIdentifier)

        return calendar
    }
}

// MARK: - DispatchQueue (function)
extension DispatchQueue {
    
    /// [GCD - Grand Central Dispatch](https://ithelp.ithome.com.tw/articles/10227071)
    /// - Parameters:
    ///   - qos: DispatchQoS.QoSClass
    ///   - globalAction: 次線程的動作
    ///   - mainAction: 主線程的動作
    static func _GCD(qos: DispatchQoS.QoSClass = .default, globalAction: @escaping (() -> Void), mainAction: @escaping (() -> Void)) {
        
        DispatchQueue.global(qos: qos).async {
            globalAction()
            DispatchQueue.main.async { mainAction() }
        }
    }
}

// MARK: - Collection (override function)
extension Collection {

    /// [為Array加上安全取值特性 => nil](https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings)
    subscript(safe index: Index) -> Element? { return indices.contains(index) ? self[index] : nil }
}

// MARK: - Collection (mutating function)
extension Collection where Self == [Music] {
    
    /// [彈出第一個](https://stackoverflow.com/questions/32869999/how-do-you-use-swift-2-0-popfirst-on-an-array)
    /// - Returns: Music?
    mutating func _popFirst() -> Music? {
        
        var slice = self[self.indices]
        
        defer { self = Array(slice) }
        return slice.popFirst()
    }
}

// MARK: - Set (function)
extension Set where Self.Element: Hashable {
    
    /// 切換Set
    /// - Parameter member: Self.Element
    mutating func _toggle(member: Self.Element) {
        if !contains(member) { self.insert(member); return }
        self.remove(member)
    }
}

// MARK: - Array (function)
extension Array {
    
    /// [仿javaScript的forEach()](https://developer.mozilla.org/zh-TW/docs/Web/JavaScript/Reference/Global_Objects/Array/forEach)
    /// - Parameter forEach: (Int, Element, Self)
    func _forEach(_ forEach: (Int, Element, Self) -> Void) {
                
        for (index, object) in self.enumerated() {
            forEach(index, object, self)
        }
    }
}

// MARK: - Encodable (function)
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

// MARK: - Sequence (function)
extension Sequence {
    
    /// Array => JSON Data => Base64String
    /// - Parameters:
    ///   - writingOptions: JSONSerialization.WritingOptions
    ///   - base64EncodingOptions: Data.Base64EncodingOptions
    /// - Returns: String?
    func _base64JSONDataString(writingOptions: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions(), base64EncodingOptions: Data.Base64EncodingOptions = []) -> String? {
        return _jsonData(options: writingOptions)?._base64String(options: base64EncodingOptions)
    }
}

// MARK: - Array (function)
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
    
    /// Array => JSON Data => [T]
    /// - Parameter type: 要轉換成的Array類型
    /// - Returns: [T]?
    func _jsonClass<T: Decodable>(for type: [T].Type) -> [T]? {
        let array = self._jsonData()?._class(type: type.self)
        return array
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

// MARK: - Dictionary (function)
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

// MARK: - String (function)
extension String {
    
    /// 去除空白及換行字元
    /// - Returns: Self
    func _removeWhitespacesAndNewlines() -> Self { return trimmingCharacters(in: .whitespacesAndNewlines) }
        
    /// [國家地區代碼](https://zh.wikipedia.org/wiki/國家地區代碼)
    /// - [顏文字：AA => 🇦🇦 / TW => 🇹🇼](https://lets-emoji.com/)
    /// - Returns: String
    func _flagEmoji() -> Self {
        
        let characterA: (ascii: String, unicode: UInt32, error: String) = ("A", 0x1F1E6, "？")
        var unicodeString = ""
        
        for scalar in unicodeScalars {
            
            guard let asciiA = characterA.ascii.unicodeScalars.first,
                  let unicodeWord = Unicode.Scalar(characterA.unicode + scalar.value - asciiA.value)
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
    
    /// [修正Sqlite單引號問題 / ' => ''](https://dotblogs.com.tw/shanna/2019/09/08/205706)
    /// - Returns: [String](https://benjr.tw/102928)
    func fixSqliteSingleQuote() -> Self { return self.replacingOccurrences(of: "'", with: "''") }
    
    /// 去除空白及換行字元
    /// - Returns: Self
    func _removeWhiteSpacesAndNewlines() -> Self {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 將"2020-07-08 16:36:31 +0800" => Date()
    /// - Parameter dateFormat: 時間格式
    /// - Returns: Date?
    func _date(dateFormat: String = "yyyy-MM-dd HH:mm:ss ZZZ") -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        return dateFormatter.date(from: self)
    }
    
    /// String => Data
    /// - Parameters:
    ///   - encoding: 字元編碼
    ///   - isLossyConversion: 失真轉換
    /// - Returns: Data?
    func _data(using encoding: String.Encoding = .utf8, isLossyConversion: Bool = false) -> Data? {
        let data = self.data(using: encoding, allowLossyConversion: isLossyConversion)
        return data
    }
    
    /// 文字 => Base64文字
    /// => Hello World -> SGVsbG8gV29ybGQ=
    /// - Parameter options: Data.Base64EncodingOptions
    /// - Returns: String?
    func _base64Encoded(using encoding: String.Encoding = .utf8, isLossyConversion: Bool = false, options: Data.Base64EncodingOptions = []) -> String? {
        return _data(using: encoding, isLossyConversion: isLossyConversion)?._base64String(options: options)
    }
    
    /// JSON String => JSON Object
    /// - Parameters:
    ///   - encoding: 字元編碼
    ///   - options: JSON序列化讀取方式
    /// - Returns: Any?
    func _jsonObject(encoding: String.Encoding = .utf8, options: JSONSerialization.ReadingOptions = .allowFragments) -> Any? {
        
        guard let data = self._data(using: encoding),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: options)
        else {
            return nil
        }
        
        return jsonObject
    }
    
    /// 將轉成Base64的JSONObject轉回來 - "WzEsMiwzXQ==" => [1, 2, 3]
    /// - Parameters:
    ///   - encoding: String.Encoding
    ///   - isLossyConversion: Bool
    ///   - options: JSONSerialization.ReadingOptions
    /// - Returns: T?
    func _base64JSONObjectDecode<T>(using encoding: String.Encoding = .utf8, isLossyConversion: Bool = false, options: JSONSerialization.ReadingOptions = .allowFragments) -> T? {
        
        guard let data = _data(using: encoding, isLossyConversion: isLossyConversion),
              let jsonObject = Data(base64Encoded: data)?._jsonObject(options: options)
        else {
            return nil
        }
        
        return jsonObject as? T
    }
}

// MARK: - Data (function)
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
    
    /// [Data => Base64文字](https://zh.wikipedia.org/zh-tw/Base64)
    /// - Parameter options: Base64EncodingOptions
    /// - Returns: Base64EncodingOptions
    func _base64String(options: Base64EncodingOptions = []) -> String {
        return self.base64EncodedString(options: options)
    }
}

// MARK: - Date (function)
extension Date {
    
    /// 將UTC時間 => 該時區的時間
    /// - 2020-07-07 16:08:50 +0800
    /// - Parameters:
    ///   - dateFormat: 時間格式
    ///   - timeZone: 時區辨識
    /// - Returns: String?
    func _localTime(dateFormat: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone? = TimeZone(identifier: "UTC")) -> String {
        
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "\(dateFormat)"
        dateFormatter.timeZone = timeZone
        
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

// MARK: - UIDeviceOrientation
extension UIDeviceOrientation {
    
    /// UIDeviceOrientation => UIInterfaceOrientation
    /// - Returns: UIInterfaceOrientation
    func _interfaceOrientation() -> UIInterfaceOrientation {
        
        var interfaceOrientation: UIInterfaceOrientation = .unknown
        
        switch self {
        case .portrait: interfaceOrientation = .portrait
        case .portraitUpsideDown: interfaceOrientation = .portraitUpsideDown
        case .landscapeLeft: interfaceOrientation = .landscapeRight
        case .landscapeRight: interfaceOrientation = .landscapeLeft
        case .unknown, .faceUp, .faceDown: interfaceOrientation = .unknown
        @unknown default: break
        }
        
        return interfaceOrientation
    }
}

// MARK: - AppDelegate
//extension AppDelegate {
//    
//    /// [設置畫面能夠旋轉的方向](https://johnchihhonglin.medium.com/限制某個頁面的螢幕旋轉方向-8c7235d5a774)
//    /// - Parameter orientation: UIInterfaceOrientationMask
//    /// - Returns: Bool
//    func _lockOrientation(_ orientation: UIInterfaceOrientationMask) -> Bool {
//        
//        guard let delegate = UIApplication.shared.delegate as? OrientationLockable else { return false }
//        delegate.orientationLock = orientation
//        
//        return true
//    }
//    
//    /// [強制改變裝置的方向](https://juejin.cn/post/6855869344119783431)
//    /// - Parameters:
//    ///   - orientation: [UIInterfaceOrientationMask](https://www.jianshu.com/p/1a43d839a0e3)
//    ///   - rotateOrientation: UIInterfaceOrientation
//    func _orientation(lock orientation: UIInterfaceOrientationMask, rotate rotateOrientation: UIInterfaceOrientation) -> Bool {
//        
//        let isSuccess = self._lockOrientation(orientation)
//        
//        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
//        UIViewController.attemptRotationToDeviceOrientation()
//                
//        return isSuccess
//    }
//}

// MARK: - Bundle (function)
extension Bundle {
    
    /// 讀取info.plist的欄位資訊
    /// - CFBundleShortVersionString...
    /// - Parameter key: 要取的Key值
    /// - Returns: Any?
    func _infoDictionary(with key: String) -> Any? { return self.infoDictionary?[key] }
    
    /// 讀取info.plist的欄位資訊
    /// - CFBundleShortVersionString...
    /// - Parameter key: 要取的Key值
    /// - Returns: Any?
    func _infoDictionary(with key: Constant.InfoPlistKey) -> Any? { return self._infoDictionary(with: key.rawValue) }
    
    /// 取得APP版本號 (外部 / 內部)
    /// - info.plist => Version
    /// - Parameter `default`: 預設值
    /// - Returns: String?
    func _appVersion(`default`: Constant.AppVersion = (app: "0.0.0", build: "1970101")) -> Constant.AppVersion {
        
        let app = self._appVersionString() ?? `default`.app
        let build = self._appBuildString() ?? `default`.build
        
        return (app: app, build: build)
    }
    
    /// 取得外部版本號
    /// - info.plist => Version
    /// - Returns: String?
    func _appVersionString() -> String? {
        guard let version = self._infoDictionary(with: .CFBundleShortVersionString) as? String else { return nil }
        return version
    }
    
    /// 取得內部版本號
    /// - info.plist => Build
    /// - Returns: String?
    func _appBuildString() -> String? {
        guard let build = self._infoDictionary(with: .CFBundleVersion) as? String else { return nil }
        return build
    }
}

// MARK: - UIPasteboard (static function)
extension UIPasteboard {
 
    /// 剪貼簿 (全域)
    /// - Parameter string: 要複製的文字
    static func _paste(string: String) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = string
    }
}

// MARK: - URLComponents (static function)
extension URLComponents {
    
    /// 產生URLComponents
    /// - Parameters:
    ///   - urlString: UrlString
    ///   - queryItems: Query參數
    /// - Returns: URLComponents?
    static func _build(urlString: String, queryItems: [URLQueryItem]? = nil) -> URLComponents? {
        
        guard var urlComponents = URLComponents(string: urlString) else { return nil }
        
        if let queryItems = queryItems {
            
            let urlComponentsQueryItems = urlComponents.queryItems ?? []
            let newQueryItems = (urlComponentsQueryItems + queryItems)
            
            urlComponents.queryItems = newQueryItems
        }
        
        return urlComponents
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

// MARK: - URL (function)
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
    
    /// [將URL => URLComponents](https://youtu.be/OyzFPrVIlQ8)
    /// - Returns: [URLComponents?](https://cg2010studio.com/2014/11/13/ios-客製化-url-scheme-custom-url-scheme/)
    func _components() -> URLComponents? {
        return URLComponents._build(urlString: absoluteString, queryItems: nil)
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

// MARK: - CALayer (function)
extension CALayer {
    
    /// 設定圓角
    /// - 可以個別設定要哪幾個角
    /// - 預設是四個角全是圓角
    /// - Parameters:
    ///   - radius: 圓的半徑
    ///   - corners: 圓角要哪幾個邊
    func _maskedCorners(radius: CGFloat, corners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]) {
        masksToBounds = true
        maskedCorners = corners
        cornerRadius = radius
    }
    
    /// [設置陰影 (不切邊)](https://www.jianshu.com/p/2c90d6a637f7)
    /// - Parameters:
    ///   - color: [陰影顏色](https://medium.com/彼得潘的-swift-ios-app-開發教室/swift-collectionview-csutomercollectioncell-decoder-api-collectioncell陰影-collectioncell-e025d399022a)
    ///   - backgroundColor: 陰影背景色
    ///   - offset: 陰影位移
    ///   - opacity: 陰影不透明度
    ///   - radius: 陰影半徑
    ///   - cornerRadius: 圓角半徑
    func _shadow(color: UIColor, backgroundColor: UIColor, offset: CGSize, opacity: Float, radius: CGFloat, cornerRadius: CGFloat) {
        
        masksToBounds = false
        
        shadowColor = color.cgColor
        shadowOffset = offset
        shadowOpacity = opacity
        shadowRadius = radius
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor.cgColor
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

// MARK: - AVSpeechSynthesizer (function)
extension AVSpeechSynthesizer {
    
    /// [讀出文字 / 文字發聲](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/讓開不了口的-app-開口說話-48c674f8f69e)
    /// - Parameters:
    ///   - string: [要讀出的文字](https://medium.com/彼得潘的-swift-ios-app-開發教室/利用-avspeechsynthesizer-講話-14bc4ca4a3a6)
    ///   - voice: 使用的聲音語言
    ///   - rate: 語速 (0% ~ 100%)
    ///   - pitchMultiplier: 音調 (50% ~ 200%)
    ///   - volume: 音量 (0% ~ 100%)
    func _speak(string: String, code: String, rate: Float, pitchMultiplier: Float, volume: Float) {
        
        let utterance = AVSpeechUtterance._build(string: string, code: code)
        
        utterance.rate = rate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.volume = volume
        utterance.postUtteranceDelay = 1.0
        
        self.speak(utterance)
    }
}

// MARK: - AVSpeechUtterance (static function)
extension AVSpeechUtterance {
    
    /// [產生AVSpeechUtterance](https://stackoverflow.com/questions/35492386/how-to-get-a-list-of-all-voices-on-ios-9/43576853)
    /// - Parameters:
    ///   - string: 要讀的文字
    ///   - code: 使用的聲音語言
    /// - Returns: AVSpeechUtterance
    static func _build(string: String, code: String) -> AVSpeechUtterance {
        
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: code)

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

// MARK: - AVAudioRecorder (function)
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

// MARK: - Selector (function)
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

// MARK: - NotificationCenter (function)
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

// MARK: - NotificationCenter (function)
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

// MARK: - FileManager (function)
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
    
    /// 讀取檔案文字
    /// - Parameters:
    ///   - url: 文件的URL
    ///   - encoding: 編碼格式
    /// - Returns: String?
    func _readText(from url: URL?, encoding: String.Encoding = .utf8) -> String? {
        
        guard let url = url,
              let readedText = try? String(contentsOf: url, encoding: encoding)
        else {
            return nil
        }
        
        return readedText
    }
    
    /// 寫入檔案文字
    /// - Parameters:
    ///   - url: 文字檔的URL
    ///   - text: 要寫入的文字
    ///   - encoding: 文字的編碼
    /// - Returns: Bool
    func _writeText(to url: URL?, text: String?, encoding: String.Encoding = .utf8) -> Result<Bool, Error> {
        
        guard let url = url,
              let text = text
        else {
            return .success(false)
        }
        
        do {
            try text.write(to: url, atomically: true, encoding: encoding)
        } catch {
            return .failure(error)
        }
        
        return .success(true)
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
    
    /// 移動檔案
    /// - Parameters:
    ///   - atURL: 從這裡移動 =>
    ///   - toURL: => 到這裡
    /// - Returns: Result<Bool, Error>
    func _moveFile(at atURL: URL, to toURL: URL) -> Result<Bool, Error> {
        
        do {
            try moveItem(at: atURL, to: toURL)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// 複製檔案
    /// - Parameters:
    ///   - atURL: 從這裡複製 =>
    ///   - toURL: => 到這裡
    /// - Returns: Result<Bool, Error>
    func _copyFile(at atURL: URL, to toURL: URL) -> Result<Bool, Error> {
        
        do {
            try copyItem(at: atURL, to: toURL)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - UIImpactFeedbackGenerator (static function)
extension UIImpactFeedbackGenerator {
    
    /// 產生震動物件 => UIImpactFeedbackGenerator(style: style)
    /// - Parameter style: 震動的類型
    static func _build(style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator { return UIImpactFeedbackGenerator(style: style) }
    
    /// 產生震動 => impactOccurred()
    static func _impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let feedbackGenerator = Self._build(style: style)
        feedbackGenerator._impact()
    }
}

// MARK: - UIImpactFeedbackGenerator (static function)
extension UIImpactFeedbackGenerator {
    
    /// 產生震動 => impactOccurred()
    func _impact() { self.impactOccurred() }
}

// MARK: - UIDevice (static function)
extension UIDevice {
    
    /// [取得系統的相關資訊](https://mini.nidbox.com/diary/read/9759417) => (name: "iOS", version: "14.6", model: "iPhone")
    /// - Returns: [Constant.SystemInformation](https://mini.nidbox.com/diary/read/9759417)
    static func _systemInformation() -> Constant.SystemInformation {
        let info: Constant.SystemInformation = (name: UIDevice.current.systemName, version: UIDevice.current.systemVersion, model: UIDevice.current.model, idiom: UIDevice.current.userInterfaceIdiom)
        return info
    }
}

// MARK: - UIWindow (static function)
extension UIWindow {
    
    /// [取得作用中的KeyWindow](https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0)
    /// - Parameter hasScene: [有沒有使用Scene ~ iOS 13](https://juejin.cn/post/6844903993496305671)
    /// - Returns: UIWindow?
    static func _keyWindow(hasScene: Bool = true) -> UIWindow? {
        
        var keyWindow: UIWindow?
        
        keyWindow = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).compactMap({$0 as? UIWindowScene}).first?.windows.filter({$0.isKeyWindow}).first
        
        return keyWindow
    }
}

// MARK: - UIWindow (function)
extension UIWindow {
    
    /// 測試有沒有SafeArea => 瀏海？
    /// - Returns: Bool
    func _hasSafeArea() -> Bool {
        let bottom = safeAreaInsets.bottom
        return bottom > 0
    }
}

// MARK: - UIStoryboard (static function)
extension UIStoryboard {
    
    /// 由UIStoryboard => ViewController
    /// - Parameters:
    ///   - name: Storyboard的名稱 => Main.storyboard
    ///   - storyboardBundleOrNil: Bundle名稱
    ///   - identifier: ViewController的代號 (記得要寫)
    /// - Returns: T (泛型) => UIViewController
    static func _instantiateViewController<T: UIViewController>(name: String = "Main", bundle storyboardBundleOrNil: Bundle? = nil, identifier: String = String(describing: T.self)) -> T {
        
        let viewController = Self(name: name, bundle: storyboardBundleOrNil).instantiateViewController(identifier: identifier) as T
        return viewController
    }
}

// MARK: - UIView (static function)
extension UIView {
    
    /// UIView動畫關閉 / 啟動
    /// - Parameters:
    ///   - isEnabled: Bool
    ///   - action: () -> Void
    static func _animations(isEnabled: Bool, action: () -> Void) {
        
        CATransaction.begin()
        UIView.setAnimationsEnabled(isEnabled)
        CATransaction.setDisableActions(!isEnabled)
        
        action()
        
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
    }
}

// MARK: - UIView (function)
extension UIView {
    
    /// [設定LayoutConstraint => 不能加frame](https://zonble.gitbooks.io/kkbox-ios-dev/content/autolayout/intrinsic_content_size.html)
    /// - Parameter view: [要設定的View](https://www.appcoda.com.tw/auto-layout-programmatically/)
    func _autolayout(on view: UIView) {
        
        removeFromSuperview()
        view.addSubview(self)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}

// MARK: - UIButton (function)
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

// MARK: - UIImage (function)
extension UIImage {
    
    /// [iOS點九圖NinePatch解析 - 9.png](https://mp.weixin.qq.com/s/angyJag7AZntt2FLNCOuXw)
    /// - Parameters:
    ///   - image: [原始圖片](https://blog.csdn.net/kmyhy/article/details/79087418)
    ///   - capInsets: [裁切的位置](https://awesome-tips.gitbook.io/ios/xcode/content-4)
    ///   - resizingMode: [填充的方式](https://developer.apple.com/documentation/swift/slice)
    func _ninePatch(capInsets: UIEdgeInsets, resizingMode: UIImage.ResizingMode = .stretch) -> UIImage {
        return self.resizableImage(withCapInsets: capInsets, resizingMode: resizingMode)
    }
}

// MARK: - UIImageView (function)
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

// MARK: - UIApplication (function)
extension UIApplication {
    
    /// 開啟相關的URL
    /// - Parameters:
    ///   - url: 要開啟的URL
    ///   - options: 細部選項
    ///   - result: Result<Bool, Error>
    func _openURL(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:], result: @escaping (Result<Bool, Error>) -> Void) {
        
        if !canOpenURL(url) { result(.failure(Constant.CustomError.notOpenURL)); return }
        
        open(url, options: options) { (isSuccess) in
            result(.success(isSuccess))
        }
    }
    
    /// [更換APP ICON](https://github.com/CoderTitan/ChangeIcon)
    /// - [動態更換APP ICON](https://www.cnblogs.com/zhanggui/p/6674858.html)
    /// - [會回傳現在使用的ICON名稱](https://www.jianshu.com/p/69313970d0e7)
    /// - [Key = PrimaryIcon就是原本的ICON => nil](https://www.hackingwithswift.com/example-code/uikit/how-to-change-your-app-icon-dynamically-with-setalternateiconname)
    /// - Parameters:
    ///   - key: [要取ICON的Key值](https://medium.com/ios-os-x-development/dynamically-change-the-app-icon-7d4bece820d2)
    ///   - result: (Result<String?, Error>) -> Void
    func _alternateIcons(for key: String?, result: @escaping ((Result<String?, Error>) -> Void)) {
        
        guard UIApplication.shared.supportsAlternateIcons else { result(.failure(Constant.CustomError.notSupports)); return }
        
        UIApplication.shared.setAlternateIconName(key) { (error) in
            if let error = error { result(.failure(error)); return }
            result(.success(UIApplication.shared.alternateIconName))
        }
    }
}

// MARK: - UINavigationBar (function)
extension UINavigationBar {
    
    /// 取得第一個SubView
    /// - Returns: UIView?
    func _rootView() -> UIView? { return subviews.first }
    
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

// MARK: - UINavigationBarAppearance (function)
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

// MARK: - UINavigationController (function)
extension UINavigationController {
    
    /// 設定NavigationBarHidden
    /// - Parameters:
    ///   - isHidden: Bool
    ///   - flag: Bool
    func _barHidden(_ isHidden: Bool, animated flag: Bool = true) {
        setNavigationBarHidden(isHidden, animated: flag)
    }
    
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
    
    /// 取得NavigationBar的高度
    /// - Parameter keyWindow: UIWindow?
    /// - Returns: CGFloat
    func _navigationBarHeight(for keyWindow: UIWindow?) -> CGFloat {
        
        guard let statusBarManager = UIStatusBarManager._build(for: keyWindow),
              let navigationBarFrame = Optional.some(navigationBar.frame)
        else {
            return .zero
        }
        
        return statusBarManager.statusBarFrame.height + navigationBarFrame.height
    }
}

// MARK: - UIStatusBarManager (static function)
extension UIStatusBarManager {
    
    /// [取得UIStatusBarManager](https://www.jianshu.com/p/d60757f13038)
    /// - Parameter keyWindow: UIWindow?
    /// - Returns: [UIStatusBarManager?](https://www.jianshu.com/p/e401762d824b)
    static func _build(for keyWindow: UIWindow? = UIWindow._keyWindow()) -> UIStatusBarManager? {
        return keyWindow?.windowScene?.statusBarManager
    }
}

// MARK: - UITabBarController
extension UITabBarController {
    
    /// [設定TabBar是否顯示](https://stackoverflow.com/questions/41169966/swift-uitabbarcontroller-hide-with-animation)
    /// - Parameters:
    ///   - hidden: [Bool](https://www.appcoda.com.tw/interactive-animation-uiviewpropertyanimator/)
    func _tabBarHidden(_ isHidden: Bool) {
                
        let viewHeight = view.frame.size.height
        var tabBarFrame = tabBar.frame
        
        tabBarFrame.origin.y = !isHidden ? viewHeight - tabBarFrame.size.height : viewHeight
        tabBar.frame = tabBarFrame
    }
}

// MARK: - UIActivityViewController (static function)
extension UIActivityViewController {
    
    /// [產生UIActivityViewController分享功能](https://jjeremy-xue.medium.com/swift-玩玩-uiactivityviewcontroller-5995bb80ff68)
    /// - Parameters:
    ///   - activityItems: [Any]
    ///   - applicationActivities: [UIActivity]?
    ///   - tintColor: tintColor
    ///   - sourceView: 要貼在哪個View上
    /// - Returns: UIActivityViewController
    static func _build(activityItems: [Any], applicationActivities: [UIActivity]? = nil, tintColor: UIColor = .white, sourceView: UIView? = nil) -> UIActivityViewController {
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        
        activityViewController.view.tintColor = tintColor
        activityViewController.popoverPresentationController?.sourceView = sourceView
        
        return activityViewController
    }
}

// MARK: - UITabBar (function)
extension UITextField {
    
    /// [退鍵盤](https://medium.com/彼得潘的-swift-ios-app-開發教室/uitextfield如何讓鍵盤消失-)
    /// - Parameter textField: UITextField
    func _dismissKeyboard() { self.resignFirstResponder() }
    
    /// 取得完整的輸入文字 => textField(_:shouldChangeCharactersIn:replacementString:)
    /// - Parameters:
    ///   - range: NSRange
    ///   - string: String
    /// - Returns: String?
    func _keyInText(shouldChangeCharactersIn range: NSRange, replacementString string: String) -> String? {
        
        guard let currentText = text,
              let stringRange = Range(range, in: currentText)
        else {
            return nil
        }
        
        return currentText.replacingCharacters(in: stringRange, with: string)
    }
}

// MARK: - UITabBar (static function)
extension UITabBar {
    
    /// 透明背景 (透明底線)
    /// - application(_:didFinishLaunchingWithOptions:)
    static func _transparent() { self.appearance()._transparent() }
}

// MARK: - UITabBar (function)
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

// MARK: - UISearchBar (function)
extension UISearchBar {
    
    /// [SearchBar的背景樣式調整](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/uisearchbar-的樣式調整-763767570b11)
    /// - Parameters:
    ///   - style: UISearchBar.Style
    func _searchBarStyle(with style: UISearchBar.Style = .default) { self.searchBarStyle = style }
}

// MARK: - UIScrollView (function)
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

// MARK: - UITableView (function)
extension UITableView {
    
    /// 初始化Protocal
    /// - Parameters:
    ///   - this: UITableViewDelegate & UITableViewDataSource
    ///   - isFooterViewHidden: 要不要隱藏空Cell
    ///   - isPrefetchingEnabled: 要不要預先處理資料
    func _delegateAndDataSource(with this: UITableViewDelegate & UITableViewDataSource, isFooterViewHidden: Bool = true, isPrefetchingEnabled: Bool = false) {
        
        self.delegate = this
        self.dataSource = this
                
        if (isFooterViewHidden) { self._tableFooterViewHidden() }
        if #available(iOS 15.0, *) { self._isPrefetchingEnabled(isPrefetchingEnabled) }
    }
    
    /// 取得UITableViewCell
    /// - let cell = tableview._reusableCell(at: indexPath) as MyTableViewCell
    /// - Parameter indexPath: IndexPath
    /// - Returns: 符合CellReusable的Cell
    func _reusableCell<T>(at indexPath: IndexPath) -> T where T: UITableViewCell {
        guard let cell = dequeueReusableCell(withIdentifier: "\(T.self)", for: indexPath) as? T else { fatalError("UITableViewCell Error") }
        return cell
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
    
    /// 加強版的scrollToRow => 動畫完成後
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - scrollPosition: UITableView.ScrollPosition
    ///   - completion: (() -> Void)?
    func _scrollToRow(with indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, completion: (() -> Void)?) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        scrollToRow(at: indexPath, at: scrollPosition, animated: true)
        
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
    
    /// 沒有資料的部分不要有分隔線
    func _tableFooterViewHidden() { tableFooterView = UIView() }
    
    /// 修正TableView滿版，而不使用SafeArea的位置問題 (contentInsetAdjustmentBehavior = .never)
    /// => UINavigationBar切換 / 隱藏時會造成Inset變動的問題
    /// - Parameters:
    ///   - height: height
    ///   - indexPath: IndexPath?
    ///   - animated: Bool
    func _fixContentInsetForSafeArea(height: CGFloat, scrollTo indexPath: IndexPath? = nil, animated: Bool = true) {
        _fixContentInsetForSafeArea(top: height, bottom: height, scrollTo: indexPath, animated: animated)
    }
    
    /// 修正TableView滿版，而不使用SafeArea的位置問題 (contentInsetAdjustmentBehavior = .never)
    /// => UINavigationBar切換 / 隱藏時會造成Inset變動的問題
    /// - Parameters:
    ///   - topHeight: CGFloat
    ///   - bottomHeight: CGFloat
    ///   - indexPath: IndexPath?
    ///   - animated: Bool
    func _fixContentInsetForSafeArea(top topHeight: CGFloat, bottom bottomHeight: CGFloat, scrollTo indexPath: IndexPath? = nil, animated: Bool = true) {
        
        contentInsetAdjustmentBehavior = .never
        
        contentInset.top = topHeight
        contentInset.bottom = bottomHeight
        
        if let indexPath = indexPath { scrollToRow(at: indexPath, at: .top, animated: animated) }
    }
    
    /// [設定要不要預先處理資料](https://ithelp.ithome.com.tw/articles/10289725)
    /// - Parameter isEnabled: [Bool](https://ithelp.ithome.com.tw/articles/10289725)
    @available(iOS 15.0, *)
    func _isPrefetchingEnabled(_ isEnabled: Bool = false) {
        self.isPrefetchingEnabled = isEnabled
    }
}

// MARK: - UIRefreshControl (static function)
extension UIRefreshControl {
    
    /// 產生UIRefreshControl
    /// - Parameters:
    ///   - title: 標題
    ///   - target: 要設定的位置
    ///   - action: 向下拉要做什麼？
    ///   - controlEvents: 事件 => 值改變的時候
    ///   - tintColor: UIColor
    ///   - backgroundColor: UIColor
    /// - Returns: UIRefreshControl
    static func _build(title: String? = nil, target: Any?, tintColor: UIColor = .black, backgroundColor: UIColor? = nil, for controlEvents: UIControl.Event = [.valueChanged], action: Selector) -> UIRefreshControl {
        
        let refreshControl = UIRefreshControl()
        
        refreshControl.addTarget(target, action: action, for: controlEvents)
        refreshControl.tintColor = tintColor
        refreshControl.backgroundColor = backgroundColor
        refreshControl._attributedTitle(string: title ?? "", attributes: [.foregroundColor: tintColor])
        
        return refreshControl
    }
}

// MARK: - UIRefreshControl (function)
extension UIRefreshControl {

    /// 設定attributedTitle
    /// - Parameters:
    ///   - string: 文字
    ///   - attributes: 屬性設定
    func _attributedTitle(string: String, attributes: [NSAttributedString.Key : Any] = [:]) {
        self.attributedTitle = NSAttributedString(string: string, attributes: attributes)
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

// MARK: - UICollectionView (function)
extension UICollectionView {
    
    /// 初始化Protocal
    /// - Parameter this: UICollectionViewDelegate & UICollectionViewDataSource
    func _delegateAndDataSource(with this: UICollectionViewDelegate & UICollectionViewDataSource) {
        delegate = this
        dataSource = this
    }
    
    /// [初始化拖放操作Protocal](https://juejin.cn/post/6872696500284686350)
    /// - Parameters:
    ///   - this: [UICollectionViewDragDelegate & UICollectionViewDropDelegate](https://blog.csdn.net/u014029960/article/details/118371984)
    ///   - isDragInteraction: [Bool](https://github.com/pro648/tips/blob/master/sources/UICollectionView及其新功能drag and drop.md)
    func _dragAndDropdelegate(with this: UICollectionViewDragDelegate & UICollectionViewDropDelegate, isDragInteraction: Bool = true) {
        dragDelegate = this
        dropDelegate = this
        dragInteractionEnabled = isDragInteraction
    }
    
    /// 取得UICollectionViewCell
    /// - let cell = collectionView._reusableCell(at: indexPath) as MyCollectionViewCell
    /// - Parameter indexPath: IndexPath
    /// - Returns: 符合CellReusable的Cell
    func _reusableCell<T: CellReusable>(at indexPath: IndexPath) -> T where T: UICollectionViewCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.identifier, for: indexPath) as? T else { fatalError("UICollectionViewCell Error") }
        return cell
    }
    
    /// [資料新增或刪除時的動作設定 - performBatchUpdates() => beginUpdates() + endUpdates()](https://ithelp.ithome.com.tw/articles/10225747)
    /// - Parameters:
    ///   - updates: [((UICollectionView) -> Void)?](https://medium.com/@howardsun/uicollectionview-performbatchupdates-最大的秘密-7fb214c81d17)
    ///   - completion: [((UICollectionView) -> Void)?](https://developer.apple.com/documentation/uikit/uicollectionview/1618045-performbatchupdates)
    func _performBatchUpdates(_ updates: ((UICollectionView) -> Void)?, completion: ((UICollectionView) -> Void)? = nil) {
        
        self.performBatchUpdates {
            updates?(self)
        } completion: { isCompleted in
            if (!isCompleted) { return }
            completion?(self)
        }
    }
}

// MARK: - UIViewController (function)
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

// MARK: - UIAlertController (static function)
extension UIAlertController {
    
    /// 建立UIAlertController
    /// - Parameters:
    ///   - title: String?
    ///   - message: String?
    ///   - tintColor: UIColor
    ///   - preferredStyle: UIAlertController.Style
    /// - Returns: Self
    static func _build(title: String?, message: String?, tintColor: UIColor = .systemBlue, preferredStyle: UIAlertController.Style = .alert) -> Self {
        let alertController = Self(title: title, message: message, preferredStyle: .alert)
        alertController.view.tintColor = tintColor
        return alertController
    }
}

// MARK: - UIDocumentPickerViewController (static function)
extension UIDocumentPickerViewController {
    
    /// [產生UIDocumentPickerViewController](https://www.jianshu.com/p/f34c2688e55b)
    /// - Parameters:
    ///   - delegate: [UIDocumentPickerDelegate](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html)
    ///   - allowedUTIs: [要讀取的檔案類型](https://developer.apple.com/documentation/uniformtypeidentifiers)
    ///   - presentationStyle: 彈出動畫的樣式
    /// - Returns: Self
    static func _build(delegate: (any UIDocumentPickerDelegate)?, allowedUTIs: [UTType], asCopy: Bool = true) -> UIDocumentPickerViewController {
        
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: allowedUTIs, asCopy: asCopy)
        controller.delegate = delegate
        
        return controller
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

// MARK: - WKWebView (function)
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
    
    /// 載入本機HTML檔案
    /// - Parameters:
    ///   - filename: HTML檔案名稱
    ///   - bundle: Bundle位置
    ///   - directory: 資料夾位置
    ///   - readAccessURL: 允許讀取的資料夾位置
    /// - Returns: Result<WKNavigation?, Error>
    func _loadFile(filename: String, bundle: Bundle? = nil, inSubDirectory directory: String? = nil, allowingReadAccessTo readAccessURL: URL? = nil) -> WKNavigation? {
        
        guard let url = (bundle ?? .main).url(forResource: filename, withExtension: nil, subdirectory: directory) else { return nil }
        
        let readAccessURL: URL = readAccessURL ?? url.deletingLastPathComponent()
        return loadFileURL(url, allowingReadAccessTo: readAccessURL)
    }
    
    /// 執行JavaScript
    /// - Parameters:
    ///   - script: JavaScript文字
    ///   - result: Result<Any?, Error>
    func _evaluateJavaScript(script: String?, result: @escaping (Result<Any?, Error>) -> Void) {
        
        guard let script = script else { result(.failure(Constant.CustomError.isEmpty)); return }
        
        self.evaluateJavaScript(script) { data, error in
            if let error = error { result(.failure(error)); return }
            result(.success(data))
        }
    }
    
    /// [禁止使用者去動作 => 不能長按](https://teagan-hsu.coderbridge.io/2020/12/29/how-to-set-css-styles-using-javascript/)
    /// - Parameter result: [Result<Any?, Error>](https://teagan-hsu.coderbridge.io/2020/12/29/how-to-set-css-styles-using-javascript/)
    func _disableUserSelectAndTouch(result: @escaping (Result<Any?, Error>) -> Void) {
        
        let script = """
        (function() {
            let style = document.createElement('style');
            style.innerHTML = `*:not(input,textarea),*:focus:not(input,textarea){-webkit-user-select:none;-webkit-touch-callout:none;}`;
            document.head.appendChild(style);
            return true;
        }());
        """
        
        self._evaluateJavaScript(script: script) { _result in
            
            switch _result {
            case .failure(let error): result(.failure(error))
            case .success(let value): result(.success(value))
            }
        }
    }
    
    /// [禁止使用者縮放 => 不能雙指放大縮小](https://blog.csdn.net/jbj6568839z/article/details/103665222)
    /// - Parameter result: [Result<Any?, Error>](https://stackoverflow.com/questions/18982228/how-to-add-meta-tag-in-javascript)
    func _disableUserScale(result: @escaping (Result<Any?, Error>) -> Void) {
        
        let script = """
        (function() {
            let meta = document.createElement('meta');
            meta.name = `viewport`;
            meta.content = `initial-scale=1.0,maximum-scale=1.0,minimum-scale=1.0,user-scalable=no`;
            document.getElementsByTagName('head')[0].appendChild(meta);
            return true;
        }());
        """
        
        self._evaluateJavaScript(script: script) { _result in
            
            switch _result {
            case .failure(let error): result(.failure(error))
            case .success(let value): result(.success(value))
            }
        }
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
            
            var isHidden = true
            
            progressView.progress = Float(this.estimatedProgress)
            
            if (progressView.progress < 1.0) { isHidden = false }
            progressView.isHidden = isHidden
        }
        
        return observation
    }
}

// MARK: - HTTPURLResponse
extension HTTPURLResponse {
    
    /// 取得其中一個Field
    /// - Parameter key: AnyHashable
    /// - Returns: Any?
    func _headerField(for key: AnyHashable) -> Any? {
        return self.allHeaderFields[key]
    }
    
    /// 取得其中一個Field
    /// - Parameter key: HTTPHeaderField
    /// - Returns: Any?
    func _headerField(with key: WWNetworking.HTTPHeaderField) -> Any? {
        return self._headerField(for: key.rawValue)
    }
}

// MARK: - UIColorPickerViewController (static function)
extension UIColorPickerViewController {
    
    /// [產生UIColorPickerViewController](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/ios-sdk-選東西的-view-controller-delegate-範例-c3f0b5238933)
    /// - Parameters:
    ///   - delegate: UIColorPickerViewControllerDelegate?
    ///   - supportsAlpha: Bool
    ///   - selectedColor: UIColor?
    /// - Returns: UIColorPickerViewController
    static func _build(delegate: UIColorPickerViewControllerDelegate?, supportsAlpha: Bool = false, selectedColor: UIColor? = nil) -> UIColorPickerViewController {
        
        let controller = UIColorPickerViewController()
        
        controller.delegate = delegate
        controller.supportsAlpha = supportsAlpha
        controller.selectedColor = selectedColor ?? controller.selectedColor
        
        return controller
    }
}

// MARK: - PKToolPicker (static function)
extension PKToolPicker {
    
    /// [產生Pancel工具列 => 要留著全域的](https://developer.apple.com/videos/play/wwdc2020/10107/)
    /// - Parameters:
    ///   - window: [UIWindow](https://developer.apple.com/videos/play/wwdc2019/221/)
    ///   - canvasView: PKCanvasView
    /// - Returns: PKToolPicker?
    static func _build(with canvasView: PKCanvasView) -> PKToolPicker {
        
        let toolPicker = PKToolPicker()
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        
        return toolPicker
    }
}

// MARK: - PKCanvasView (static function)
extension PKCanvasView {
    
    /// [產生Pencel畫布](https://youtu.be/PkJ9dB-Ou_w)
    /// - Parameters:
    ///   - view: [要顯示哪一個View上面？](https://www.youtube.com/watch?v=f2SHsHsjTGM)
    ///   - backgroundColor: 背景色
    ///   - isOpaque: 背景的isOpaque = true，才可以讓背景看得到，但是效能↓
    ///   - drawing: PKDrawing
    ///   - drawingPolicy: 畫筆的使用權 (用筆畫？用手畫？)
    ///   - delegate: PKCanvasViewDelegate
    /// - Returns: PKCanvasView
    static func _build(onView view: UIView, backgroundColor: UIColor = .black.withAlphaComponent(0.3), isOpaque: Bool = false, drawing: PKDrawing = PKDrawing(), drawingPolicy: PKCanvasViewDrawingPolicy = .default, delegate: PKCanvasViewDelegate? = nil) -> PKCanvasView {
        
        let canvasView = PKCanvasView()
        
        canvasView.delegate = delegate
        canvasView.drawing = drawing
        canvasView.backgroundColor = backgroundColor
        canvasView.drawingPolicy = .default
        canvasView.isOpaque = isOpaque
        
        canvasView.alwaysBounceVertical = false
        canvasView.alwaysBounceHorizontal = false
        canvasView._autolayout(on: view)

        return canvasView
    }
}

// MARK: - PKCanvasView (function)
extension PKCanvasView {
    
    /// [清除畫布](https://stackoverflow.com/questions/56683060/removing-content-in-pencilkit)
    func _clear() { drawing = PKDrawing() }
}

// MARK: - UIViewController (static function)
extension UIApplicationShortcutItem {
    
    /// [產生QuickActions選單 (APP圖示長按出現的選單)](https://blog.csdn.net/soindy/article/details/49995573)
    /// - [applicationWillResignActive(_:) / application(_:performActionFor:completionHandler:)](https://blog.csdn.net/soindy/article/details/49995573)
    /// - [sceneWillResignActive(_:) / windowScene(_:performActionFor:completionHandler:)](https://bjdehang.github.io/OneSwift/articles/14.Swift如何给应用添加3D_Touch菜单.html)
    /// - Parameters:
    ///   - type: type = "DynamicAction"
    ///   - localizedTitle: [顯示的主標題](https://www.jianshu.com/p/3024e997b457)
    ///   - localizedSubtitle: 顯示的副標題
    ///   - icon: 圖示
    ///   - userInfo: 其它的資訊
    /// - Returns: UIApplicationShortcutItem
    static func _build(type: String = "DynamicAction", localizedTitle: String, localizedSubtitle: String? = nil, icon: UIApplicationShortcutIcon? = nil, userInfo: [String : NSSecureCoding]? = nil) -> UIApplicationShortcutItem {
        let shortcutItem = UIApplicationShortcutItem(type: type, localizedTitle: localizedTitle, localizedSubtitle: localizedSubtitle, icon: icon, userInfo: userInfo)
        return shortcutItem
    }
}
