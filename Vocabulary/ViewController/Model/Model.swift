//
//  Model.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import WWPrint
import WWSQLite3Manager

// MARK: - 單字內容
final class Vocabulary: Codable {
    
    // 單字難度等級
    public enum Level: Int, CaseIterable {
        
        case easy = 0
        case medium = 1
        case hard = 2
        
        /// 單字等級
        func value() -> String {
            switch self {
            case .easy: return "簡單"
            case .medium: return "一般"
            case .hard: return "困難"
            }
        }
        
        /// 等級背景色
        /// - Returns: UIColor
        func backgroundColor() -> UIColor {
            
            switch self {
            case .easy: return .systemGreen
            case .medium: return .systemBlue
            case .hard: return .systemRed
            }
        }
    }
    
    // 單字詞性
    public enum Speech: Int, CaseIterable {
        
        case noue = 000
        case pronoue = 001
        case verb = 002
        case adverb = 003
        case adjective = 004
        case preposition = 005
        case conjunction = 006
        case determiner = 007
        case interjection = 008
        case numeral = 009
        case phrase = 010
        case addreviation = 011
        
        /// [語言詞性](https://boroenglish.com/詞性縮寫總整理/)
        /// - Returns: String
        func value() -> String {
            
            switch self {
            case .noue: return "名詞"
            case .pronoue: return "代名詞"
            case .verb: return "動詞"
            case .adverb: return "副詞"
            case .adjective: return "形容詞"
            case .preposition: return "介系詞"
            case .conjunction: return "連接詞"
            case .determiner: return "限定詞"
            case .interjection: return "感嘆詞"
            case .numeral: return "數詞"
            case .phrase: return "片語"
            case .addreviation: return "縮寫"
            }
        }
        
        /// 詞性背景色
        /// - Returns: UIColor
        func backgroundColor() -> UIColor {
            
            switch self {
            case .noue: return .systemGray
            case .pronoue: return .systemBlue
            case .verb: return .systemRed
            case .adverb: return .black
            case .adjective: return .systemOrange
            case .preposition: return .systemBrown
            case .conjunction: return .darkGray
            case .determiner: return .systemGray
            case .interjection: return .systemIndigo
            case .numeral: return .systemBlue
            case .phrase: return .darkGray
            case .addreviation: return .systemGray
            }
        }
    }
    
    let id: Int             // 編號
    let speech: Int         // 詞性
    let word: String        // 單字
    let interpret: String?  // 單字翻譯
    let example: String?    // 例句範例
    let translate: String?  // 例句翻譯
    let imageUrl: String?   // 圖片網址
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - 單字列表內容
final class VocabularyList: Codable {
    
    let id: Int             // 編號
    let level: Int          // 難度等級
    let count: Int          // 單字內容數量
    let review: Int         // 複習的次數
    let word: String        // 單字
    let alphabet: String?   // 音標
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - 單字複習列表
final class VocabularyReviewList: Codable {
    
    let id: Int             // 編號
    let word: String        // 單字
    let correctCount: Int   // 答對的次數
    let mistakeCount: Int   // 答錯的次數
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - 單字例句列表
final class VocabularySentenceList: Codable {
    
    let id: Int             // 編號
    let example: String?    // 例句範例
    let translate: String?  // 例句翻譯
    let speech: Int         // 詞性
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    deinit { wwPrint("\(Self.self) deinit") }
    
    // 例句詞性
    public enum Speech: Int, CaseIterable {
        
        case general = 000
        case proverb = 001
        case movie = 002
        case article = 003
        case locution = 004
        case celebrity = 005
        case slang = 006
        
        /// 例句詞性
        /// - Returns: String
        func value() -> String {
            
            switch self {
            case .general: return "一般"
            case .proverb: return "諺語"
            case .movie: return "電影"
            case .article: return "文章"
            case .locution: return "慣用語"
            case .celebrity: return "名人"
            case .slang: return "俚語"
            }
        }
        
