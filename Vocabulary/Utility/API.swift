//
//  API.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import UIKit
import WWSQLite3Manager

// MARK: - API (單例)
final class API: NSObject {
    
    static let shared = API()
    private override init() {}
}

// MARK: - 小工具 (Search)
extension API {
    
    /// 搜尋單字列表
    /// - Parameters:
    ///   - words: 特定單字群
    ///   - info: Settings.SentenceSpeechInformation
    ///   - count: 單次搜尋的數量
    ///   - offset: 搜尋的偏移量
    ///   - isFavorite: 我的最愛
    /// - Returns: [[String : Any]]
    func searchVocabularyList(in words: [String]? = nil, isFavorite: Bool = false, info: Settings.GeneralInformation, count: Int = Constant.searchCount, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let type: Constant.DataTableType = .list(info.key)
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        var condition: SQLite3Condition.Where?
        var orderBy: SQLite3Condition.OrderBy? = SQLite3Condition.OrderBy().item(type: .descending(key: "updateTime"))
        
        if let words = words, !words.isEmpty {
            condition = SQLite3Condition.Where().in(key: "word", values: words)
            orderBy = SQLite3Condition.OrderBy().item(type: .ascending(key: "word"))
        }
        
        if (isFavorite) {
            condition = SQLite3Condition.Where().isCompare(type: .equal(key: "favorite", value: isFavorite._int()))
            orderBy = SQLite3Condition.OrderBy().item(type: .descending(key: "updateTime"))
        }
        
        let result = database.select(tableName: type.name(), type: VocabularyList.self, where: condition, orderBy: orderBy, limit: limit)
        return result.array
    }
    
    /// 隨機單字搜尋
    /// - Parameters:
    ///   - info: Settings.GeneralInformation
    ///   - count: 數量
    /// - Returns: [[String : Any]]
    func searchWordRandomListDetail(info: Settings.GeneralInformation, count: Int = Constant.searchCount) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let type: Constant.DataTableType = .list(info.key)
        let limit = SQLite3Condition.Limit().build(count: count, offset: 0)
        let orderBy: SQLite3Condition.OrderBy? = SQLite3Condition.OrderBy().item(type: .random)
        let result = database.select(tableName: type.name(), type: VocabularyList.self, where: nil, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    /// 搜尋單字列表總數量
    /// - Parameters:
    ///   - info: Settings.GeneralInformation
    ///   - key: 欄位名稱
    ///   - isFavorite: Bool
    /// - Returns: [[String : Any]]
    func searchVocabularyCount(info: Settings.GeneralInformation, key: String? = nil, isFavorite: Bool = false) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let type: Constant.DataTableType = .list(info.key)
        let condition: SQLite3Condition.Where? = (isFavorite) ? SQLite3Condition.Where().isCompare(type: .equal(key: "favorite", value: isFavorite._int())) : nil
        let result = database.select(tableName: type.name(), functions: [.count(key, .INTEGER())], where: condition)
        
        return result.array
    }
    
