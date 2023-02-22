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
    ///   - words: 特定單字群
    ///   - tableName: 資料表名稱
    ///   - count: 單次搜尋的數量
    ///   - offset: 搜尋的偏移量
    /// - Returns: [[String : Any]]
    func searchVocabularyList(in words: [String]? = nil, for tableName: Constant.VoiceCode, count: Int = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        var condition: SQLite3Condition.Where?
        let orderBy = SQLite3Condition.OrderBy().item(key: "updateTime", type: .descending)
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        
        if let words = words, !words.isEmpty { condition = SQLite3Condition.Where().in(key: "word", values: words) }
        
        let result = database.select(tableName: tableName.vocabularyList(), type: VocabularyList.self, where: condition, orderBy: orderBy, limit: limit)
        return result.array
    }
    
    /// 搜尋單字內容列表
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    /// - Returns: [[String : Any]]
    func searchWordDetailList(_ word: String, for tableName: Constant.VoiceCode) -> [[String : Any]] {
        
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
    
    /// 搜尋單字組的內容細節
    /// - Parameters:
    ///   - words: 單字組
    ///   - tableName: Constant.VoiceCode
    ///   - count: Int
    ///   - offset: offset
    /// - Returns: [[String : Any]]
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
    
    /// 搜尋要猜的單字列表 (複習)
    /// - Parameters:
    ///   - level: 難度等級
    ///   - days: 幾天前後的資料
    ///   - tableName: 資料表名稱
    ///   - count: 數量
    ///   - offset: 偏移量
    /// - Returns: [[String : Any]]
    func searchGuessWordList(with level: Vocabulary.Level, days: Int = -3, for tableName: Constant.VoiceCode, count: Int = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database,
              let time = Date()._adding(component: .day, value: days)?._localTime()
        else {
            return []
        }
        
        let condition = SQLite3Condition.Where().isCompare(key: "level", type: .equal, value: level.rawValue).andCompare(key: "createTime", type: .lessThan, value: time)
        let limit = SQLite3Condition.Limit().build(count: count, offset: 0)
        let orderBy = SQLite3Condition.OrderBy().item(key: "level", type: .ascending).addItem(key: "review", type: .ascending).addItem(key: "createTime", type: .descending)
        let result = database.select(tableName: tableName.vocabularyList(), type: VocabularyList.self, where: condition, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    /// 搜尋複習單字內容的列表
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    /// - Returns: [[String : Any]]
    func searchReviewWordList(_ word: String, for tableName: Constant.VoiceCode) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let condition = SQLite3Condition.Where().isCompare(key: "word", type: .equal, value: word)
        let orderBy = SQLite3Condition.OrderBy().item(key: "createTime", type: .ascending)
        let result = database.select(tableName: tableName.vocabularyReviewList(), type: VocabularyReviewList.self, where: condition, orderBy: orderBy, limit: nil)
        
        return result.array
    }
    
    /// 搜尋例句內容的列表
    /// - Parameters:
    ///   - speech: 例句的詞性
    ///   - tableName: 資料表名稱
    ///   - count: 數量
    ///   - offset: 偏移量
    /// - Returns: [[String : Any]]
    func searchSentenceList(with speech: VocabularySentenceList.Speech? = nil, for tableName: Constant.VoiceCode, count: Int = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        var condition: SQLite3Condition.Where?
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        let orderBy = SQLite3Condition.OrderBy().item(key: "createTime", type: .descending)
        
        if let speech = speech { condition = SQLite3Condition.Where().isCompare(key: "speech", type: .equal, value: speech.rawValue) }
        
        let result = database.select(tableName: tableName.vocabularySentenceList(), type: VocabularySentenceList.self, where: condition, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    ///  搜尋複習過的單字內容總表
    /// - Parameters:
    ///   - tableName: 資料表名稱
    ///   - count: 單次搜尋的數量
    ///   - offset: 搜尋的偏移量
    /// - Returns: [[String : Any]]
    func searchReviewList(for tableName: Constant.VoiceCode, count: Int = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        let orderBy = SQLite3Condition.OrderBy().item(key: "mistakeCount", type: .descending).addItem(key: "correctCount", type: .ascending).addItem(key: "updateTime", type: .descending)
        let result = database.select(tableName: tableName.vocabularyReviewList(), type: VocabularyReviewList.self, where: nil, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    ///  搜尋書籤列表
    /// - Parameters:
    ///   - tableName: 資料表名稱
    ///   - count: 單次搜尋的數量
    ///   - offset: 搜尋的偏移量
    /// - Returns: [[String : Any]]
    func searchBookmarkList(for tableName: Constant.VoiceCode, count: Int? = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        var limit: SQLite3Condition.Limit?
        
        if let count = count { limit = SQLite3Condition.Limit().build(count: count, offset: offset) }
        let orderBy = SQLite3Condition.OrderBy().item(key: "updateTime", type: .descending)
        let result = database.select(tableName: tableName.bookmarks(), type: BookmarkSite.self, where: nil, orderBy: orderBy, limit: limit)
                
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
    func insertNewWord(_ word: String, for tableName: Constant.VoiceCode) -> [[String : Any]]? {
        
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
        
        let list = searchWord(word, for: tableName)
        return list
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
    
    /// 新增複習過單字到列表
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表名稱
    ///   - isCorrect: 是否答題正確
    /// - Returns: Bool
    func insertReviewWordToList(_ word: String, for tableName: Constant.VoiceCode, isCorrect: Bool) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        var items: [SQLite3Database.InsertItem] = [
            (key: "word", value: word),
        ]
        
        if (!isCorrect) {
            items.append(SQLite3Database.InsertItem(key: "correctCount", value: 0))
            items.append(SQLite3Database.InsertItem(key: "mistakeCount", value: 1))
        } else {
            items.append(SQLite3Database.InsertItem(key: "correctCount", value: 1))
            items.append(SQLite3Database.InsertItem(key: "mistakeCount", value: 0))
        }
        
        let result = database.insert(tableName: tableName.vocabularyReviewList(), itemsArray: [items])
        return result?.isSussess ?? false
    }
    
    /// 新增常用例句
    /// - Parameters:
    ///   - example: 常用例句
    ///   - translate: 例句翻譯
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func insertSentenceToList(_ example: String, translate: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "speech", value: 0),
            (key: "example", value: example.fixSqliteSingleQuote()),
            (key: "translate", value: translate),
        ]
        
        let result = database.insert(tableName: tableName.vocabularySentenceList(), itemsArray: [items])
        return result?.isSussess ?? false
    }
    
    /// 新增書籤
    /// - Parameters:
    ///   - title: 網頁標題
    ///   - webUrl: 網頁網址
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func insertBookmarkToList(_ title: String, webUrl: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "title", value: title),
            (key: "url", value: webUrl),
        ]
        
        let result = database.insert(tableName: tableName.bookmarks(), itemsArray: [items])
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
            (key: "alphabet", value: alphabet.fixSqliteSingleQuote()),
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
            (key: "example", value: info.example.fixSqliteSingleQuote()),
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
    
    /// 更新單字複習次數
    /// - Parameters:
    ///   - id: Int
    ///   - level: 等級
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateReviewCountToList(_ id: Int, count: Int, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "review", value: count),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.vocabularyList(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新複習過的單字正確與否的結果列表
    /// - Parameters:
    ///   - list: VocabularyReviewList
    ///   - isCorrect: 是否答題正題
    ///   - tableName: Constant.VoiceCode
    /// - Returns: Bool
    func updateReviewResultToList(_ list: VocabularyReviewList, isCorrect: Bool, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        var items: [SQLite3Database.InsertItem] = [
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        if (!isCorrect) {
            items.append(SQLite3Database.InsertItem(key: "mistakeCount", value: list.mistakeCount + 1))
        } else {
            items.append(SQLite3Database.InsertItem(key: "correctCount", value: list.correctCount + 1))
        }
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: list.id)
        let result = database.update(tableName: tableName.vocabularyReviewList(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新常用例句分類
    /// - Parameters:
    ///   - id: Int
    ///   - speech: 分類
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateSentenceSpeechToList(_ id: Int, speech: VocabularySentenceList.Speech, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "speech", value: speech.rawValue),
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.vocabularySentenceList(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新常用例句內容
    /// - Parameters:
    ///   - id: Int
    ///   - example: 常用例句
    ///   - translate: 例句翻譯
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateSentenceToList(_ id: Int, example: String, translate: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "example", value: example.fixSqliteSingleQuote()),
            (key: "translate", value: translate),
            (key: "updateTime", value: Date()._localTime())
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.vocabularySentenceList(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新書籤內容
    /// - Parameters:
    ///   - id: Int
    ///   - title: 標題
    ///   - webUrl: 網址
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateBookmarkToList(_ id: Int, title: String, webUrl: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "title", value: title),
            (key: "url", value: webUrl),
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.bookmarks(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新書籤圖片網址
    /// - Parameters:
    ///   - id: Int
    ///   - iconUrl: 圖片網址
    ///   - webUrl: 資料表名稱
    /// - Returns: Bool
    func updateBookmarkIconToList(_ id: Int, iconUrl: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "icon", value: iconUrl),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.update(tableName: tableName.bookmarks(), items: items, where: condition)
        
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
    
    /// 刪除常用例句
    /// - Parameters:
    ///   - id: Int
    ///   - tableName: Constant.VoiceCode
    /// - Returns: Bool
    func deleteSentenceList(with id: Int, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.delete(tableName: tableName.vocabularySentenceList(), where: condition)
        
        return result.isSussess
    }
    
    /// 刪除書籤
    /// - Parameters:
    ///   - id: Int
    ///   - tableName: Constant.VoiceCode
    /// - Returns: Bool
    func deleteBookmark(with id: Int, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let condition = SQLite3Condition.Where().isCompare(key: "id", type: .equal, value: id)
        let result = database.delete(tableName: tableName.bookmarks(), where: condition)
        
        return result.isSussess
    }
}