        /// 詞性背景色
        /// - Returns: UIColor
        func backgroundColor() -> UIColor {
            
            switch self {
            case .general: return .systemGray
            case .proverb: return .systemRed
            case .movie: return .systemBlue
            case .article: return .systemOrange
            case .locution: return .systemGreen
            case .celebrity: return .darkGray
            case .slang: return .systemIndigo
            }
        }
    }
}

// MARK: - SQLite3SchemeDelegate
extension Vocabulary: SQLite3SchemeDelegate {
    
    /// SQLite資料結構 for WWSQLite3Manager
    /// - Returns: [(key: String, type: SQLite3Condition.DataType)]
    static func structure() -> [(key: String, type: SQLite3Condition.DataType)] {
        
        let keyTypes: [(key: String, type: SQLite3Condition.DataType)] = [
            (key: "id", type: .INTEGER()),
            (key: "speech", type: .INTEGER()),
            (key: "word", type: .TEXT(attribute: (isNotNull: true, isNoCase: true, isUnique: false), defaultValue: nil)),
            (key: "interpret", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "example", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "translate", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "imageUrl", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "createTime", type: .TIMESTAMP()),
            (key: "updateTime", type: .TIMESTAMP()),
        ]
        
        return keyTypes
    }
}

// MARK: - SQLite3SchemeDelegate
extension VocabularyList: SQLite3SchemeDelegate {

    /// SQLite資料結構 for WWSQLite3Manager
    /// - Returns: [(key: String, type: SQLite3Condition.DataType)]
    static func structure() -> [(key: String, type: SQLite3Condition.DataType)] {
        
        let keyTypes: [(key: String, type: SQLite3Condition.DataType)] = [
            (key: "id", type: .INTEGER()),
            (key: "level", type: .INTEGER()),
            (key: "count", type: .INTEGER()),
            (key: "review", type: .INTEGER()),
            (key: "word", type: .TEXT(attribute: (isNotNull: true, isNoCase: true, isUnique: true), defaultValue: nil)),
            (key: "alphabet", type: .TEXT(attribute: (isNotNull: false, isNoCase: true, isUnique: false), defaultValue: nil)),
            (key: "createTime", type: .TIMESTAMP()),
            (key: "updateTime", type: .TIMESTAMP()),
        ]
        
        return keyTypes
    }
}

// MARK: - SQLite3SchemeDelegate
extension VocabularyReviewList: SQLite3SchemeDelegate {
    
    /// SQLite資料結構 for WWSQLite3Manager
    /// - Returns: [(key: String, type: SQLite3Condition.DataType)]
    static func structure() -> [(key: String, type: SQLite3Condition.DataType)] {
        
        let keyTypes: [(key: String, type: SQLite3Condition.DataType)] = [
            (key: "id", type: .INTEGER()),
            (key: "word", type: .TEXT(attribute: (isNotNull: true, isNoCase: true, isUnique: true), defaultValue: nil)),
            (key: "correctCount", type: .INTEGER()),
            (key: "mistakeCount", type: .INTEGER()),
            (key: "createTime", type: .TIMESTAMP()),
            (key: "updateTime", type: .TIMESTAMP()),
        ]
        
        return keyTypes
    }
}

// MARK: - SQLite3SchemeDelegate
extension VocabularySentenceList: SQLite3SchemeDelegate {
    
    /// SQLite資料結構 for WWSQLite3Manager
    /// - Returns: [(key: String, type: SQLite3Condition.DataType)]
    static func structure() -> [(key: String, type: SQLite3Condition.DataType)] {
        
        let keyTypes: [(key: String, type: SQLite3Condition.DataType)] = [
            (key: "id", type: .INTEGER()),
            (key: "speech", type: .INTEGER()),
            (key: "example", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "translate", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "createTime", type: .TIMESTAMP()),
            (key: "updateTime", type: .TIMESTAMP()),
        ]
        
        return keyTypes
    }
}