    /// 搜尋該單字數量
    /// - Parameters:
    ///   - word: String
    ///   - info: Settings.GeneralInformation
    ///   - key: String?
    /// - Returns: [[String : Any]]
    func searchWordDetailListCount(_ word: String, info: Settings.GeneralInformation, key: String? = nil) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let type: Constant.DataTableType = .default(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "word", value: word))
        let result = database.select(tableName: type.name(), functions: [.count(key, .INTEGER())], where: condition)
        
        return result.array
    }
    
    /// 搜尋書籤總數量
    /// - Parameters:
    ///   - info: Settings.GeneralInformation
    ///   - key: 欄位名稱
    ///   - isFavorite: Bool
    /// - Returns: [[String : Any]]
    func searchBookmarkCount(for info: Settings.GeneralInformation, key: String? = nil, isFavorite: Bool) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let type: Constant.DataTableType = .bookmarkSite(info.key)
        var condition: SQLite3Condition.Where?

        if (isFavorite) { condition = SQLite3Condition.Where().isCompare(type: .equal(key: "favorite", value: isFavorite._int())) }
        let result = database.select(tableName: type.name(), functions: [.count(key, .INTEGER())], where: condition)
        
        return result.array
    }
    
    /// 搜尋精選例句總數量
    /// - Parameters:
    ///   - info: Settings.GeneralInformation
    ///   - key: 欄位名稱
    ///   - speechInfo: Settings.SentenceSpeechInformation?
    ///   - isFavorite: Bool
    /// - Returns: [[String : Any]]
    func searchSentenceCount(generalInfo: Settings.GeneralInformation, key: String? = nil, speechInfo: Settings.SentenceSpeechInformation?, isFavorite: Bool) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let type: Constant.DataTableType = .sentence(generalInfo.key)
        var condition: SQLite3Condition.Where?

        if let speechInfo = speechInfo {
            var _condition = SQLite3Condition.Where().isCompare(type: .equal(key: "speech", value: speechInfo.value))
            if isFavorite { _condition = _condition.andCompare(type: .equal(key: "favorite", value: isFavorite._int())) }
            condition = _condition
        }
        
        if isFavorite {
            var _condition = SQLite3Condition.Where().isCompare(type: .equal(key: "favorite", value: isFavorite._int()))
            if let speechInfo = speechInfo { _condition = _condition.andCompare(type: .equal(key: "speech", value: speechInfo.value)) }
            condition = _condition
        }
        
        let result = database.select(tableName: type.name(), functions: [.count(key, .INTEGER())], where: condition)
        
        return result.array
    }
    
    /// 搜尋複習總覽總數量
    /// - Parameters:
    ///   - info: Settings.GeneralInformation
    ///   - key: 欄位名稱
    ///   - isFavorite: Bool
    /// - Returns: [[String : Any]]
    func searchReviewCount(for info: Settings.GeneralInformation, key: String, isFavorite: Bool) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let reviewType: Constant.DataTableType = .review(info.key)
        let listType: Constant.DataTableType = .list(info.key)
        let field = "\(key)Count"
        
        var array: [[String : Any]] = []
        var sql = "SELECT Count(Review.\(key)) as \(field) FROM \(reviewType.name()) as Review JOIN \(listType.name()) as List ON Review.word = List.word"
        
        if (isFavorite) { sql += " WHERE List.favorite = \(isFavorite._int())" }
        
        database.select(sql: sql, result: { statement in
            
            var dict: [String : Any] = [:]
            
            dict["\(field)"] = statement?._value(at: Int32(0), dataType: .INTEGER()) ?? 0
            array.append(dict)
            
        }, completion: { isCompleted in
            myPrint(isCompleted)
        })
        
        return array
    }
    
    /// 搜尋單字內容列表
    /// - Parameters:
    ///   - word: 單字
    ///   - type: Constant.DataTableType
    /// - Returns: [[String : Any]]
    func searchWordDetailList(_ word: String, for type: Constant.DataTableType) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "word", value: word))
        let orderBy = SQLite3Condition.OrderBy().item(type: .descending(key: "hardwork")).addItem(type: .ascending(key: "createTime"))
        let result = database.select(tableName: type.name(), type: Vocabulary.self, where: condition, orderBy: orderBy, limit: nil)
        
        return result.array
    }
    
    /// 搜尋相似內容的列表 (單字 / 字義)
    ///  - Parameters:
    /// - Parameters:
    ///   - text: 相似的文字
    ///   - searchType: Constant.SearchType
    ///   - info: Settings.GeneralInformation
    ///   - count: 單次搜尋的數量
    ///   - offset: 搜尋的偏移量
    /// - Returns: [[String : Any]]
    func searchList(like text: String, searchType: Constant.SearchType, info: Settings.GeneralInformation, count: Int? = Constant.searchCount, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let condition: SQLite3Condition.Where
        let orderBy = SQLite3Condition.OrderBy().item(type: .ascending(key: "word"))
        let result: SQLite3Database.SelectResult

        var limit: SQLite3Condition.Limit?

        if let count = count { limit = SQLite3Condition.Limit().build(count: count, offset: offset) }
        
        switch searchType {
        case .word, .alphabet:
            
            let type: Constant.DataTableType = .list(info.key)
            condition = SQLite3Condition.Where().like(key: "\(searchType.field())", condition: "\(text)%")
            result = database.select(tableName: type.name(), type: VocabularyList.self, where: condition, orderBy: orderBy, limit: limit)
            
        case .interpret:
            
            let type: Constant.DataTableType = .default(info.key)
            condition = SQLite3Condition.Where().like(key: "\(searchType.field())", condition: "%\(text)%")
            result = database.select(tableName: type.name(), type: Vocabulary.self, where: condition, orderBy: orderBy, limit: limit)
        }
        
        return result.array
    }
    
    /// 搜尋單字組的內容細節
    /// - Parameters:
    ///   - words: 單字組
    ///   - info: Settings.GeneralInformation
    ///   - offset: offset
    /// - Returns: [[String : Any]]
    func searchWordDetail(in words: [String], info: Settings.GeneralInformation, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database,
              !words.isEmpty
        else {
            return []
        }
        
        let type: Constant.DataTableType = .default(info.key)
        let condition = SQLite3Condition.Where().in(key: "word", values: words)
        let result = database.select(tableName: type.name(), type: Vocabulary.self, where: condition, orderBy: nil, limit: nil)
        
        return result.array
    }
    
    /// 搜尋單字組內容
    /// - Parameters:
    ///   - words: [String]
    ///   - info: Settings.GeneralInformation
    ///   - count: Int
    ///   - offset: Int
    /// - Returns: [[String : Any]]
    func searchWordListDetail(in words: [String], info: Settings.GeneralInformation, count: Int = Constant.searchCount, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database,
              !words.isEmpty
        else {
            return []
        }
        
        let type: Constant.DataTableType = .list(info.key)
        let condition = SQLite3Condition.Where().in(key: "word", values: words)
        let orderBy = SQLite3Condition.OrderBy().item(type: .ascending(key: "word"))
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        let result = database.select(tableName: type.name(), type: VocabularyList.self, where: condition, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    /// 搜尋要猜的單字列表 (複習)
    /// - Parameters:
    ///   - levelInfo: 難度等級資訊
    ///   - days: 幾天前的資料
    ///   - generalInfo: Settings.GeneralInformation
    ///   - offset: 偏移量
    /// - Returns: [[String : Any]]
    func searchGuessWordList(with levelInfo: Settings.VocabularyLevelInformation, days: Int = 0, generalInfo: Settings.GeneralInformation, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database,
              let time = Date()._adding(component: .day, value: -days)?._localTime()
        else {
            return []
        }
        
        let type: Constant.DataTableType = .list(generalInfo.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "level", value: levelInfo.value)).andCompare(type: .lessThan(key: "createTime", value: time))
        let limit = SQLite3Condition.Limit().build(count: levelInfo.guessCount, offset: offset)
        let orderBy = SQLite3Condition.OrderBy().item(type: .ascending(key: "level")).addItem(type: .ascending(key: "review")).addItem(type: .descending(key: "createTime"))
        let result = database.select(tableName: type.name(), type: VocabularyList.self, where: condition, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    /// 搜尋複習單字內容的列表
    /// - Parameters:
    ///   - word: 單字
    ///   - info: Settings.GeneralInformation
    /// - Returns: [[String : Any]]
    func searchReviewWordList(_ word: String, info: Settings.GeneralInformation) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let type: Constant.DataTableType = .review(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "word", value: word))
        let orderBy = SQLite3Condition.OrderBy().item(type: .ascending(key: "createTime"))
        let result = database.select(tableName: type.name(), type: VocabularyReviewList.self, where: condition, orderBy: orderBy, limit: nil)
        
        return result.array
    }
    
    /// 搜尋例句內容的列表
    /// - Parameters:
    ///   - speechInfo: Settings.SentenceSpeechInformation?
    ///   - generalInfo: Settings.GeneralInformation
    ///   - count: 數量
    ///   - offset: 偏移量
    ///   - isFavorite: 我的最愛
    /// - Returns: [[String : Any]]
    func searchSentenceList(with speechInfo: Settings.SentenceSpeechInformation? = nil, isFavorite: Bool = false, generalInfo: Settings.GeneralInformation, count: Int = Constant.searchCount, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let type: Constant.DataTableType = .sentence(generalInfo.key)
        let limit = SQLite3Condition.Limit().build(count: count, offset: offset)
        
        var orderBy = SQLite3Condition.OrderBy().item(type: .descending(key: "createTime"))
        var condition: SQLite3Condition.Where?

        if let speechInfo = speechInfo {
            var _condition = SQLite3Condition.Where().isCompare(type: .equal(key: "speech", value: speechInfo.value))
            if isFavorite { _condition = _condition.andCompare(type: .equal(key: "favorite", value: isFavorite._int())) }
            condition = _condition
        }
        
        if isFavorite {
            var _condition = SQLite3Condition.Where().isCompare(type: .equal(key: "favorite", value: isFavorite._int()))
            if let speechInfo = speechInfo { _condition = _condition.andCompare(type: .equal(key: "speech", value: speechInfo.value)) }
            orderBy = SQLite3Condition.OrderBy().item(type: .descending(key: "updateTime"))
            condition = _condition
        }
        
        let result = database.select(tableName: type.name(), type: VocabularySentenceList.self, where: condition, orderBy: orderBy, limit: limit)
        
        return result.array
    }
    
    /// 搜尋複習過的單字內容總表
    /// - Parameters:
    ///   - info: Settings.GeneralInformation
    ///   - type: Constant.ReviewResultType
    ///   - isFavorite: Bool
    ///   - count: Int
    ///   - offset: Int
    /// - Returns: [[String : Any]]
    func searchReviewList(for info: Settings.GeneralInformation, type: Constant.ReviewResultType = .alphabet, isFavorite: Bool, count: Int = Constant.searchCount, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        let reviewType: Constant.DataTableType = .review(info.key)
        let listType: Constant.DataTableType = .list(info.key)
        
        let limit = "LIMIT \(count) OFFSET \(offset)"
        let condition = "WHERE favorite = \(isFavorite._int())"
        let modelType = VocabularyReviewList.self
        
        var orderBy = "ORDER BY Review.updateTime DESC"
        var array: [[String : Any]] = []

        switch type {
        case .updateTime: orderBy = "ORDER BY Review.updateTime DESC"
        case .alphabet: orderBy = "ORDER BY Review.word ASC"
        case .correctCount: orderBy = "ORDER BY Review.correctCount DESC"
        case .mistakeCount: orderBy = "ORDER BY Review.mistakeCount DESC"
        }
        
        var sql = "SELECT Review.id, Review.word, Review.correctCount, Review.mistakeCount, List.id as wordId, List.favorite as favorite, Review.createTime, Review.updateTime FROM \(reviewType.name()) as Review JOIN \(listType.name()) as List ON Review.word = List.word"
        
        if (isFavorite) { sql += " \(condition)" }
        sql += " \(orderBy) \(limit)"
        
        database.select(sql: sql, result: { statement in
            
            var dict: [String : Any] = [:]
            
            modelType.structure()._forEach { (index, paramater, _) in
                dict[paramater.key] = statement?._value(at: Int32(index), dataType: paramater.type) ?? nil
            }
            
            array.append(dict)
            
        }, completion: { isCompleted in
            myPrint(isCompleted)
        })
        
        return array
    }
    
    ///  搜尋書籤列表
    /// - Parameters:
    ///   - info: Settings.GeneralInformation
    ///   - count: 單次搜尋的數量
    ///   - offset: 搜尋的偏移量
    ///   - isFavorite: 我的最愛
    /// - Returns: [[String : Any]]
    func searchBookmarkList(isFavorite: Bool, info: Settings.GeneralInformation, count: Int? = 10, offset: Int) -> [[String : Any]] {
        
        guard let database = Constant.database else { return [] }
        
        var orderBy = SQLite3Condition.OrderBy().item(type: .descending(key: "createTime"))
        var condition: SQLite3Condition.Where?
        var limit: SQLite3Condition.Limit?
        
        if let count = count { limit = SQLite3Condition.Limit().build(count: count, offset: offset) }
        
        if (isFavorite) {
            condition = SQLite3Condition.Where().isCompare(type: .equal(key: "favorite", value: isFavorite._int()))
            orderBy = SQLite3Condition.OrderBy().item(type: .descending(key: "updateTime"))
        }
        
        let type: Constant.DataTableType = .bookmarkSite(info.key)
        let result = database.select(tableName: type.name(), type: BookmarkSite.self, where: condition, orderBy: orderBy, limit: limit)
        
        return result.array
    }
}

