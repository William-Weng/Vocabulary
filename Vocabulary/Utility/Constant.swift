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
    
    static let duration: TimeInterval = 0.15
    static let updateScrolledHeight: CGFloat = 96.0
    static let databaseName = "Vocabulary.db"
    static let databaseFileExtension = "db"
    static let autoBackupDays = 7
    static let autoBackupDelaySecond: TimeInterval = 2
    static let searchCountWithLevel: SearchCountWithLevel = [.easy: 3, .medium: 4, .hard: 3]
    
    static var volume: Float = 0.1
    static var speakingSpeed: Float = 0.4
    static var database: SQLite3Database?
    
    static var backupDirectory = FileManager.default._documentDirectory()
    static var currentTableName: Constant.VoiceCode = .english { didSet { NotificationCenter.default._post(name: .refreshViewController) }}
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
    
    /// [info.plist上的Key值](https://ithelp.ithome.com.tw/articles/10206444)
    enum InfoPlistKey: String {
        case CFBundleShortVersionString = "CFBundleShortVersionString"      // Version版本號 => 1.0.0
        case CFBundleVersion = "CFBundleVersion"                            // Build的代號 => 202001011
    }
    
    // MARK: - 單字內容的資料庫名稱
    enum VoiceCode: String, CaseIterable {
        
        case english = "English"
        case japanese = "Japenese"
        case french = "French"
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
        
        /// 常用書籤 => EnglishBookmarkSite
        /// - Returns: String
        func bookmarks() -> String { return "\(self.rawValue)BookmarkSite" }
        
        /// [AVSpeechSynthesisVoice List](https://stackoverflow.com/questions/35492386/how-to-get-a-list-of-all-voices-on-ios-9/43576853)
        /// - Returns: String
        func code() -> String {
            switch self {
            case .english: return "en-US"
            case .japanese: return "ja-JP"
            case .french: return "fr-FR"
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
            case .french: return "https://www.frdic.com/dicts/fr/\(word)"
            case .korean: return "https://dic.daum.net/search.do?dic=ch&q=\(word)"
            case .chinese: return "https://cdict.net/?q=\(word)"
            }
        }
        
        /// 字典名稱
        /// - Returns: String
        func name() -> String {
            
            switch self {
            case .english: return "\(flagEmoji()) 英文字典"
            case .japanese: return "\(flagEmoji()) 日文字典"
            case .french: return "\(flagEmoji()) 法文字典"
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
            case .french: return "FR"._flagEmoji()
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
            case .french: return UIFont(name: "Bradley Hand", size: fontSize)
            case .korean: return UIFont(name: "GamjaFlower-Regular", size: fontSize)
            case .chinese: return UIFont(name: "jf-openhuninn-1.1", size: fontSize)
            }
        }
        
        /// 分類 / 分組號碼 (0xx / 1xx / 2xx / ...)
        /// => 要跟Vocabulary.Speech配合
        /// - Returns: Int
        func groupNumber() -> Int {
            switch self {
            case .english: return 000
            case .japanese: return 100
            case .french: return 200
            case .korean: return 000
            case .chinese: return 000
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
    
    // MARK: - 問題等級
    enum QuestionLevel: CaseIterable {
        
        case read       // 看到中文解譯
        case listen     // 聽到外文語句
        
        /// 文字顏色
        /// - Returns: UIColor
        func color() -> UIColor {
            switch self {
            case .read: return .darkText
            case .listen: return .clear
            }
        }
        
        /// 顯示Title
        /// - Returns: String
        func value() -> String {
            switch self {
            case .read: return "單字翻譯"
            case .listen: return "例句閱讀"
            }
        }
    }
    
    /// 通知的名稱
    enum NotificationName: String {
        
        case refreshViewController = "RefreshViewController"
        case viewDidTransition = "ViewDidTransition"
        case displayCanvasView = "DisplayCanvasView"
        
        /// 產生Notification.Name
        /// - Returns: Notification.Name
        func name() -> Notification.Name { return Notification._name(self.rawValue) }
    }
    
    /// 外部的資料夾路徑 => ./Documents/Music
    enum FileFolder: String {
        
        case image = "Image"
        case music = "Music"
        case animation = "Animation"
        
        /// 產生URL
        /// - Returns: URL?
        func url() -> URL? { return FileManager.default._documentDirectory()?.appendingPathComponent(self.rawValue, isDirectory: false) }
    }
    
    /// 要搜尋的類型分類
    enum SearchType: Int, CaseIterable, CustomStringConvertible {
        
        var description: String { toString() }
        
        case word = 0
        case interpret = 1
        
        /// 轉成中文字
        /// - Returns: String
        func toString() -> String {
            switch self {
            case .word: return "單字"
            case .interpret: return "字義"
            }
        }
        
        /// 轉成欄位名稱
        /// - Returns: String
        func field() -> String {
            switch self {
            case .word: return "word"
            case .interpret: return "interpret"
            }
        }
        
        /// 背景色
        /// - Returns: UIColor
        func backgroundColor() -> UIColor {
            switch self {
            case .word: return .darkGray
            case .interpret: return .systemBlue
            }
        }
    }
}
