//
//  Constant.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import WWSQLite3Manager

// MARK: - Constant
final class Constant: NSObject {
    
    static let databaseName = "Vocabulary.db"
    static let duration: TimeInterval = 0.15
    static let notificationName = Notification._name("RefreshViewController")
    static let updateScrolledHeight: CGFloat = 80.0
    static let searchCountWithLevel: SearchCountWithLevel = [.easy: 3, .medium: 4, .hard: 3]

    static var database: SQLite3Database?
    static var currentTableName: Constant.VoiceCode = .english { didSet { NotificationCenter.default._post(name: Constant.notificationName) }}
    static var volume: Float = 0.1
    static var musicFolderUrl: URL? { get { return FileManager.default._documentDirectory()?.appendingPathComponent("Music", isDirectory: false) }}
    static var imageFolderUrl: URL? { get { return FileManager.default._documentDirectory()?.appendingPathComponent("Image", isDirectory: false) }}
}

// MARK: - Typealias
extension Constant {
    
    typealias ExampleInfomation = (id: Int, interpret: String, example: String, translate: String)      // 單字ID / 字義 / 例句 / 例句翻譯
    typealias GIFImageInformation = (index: Int, cgImage: CGImage, pointer: UnsafeMutablePointer<Bool>) // GIF動畫: (第幾張, CGImage, UnsafeMutablePointer<Bool>)
    typealias SearchCountWithLevel = [Vocabulary.Level: Int]                                            // 複習單字的數量
    typealias FileInfomation = (isExist: Bool, isDirectory: Bool)                                       // 檔案相關資訊 (是否存在 / 是否為資料夾)
}

// MARK: - Enumeration
extension Constant {
    
    /// ScrollView滾動的方向
    enum ScrollDirection {
        case none
        case up
        case down
        case left
        case right
    }
    
    // MARK: - 單字內容的資料庫名稱
    enum VoiceCode: String, CaseIterable {
        
        case english = "English"
        case japanese = "Japenese"
        case korean = "Korean"
        case chinese = "Chinese"
        
        /// 單字列表的資料庫名稱 => EnglishList
        /// - Returns: String
        func vocabularyList() -> String { return "\(self.rawValue)List" }
        
        /// 複習單字列表的資料庫名稱 => EnglishReview
        /// - Returns: String
        func vocabularyReviewList() -> String { return "\(self.rawValue)Review" }
        
        /// 常用例句的資料庫名稱 => EnglishSentence
        /// - Returns: String
        func vocabularySentenceList() -> String { return "\(self.rawValue)Sentence" }
        
        /// 常用書籤
        /// - Returns: String
        func bookmarks() -> String { return "\(self.rawValue)BookmarkSite" }
        
        /// [AVSpeechSynthesisVoice List](https://stackoverflow.com/questions/35492386/how-to-get-a-list-of-all-voices-on-ios-9/43576853)
        /// - Returns: String
        func code() -> String {
            switch self {
            case .english: return "en-US"
            case .japanese: return "ja-JP"
            case .korean: return "ko-KR"
            case .chinese: return "zh-TW"
            }
        }
        
        /// 線上字典的URL
        /// - Parameter word: 要查詢的單字
        /// - Returns: String
        func dictionaryURL(with word: String) -> String {
            
            switch self {
            case .english: return "https://tw.dictionary.search.yahoo.com/search?p=\(word)"
            case .japanese: return "https://dictionary.goo.ne.jp/word/\(word)"
            case .korean: return "https://dic.daum.net/search.do?dic=ch&q=\(word)"
            case .chinese: return "https://cdict.net/?q=\(word)"
            }
        }
        
        /// 字典名稱
        func name() -> String {
            
            switch self {
            case .english: return "\(flagEmoji()) 英文字典"
            case .japanese: return "\(flagEmoji()) 日文字典"
            case .korean: return "\(flagEmoji()) 韓文字典"
            case .chinese: return "\(flagEmoji()) 中文字典"
            }
        }
        
        /// 國旗顏文字
        /// - Returns: String
        func flagEmoji() -> String {
            
            switch self {
            case .english: return "US"._flagEmoji()
            case .japanese: return "JP"._flagEmoji()
            case .korean: return "KR"._flagEmoji()
            case .chinese: return "TW"._flagEmoji()
            }
        }
        
        /// 字型
        /// - Returns: UIFont?
        func font(size fontSize: CGFloat = 36.0) -> UIFont? {
            
            switch self {
            case .english: return UIFont(name: "Bradley Hand", size: fontSize)
            case .japanese: return UIFont(name: "KleeOne-SemiBold", size: fontSize)
            case .korean: return UIFont(name: "GamjaFlower-Regular", size: fontSize)
            case .chinese: return UIFont(name: "jf-openhuninn-1.1.ttf", size: fontSize)
            }
        }
    }
    
    // MARK: - 自定義錯誤
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }
        
        case notOpenURL
        case notImage
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {
            switch self {
            case .notOpenURL: return "打開URL錯誤"
            case .notImage: return "不是圖片檔"
            }
        }
    }
}