// MARK: - 小工具 (Insert)
extension API {
    
    /// 新增單字
    /// - Parameters:
    ///   - word: 單字
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func insertNewWord(_ word: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database,
              !word.isEmpty
        else {
            return false
        }
        
        let type: Constant.DataTableType = .default(info.key)
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "word", value: word),
            (key: "speech", value: 0),
        ]
        
        let result = database.insert(tableName: type.name(), itemsArray: [items])
        
        return result?.isSussess ?? false
    }
    
    /// 新增單字到列表
    /// - Parameters:
    ///   - word: 單字
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func insertWordToList(_ word: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let type: Constant.DataTableType = .list(info.key)
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "word", value: word),
            (key: "count", value: 1),
            (key: "level", value: 0),
        ]
        
        let result = database.insert(tableName: type.name(), itemsArray: [items])
        
        return result?.isSussess ?? false
    }
    
    /// 新增複習過單字到列表
    /// - Parameters:
    ///   - word: 單字
    ///   - info: Settings.GeneralInformation
    ///   - isCorrect: 是否答題正確
    /// - Returns: Bool
    func insertReviewWordToList(_ word: String, info: Settings.GeneralInformation, isCorrect: Bool) -> Bool {
        
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
        
        let type: Constant.DataTableType = .review(info.key)
        let result = database.insert(tableName: type.name(), itemsArray: [items])
        
        return result?.isSussess ?? false
    }
    
    /// 新增常用例句
    /// - Parameters:
    ///   - example: 常用例句
    ///   - translate: 例句翻譯
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func insertSentenceToList(_ example: String, translate: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database,
              !example.isEmpty
        else {
            return false
        }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "speech", value: 0),
            (key: "example", value: example.fixSqliteSingleQuote()),
            (key: "translate", value: translate),
        ]
        
        let type: Constant.DataTableType = .sentence(info.key)
        let result = database.insert(tableName: type.name(), itemsArray: [items])
        
        return result?.isSussess ?? false
    }
    
    /// 新增書籤
    /// - Parameters:
    ///   - title: 網頁標題
    ///   - webUrl: 網頁網址
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func insertBookmarkToList(_ title: String, webUrl: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database,
              !webUrl.isEmpty
        else {
            return false
        }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "title", value: title),
            (key: "url", value: webUrl),
        ]
        
        let type: Constant.DataTableType = .bookmarkSite(info.key)
        let result = database.insert(tableName: type.name(), itemsArray: [items])
        
        return result?.isSussess ?? false
    }
}

