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
    static let duration: TimeInterval = 0.2
    static let notificationName = Notification._name("RefreshViewController")
    
    static var database: SQLite3Database?
    static var currentTableName: Constant.VoiceCode = .english { didSet { NotificationCenter.default._post(name: Constant.notificationName) }}
    static var volume: Float = 0.1
}

// MARK: - Typealias
extension Constant {
    typealias ExampleInfomation = (id: Int, interpret: String, example: String, translate: String)      // 單字ID / 字義 / 例句 / 例句翻譯
    typealias GIFImageInformation = (index: Int, cgImage: CGImage, pointer: UnsafeMutablePointer<Bool>) // GIF動畫: (第幾張, CGImage, UnsafeMutablePointer<Bool>)
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
    
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }
        
        case notOpenURL
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {
            switch self {
            case .notOpenURL: return "打開URL錯誤"
            }
        }
    }
}
