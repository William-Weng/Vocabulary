//
//  API.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import UIKit
import WWSQLite3Manager
import WWPrint

// MARK: - API (單例)
final class API: NSObject {
    
    static let shared = API()
    private override init() {}
}

// MARK: - 小工具 (Search)
extension API {
    
    /// 單字搜尋
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    /// - Returns: [[String : Any]]
    func searchWord(_ word: String, for tableName: Constant.VoiceCode) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let condition = SQLite3Condition.Where().isCompare(key: "word", type: .equal, value: word)
        let orderBy = SQLite3Condition.OrderBy().item(key: "createTime", type: .ascending)
        let result = database.select(tableName: tableName.rawValue, type: Vocabulary.self, where: condition, orderBy: orderBy, limit: nil)
        
        return result.array
    }
    
    /// 搜尋單字列表
    /// - Parameters:
    ///   - tableName: 資料表名稱
    ///   - count: 單次搜尋的數量
    ///   - offset: 搜尋的偏移量
    /// - Returns: [[String : Any]]
    func searchVocabularyList(for tableName: Constant.VoiceCode, count: Int = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let orderBy = SQLite3Condition.OrderBy().item(key: "updateTime", type: .descending)
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        let result = database.select(tableName: tableName.vocabularyList(), type: VocabularyList.self, where: nil, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    /// 搜尋單字內容列表
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    /// - Returns: [[String : Any]]
    func searchWordList(_ word: String, for tableName: Constant.VoiceCode) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let condition = SQLite3Condition.Where().isCompare(key: "word", type: .equal, value: word)
        let orderBy = SQLite3Condition.OrderBy().item(key: "createTime", type: .ascending)
        let result = database.select(tableName: tableName.rawValue, type: Vocabulary.self, where: condition, orderBy: orderBy, limit: nil)
        
        return result.array
    }
    
    ///  搜尋相似單字內容列表
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    ///   - count: 單次搜尋的數量
    ///   - offset: 搜尋的偏移量
    /// - Returns: [[String : Any]]
    func searchWordList(like word: String, for tableName: Constant.VoiceCode, count: Int = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let condition = SQLite3Condition.Where().like(key: "word", condition: "\(word)%")
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        let orderBy = SQLite3Condition.OrderBy().item(key: "word", type: .ascending)
        let result = database.select(tableName: tableName.vocabularyList(), type: VocabularyList.self, where: condition, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    func searchWordDetail(in words: [String], for tableName: Constant.VoiceCode, count: Int = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database,
              !words.isEmpty
        else {
            return []
        }
        
        let condition = SQLite3Condition.Where().in(key: "word", values: words)
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        let orderBy = SQLite3Condition.OrderBy().item(key: "word", type: .ascending)
        let result = database.select(tableName: "\(tableName)", type: Vocabulary.self, where: condition, orderBy: orderBy, limit: limit)
        
        return result.array
    }
}

// MARK: - 小工具 (Insert)
extension API {
    
    /// 新增單字
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    /// - Returns: 單字列表數量
    func insertNewWord(_ word: String, for tableName: Constant.VoiceCode) -> Int? {
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "word", value: word),
            (key: "speech", value: Vocabulary.Speech.noue.rawValue),
        ]
        
        guard let database = Constant.database,
              let isSussess = database.insert(tableName: tableName.rawValue, itemsArray: [items])?.isSussess,
              isSussess == true
        else {
            return nil
        }
        
        let count = searchWord(word, for: tableName).count
        return count
    }
    
    /// 新增單字到列表
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func insertWordToList(_ word: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "word", value: word),
            (key: "count", value: 1),
            (key: "level", value: Vocabulary.Level.medium.rawValue),
        ]
        
        let result = database.insert(tableName: tableName.vocabularyList(), itemsArray: [items])
        return result?.isSussess ?? false
    }
}

// MARK: - 小工具 (Update)
extension API {
    
    /// 更新單字例句數量
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    ///   - count: 例句數量
    ///   - hasUpdateTime: 要不要加上更新時間
    /// - Returns: Bool
    func updateWordToList(_ word: String, for tableName: Constant.VoiceCode, count: Int, hasUpdateTime: Bool = true) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        var items: [SQLite3Database.InsertItem] = [
            (key: "count", value: count),
        ]
        
        if (hasUpdateTime) { items.append(SQLite3Database.InsertItem((key: "updateTime", value: Date()._localTime()))) }
        
        let condition = SQLite3Condition.Where().isCompare(key: "word", type: .equal, value: word)
        let result = database.update(tableName: tableName.vocabularyList(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字音標
    /// - Parameters:
    ///   - id: Int
    ///   - alphabet: 音標
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateAlphabetToList(_ id: Int, alphabet: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "alphabet", value: alphabet),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.vocabularyList(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字範例相關內容
    /// - Parameters:
    ///   - id: Int
    ///   - alphabet: 音標
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateExmapleToList(_ id: Int, info: Constant.ExampleInfomation, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "interpret", value: info.interpret),
            (key: "example", value: info.example),
            (key: "translate", value: info.translate),
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.rawValue, items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字詞性
    /// - Parameters:
    ///   - id: Int
    ///   - speech: 詞性
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateSpeechToList(_ id: Int, speech: Vocabulary.Speech, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "speech", value: speech.rawValue),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.rawValue, items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字等級
    /// - Parameters:
    ///   - id: Int
    ///   - level: 等級
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateLevelToList(_ id: Int, level: Vocabulary.Level, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "level", value: level.rawValue),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.vocabularyList(), items: items, where: condition)
        
        return result.isSussess
    }
}

// MARK: - 小工具 (Delete)
extension API {
    
    /// 刪除單字範例
    /// - Parameters:
    ///   - id: Int
    ///   - tableName: Constant.VoiceCode
    /// - Returns: Bool
    func deleteWord(with id: Int, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.delete(tableName: tableName.rawValue, where: condition)
        
        return result.isSussess
    }
    
    /// 刪除列表單字
    /// - Parameters:
    ///   - id: Int
    ///   - tableName: Constant.VoiceCode
    /// - Returns: Bool
    func deleteWordList(with id: Int, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.delete(tableName: tableName.vocabularyList(), where: condition)
        
        return result.isSussess
    }
}