// MARK: - 小工具 (Update)
extension API {
    
    /// 更新單字例句數量
    /// - Parameters:
    ///   - word: 單字
    ///   - info: Settings.GeneralInformation
    ///   - count: 例句數量
    ///   - hasUpdateTime: 要不要加上更新時間
    /// - Returns: Bool
    func updateWordToList(_ word: String, info: Settings.GeneralInformation, count: Int, hasUpdateTime: Bool = true) -> Bool {
        
        guard let database = Constant.database,
              let type: Constant.DataTableType = Optional.some(.list(info.key))
        else {
            return false
        }
        
        var items: [SQLite3Database.InsertItem] = [
            (key: "count", value: count),
        ]
        
        if (hasUpdateTime) { items.append(SQLite3Database.InsertItem((key: "updateTime", value: Date()._localTime()))) }
        
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "word", value: word))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字音標
    /// - Parameters:
    ///   - id: Int
    ///   - alphabet: 音標
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateAlphabetToList(_ id: Int, alphabet: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let type: Constant.DataTableType = .list(info.key)

        let items: [SQLite3Database.InsertItem] = [
            (key: "alphabet", value: alphabet.fixSqliteSingleQuote()),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字範例相關內容
    /// - Parameters:
    ///   - exampleInfo: Constant.ExampleInfomation
    ///   - generalInfo: Settings.GeneralInformation
    /// - Returns: Bool
    func updateExmapleToList(_ exampleInfo: Constant.ExampleInfomation, generalInfo: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "interpret", value: exampleInfo.interpret),
            (key: "example", value: exampleInfo.example.fixSqliteSingleQuote()),
            (key: "translate", value: exampleInfo.translate),
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        let type: Constant.DataTableType = .default(generalInfo.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: exampleInfo.id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字詞性
    /// - Parameters:
    ///   - id: Int
    ///   - speechInfo: Settings.WordSpeechInformation
    ///   - generalInfo: Settings.GeneralInformation
    /// - Returns: Bool
    func updateSpeechToList(_ id: Int, speechInfo: Settings.WordSpeechInformation, generalInfo: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "speech", value: speechInfo.value),
        ]
        
        let type: Constant.DataTableType = .default(generalInfo.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字等級
    /// - Parameters:
    ///   - id: Int
    ///   - info: Settings.VocabularyLevelInformation
    ///   - generalInfo: Settings.GeneralInformation
    /// - Returns: Bool
    func updateLevelToList(_ id: Int, levelInfo: Settings.VocabularyLevelInformation, generalInfo: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let type: Constant.DataTableType = .list(generalInfo.key)
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "level", value: levelInfo.value),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新『翻譯難度』 => hardWork
    /// - Parameters:
    ///   - id: Int
    ///   - isHardWork: Bool
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateHardWorkToList(_ id: Int, isHardWork: Bool, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let _isHardWork = isHardWork ? 1 : 0
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "hardWork", value: _isHardWork),
        ]
        
        let type: Constant.DataTableType = .default(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新『我的最愛』 => favorite
    /// - Parameters:
    ///   - id: Int
    ///   - isFavorite: Bool
    ///   - tableName: String
    /// - Returns: Bool
    func updateFavoriteToList(_ id: Int, isFavorite: Bool, for tableName: String) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let _isFavorite = isFavorite ? 1 : 0
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "favorite", value: _isFavorite),
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: tableName, items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新單字『我的最愛』
    /// - Parameters:
    ///   - id: Int
    ///   - info: Settings.GeneralInformation
    ///   - isFavorite: Bool
    /// - Returns: Bool
    func updateVocabularyFavoriteToList(_ id: Int, info: Settings.GeneralInformation, isFavorite: Bool) -> Bool {
        
        let type: Constant.DataTableType = .list(info.key)
        return updateFavoriteToList(id, isFavorite: isFavorite, for: type.name())
    }
    
    /// 更新例句『我的最愛』
    /// - Parameters:
    ///   - id: Int
    ///   - isFavorite: Bool
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateSentenceFavoriteToList(_ id: Int, isFavorite: Bool, info: Settings.GeneralInformation) -> Bool {
        let type: Constant.DataTableType = .sentence(info.key)
        return updateFavoriteToList(id, isFavorite: isFavorite, for: type.name())
    }
    
    /// 更新書籤『我的最愛』
    /// - Parameters:
    ///   - id: Int
    ///   - isFavorite: Bool
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateBookmarkFavoriteToList(_ id: Int, isFavorite: Bool, info: Settings.GeneralInformation) -> Bool {
        let type: Constant.DataTableType = .bookmarkSite(info.key)
        return updateFavoriteToList(id, isFavorite: isFavorite, for: type.name())
    }
    
    /// 更新單字複習次數
    /// - Parameters:
    ///   - id: Int
    ///   - level: 等級
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateReviewCountToList(_ id: Int, count: Int, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "review", value: count),
        ]
        
        let type: Constant.DataTableType = .list(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新複習過的單字正確與否的結果列表
    /// - Parameters:
    ///   - list: VocabularyReviewList
    ///   - isCorrect: 是否答題正題
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateReviewResultToList(_ list: VocabularyReviewList, isCorrect: Bool, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        var items: [SQLite3Database.InsertItem] = [
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        if (!isCorrect) {
            items.append(SQLite3Database.InsertItem(key: "mistakeCount", value: list.mistakeCount + 1))
        } else {
            items.append(SQLite3Database.InsertItem(key: "correctCount", value: list.correctCount + 1))
        }
        
        let type: Constant.DataTableType = .review(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: list.id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新常用例句分類
    /// - Parameters:
    ///   - id: Int
    ///   - speechInfo: Settings.SentenceSpeechInformation
    ///   - generalInfo: Settings.GeneralInformation
    /// - Returns: Bool
    func updateSentenceSpeechToList(_ id: Int, speechInfo: Settings.SentenceSpeechInformation, generalInfo: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "speech", value: speechInfo.value),
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        let type: Constant.DataTableType = .sentence(generalInfo.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新常用例句內容
    /// - Parameters:
    ///   - id: Int
    ///   - example: 常用例句
    ///   - translate: 例句翻譯
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateSentenceToList(_ id: Int, example: String, translate: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "example", value: example.fixSqliteSingleQuote()),
            (key: "translate", value: translate),
            (key: "updateTime", value: Date()._localTime())
        ]
        
        let type: Constant.DataTableType = .sentence(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新書籤內容
    /// - Parameters:
    ///   - id: Int
    ///   - title: 標題
    ///   - webUrl: 網址
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateBookmarkToList(_ id: Int, title: String, webUrl: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "title", value: title),
            (key: "url", value: webUrl),
            (key: "updateTime", value: Date()._localTime()),
        ]
        
        let type: Constant.DataTableType = .bookmarkSite(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
    
    /// 更新書籤圖片網址
    /// - Parameters:
    ///   - id: Int
    ///   - iconUrl: 圖片網址
    ///   - webUrl: 資料表名稱
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateBookmarkIconToList(_ id: Int, iconUrl: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let items: [SQLite3Database.InsertItem] = [
            (key: "icon", value: iconUrl),
        ]
        
        let type: Constant.DataTableType = .bookmarkSite(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.update(tableName: type.name(), items: items, where: condition)
        
        return result.isSussess
    }
}

// MARK: - 小工具 (Delete)
extension API {
    
    /// 刪除單字範例
    /// - Parameters:
    ///   - id: Int
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func deleteWord(with id: Int, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let type: Constant.DataTableType = .default(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.delete(tableName: type.name(), where: condition)
        
        return result.isSussess
    }
    
    /// 刪除列表單字
    /// - Parameters:
    ///   - id: Int
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func deleteWordList(with id: Int, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let type: Constant.DataTableType = .list(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.delete(tableName: type.name(), where: condition)
        
        return result.isSussess
    }
    
    /// 刪除常用例句
    /// - Parameters:
    ///   - id: Int
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func deleteSentenceList(with id: Int, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let type: Constant.DataTableType = .sentence(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.delete(tableName: type.name(), where: condition)
        
        return result.isSussess
    }
    
    /// 刪除書籤
    /// - Parameters:
    ///   - id: Int
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func deleteBookmark(with id: Int, info: Settings.GeneralInformation) -> Bool {
        
        guard let database = Constant.database else { return false }
        
        let type: Constant.DataTableType = .bookmarkSite(info.key)
        let condition = SQLite3Condition.Where().isCompare(type: .equal(key: "id", value: id))
        let result = database.delete(tableName: type.name(), where: condition)
        
        return result.isSussess
    }
}
