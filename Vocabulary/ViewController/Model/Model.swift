//
//  Model.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import AVFoundation
import WWSQLite3Manager
import WWHash

// MARK: - Settings.json設定檔Model
final class Settings {
        
    // MARK: - 一般般設定
    struct GeneralInformation: Decodable {
        
        var key: String                 // 字碼代號
        var code: String                // 國別簡寫 (US)
        var voice: String               // 語音代碼 (en-US)
        var name: String                // 顯示名稱
        var value: Int                  // 資料庫數值
        var font: String                // 語言字型 (Bradley Hand)
        var dictionaryURL: String       // 語言字典URL
        var defineURL: String           // 語言定義URL
    }
    
    // MARK: - 單字等級設定
    struct VocabularyLevelInformation: Decodable, ColorSettings {
        
        var key: String                 // 英文代碼
        var name: String                // 顯示名稱
        var value: Int                  // 資料庫數值
        var backgroundColor: String     // 背景顏色
        var color: String               // 文字顏色
        var guessCount: Int             // 複習題數量
    }

    // MARK: - 精選例句類型設定
    struct SentenceSpeechInformation: Decodable, ColorSettings {
        
        var key: String                 // 英文代碼
        var name: String                // 顯示名稱
        var value: Int                  // 資料庫數值
        var backgroundColor: String     // 背景顏色
        var color: String               // 文字顏色
    }
    
    // MARK: - 單字詞性類型設定 (Settings.json)
    struct WordSpeechInformation: Decodable, ColorSettings {
        
        var key: String                 // 英文代碼
        var name: String                // 顯示名稱
        var value: Int                  // 資料庫數值
        var backgroundColor: String     // 背景顏色
        var color: String               // 文字顏色
    }
    
    // MARK: - HUD動畫類型設定 (Settings.json)
    struct AnimationInformation: Decodable, ColorSettings, AnimationSettings {
        
        var key: String                 // 英文代碼
        var name: String                // 顯示名稱
        var value: Int                  // 資料庫數值
        var backgroundColor: String     // 背景顏色
        var color: String               // 文字顏色
        var filename: String            // 檔案名稱
    }
    
    // MARK: - 背景動畫類型設定 (Settings.json)
    struct BackgroundInformation: Decodable, ColorSettings, AnimationSettings {
        
        var key: String                 // 英文代碼
        var name: String                // 顯示名稱
        var value: Int                  // 資料庫數值
        var backgroundColor: String     // 背景顏色
        var color: String               // 文字顏色
        var filename: String            // 檔案名稱
    }
}

// MARK: - 單字內容
final class Vocabulary: Codable {
    
    let id: Int             // 編號
    let speech: Int         // 詞性
    let word: String        // 單字
    let hardwork: Int?      // 翻譯難度 (有讀過了嗎？)
    let interpret: String?  // 單字翻譯
    let example: String?    // 例句範例
    let translate: String?  // 例句翻譯
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 單字列表內容
final class VocabularyList: Codable {
    
    let id: Int             // 編號
    let level: Int          // 難度等級
    let count: Int          // 單字內容數量
    let review: Int         // 複習的次數
    let word: String        // 單字
    let alphabet: String?   // 音標字母
    let favorite: Int?      // 我的最愛
    let similar: String?    // 相似字 (JSON)
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 單字複習列表
final class VocabularyReviewList: Codable {
    
    let id: Int             // 編號
    let word: String        // 單字
    let correctCount: Int   // 答對的次數
    let mistakeCount: Int   // 答錯的次數
    let wordId: Int         // 列表單字編號
    let favorite: Int?      // 我的最愛
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 單字例句列表
final class VocabularySentenceList: Codable {
    
    let id: Int             // 編號
    let example: String?    // 例句範例
    let translate: String?  // 例句翻譯
    let speech: Int         // 詞性
    let favorite: Int?      // 我的最愛
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 網址書籤
final class BookmarkSite: Codable {
    
    let id: Int             // 編號
    let title: String       // 書籤標題
    let url: String         // 書籤網址
    let icon: String?       // 書籤圖示網址
    let favorite: Int?      // 我的最愛
    let createTime: Date    // 建立時間
    let updateTime: Date    // 更新時間
    
    /// 圖示檔的名稱 (SHA1)
    /// - Returns: String
    func iconName() -> String { return WWHash.sha1.encode(string: url) }
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 背景音樂
struct Music {
    
    let filename: String    // 檔案名稱
    
    /// 音樂檔案路徑
    /// - Returns: URL?
    func fileURL() -> URL? {
        let musicFolderUrl = Constant.FileFolder.music.url()
        return musicFolderUrl?._appendPath(filename)
    }
    
    /// 音樂檔案類型
    /// - Returns: AVFileType
    func fileType() -> AVFileType {
        
        guard let components = Optional.some(filename.components(separatedBy: ".")),
              components.count > 1,
              let extensionName = components.last
        else {
            return .mp3
        }
        
        if (extensionName.lowercased() == "mp3") { return .mp3 }
        if (extensionName.lowercased() == "m4a") { return .m4a }
        
        return .mp3
    }
}

// MARK: - 相似字
struct SimilarWord {
    let word: String    // 單字
    let level: Int      // 等級
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
            (key: "hardwork", type: .INTEGER()),
            (key: "interpret", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "example", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "translate", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
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
            (key: "similar", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "favorite", type: .INTEGER()),
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
            (key: "wordId", type: .INTEGER()),
            (key: "favorite", type: .INTEGER()),
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
            (key: "favorite", type: .INTEGER()),
            (key: "createTime", type: .TIMESTAMP()),
            (key: "updateTime", type: .TIMESTAMP()),
        ]
        
        return keyTypes
    }
}

// MARK: - SQLite3SchemeDelegate
extension BookmarkSite: SQLite3SchemeDelegate {
    
    /// SQLite資料結構 for WWSQLite3Manager
    /// - Returns: [(key: String, type: SQLite3Condition.DataType)]
    static func structure() -> [(key: String, type: SQLite3Condition.DataType)] {
        
        let keyTypes: [(key: String, type: SQLite3Condition.DataType)] = [
            (key: "id", type: .INTEGER()),
            (key: "title", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "url", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "icon", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "favorite", type: .INTEGER()),
            (key: "createTime", type: .TIMESTAMP()),
            (key: "updateTime", type: .TIMESTAMP()),
        ]
        
        return keyTypes
    }
}
