//
//  SettingHelper.swift
//  Vocabulary
//
//  Created by William.Weng on 2026/2/12.
//

import Foundation
import WWSQLite3Manager

// MARK: - SettingHelper (單例)
final class SettingHelper: NSObject {
    
    static let shared = SettingHelper()
    
    private override init() {}
}

// MARK: - 公開函數
extension SettingHelper {
    
    /// [初始化資料表 / 資料庫](https://apppeterpan.medium.com/還模擬器一個乾乾淨淨的-xcode-console-a630992448d5)
    func initDatabase() {
        
        let result = WWSQLite3Manager.shared.connect(for: .documents, filename: Constant.databaseName)
        
        switch result {
        case .failure(_): Utility.shared.flashHUD(with: .fail)
        case .success(let database):
            
            Constant.database = database
            Constant.SettingsJSON.generalInformations.forEach { info in _ = createDatabase(database, info: info) }
            
            myPrint(database.fileURL.path)
        }
    }
    
    /// 初始化設定值 => Settings.json
    func initSettings() {
        
        guard let parseSettingsDictionary = Utility.shared.parseSettingsDictionary(with: Constant.settingsJSON),
              let dictionary = settingsDictionary(with: Constant.tableName, dictionary: parseSettingsDictionary),
              let settings = dictionary["settings"] as? [String: Any]
        else {
            return
        }
        
        Constant.SettingsJSON.generalInformations = generalInformations(with: parseSettingsDictionary)
        Constant.SettingsJSON.vocabularyLevelInformations = vocabularyLevelInformations(with: settings)
        Constant.SettingsJSON.sentenceSpeechInformations = sentenceSpeechInformations(with: settings)
        Constant.SettingsJSON.wordSpeechInformations = wordSpeechInformations(with: settings)
        Constant.SettingsJSON.animationInformations = animationInformations(with: settings)
        Constant.SettingsJSON.backgroundInformations = backgroundInformations(with: settings)
        
        Constant.tableNameIndex = Utility.shared.tableNameIndex(Constant.tableName)
    }
}

// MARK: - 小工具
private extension SettingHelper {
    
    /// 建立該語言的資料庫群
    /// - Parameters:
    ///   - database: SQLite3Database
    ///   - info: Settings.GeneralInformation
    /// - Returns: [SQLite3Database.ExecuteResult]
    func createDatabase(_ database: SQLite3Database, info: Settings.GeneralInformation) -> [SQLite3Database.ExecuteResult] {
        
        let language = info.key
        
        let result = [
            database.create(tableName: Constant.DataTableType.default(language).name(), type: Vocabulary.self, isOverwrite: false),
            database.create(tableName: Constant.DataTableType.list(language).name(), type: VocabularyList.self, isOverwrite: false),
            database.create(tableName: Constant.DataTableType.review(language).name(), type: VocabularyReviewList.self, isOverwrite: false),
            database.create(tableName: Constant.DataTableType.sentence(language).name(), type: VocabularySentenceList.self, isOverwrite: false),
            database.create(tableName: Constant.DataTableType.bookmarkSite(language).name(), type: BookmarkSite.self, isOverwrite: false),
        ]
        
        return result
    }
}

// MARK: - Settings.json
private extension SettingHelper {
        
    /// 取得一般般的設定檔
    /// - Parameter dictionary: [String: Any]
    /// - Returns: [String: Settings.GeneralInformation]
    func generalInformations(with dictionary: [String: Any]) -> [Settings.GeneralInformation] {
        
        let array = dictionary.keys.compactMap { key -> Settings.GeneralInformation? in
            
            guard var dictionary = dictionary[key] as? [String: Any] else { return nil }
            dictionary["key"] = key
            
            return dictionary._jsonClass(for: Settings.GeneralInformation.self)
        }
        
        return array.sorted { return $1.value > $0.value }
    }
    
    /// 取得該語言的設定檔
    /// - Parameters:
    ///   - tableName: String?
    ///   - filename: String
    /// - Returns: [String: Any]?
    func settingsDictionary(with tableName: String?, dictionary: [String: Any]) -> [String: Any]? {
        
        let currentTableName = tableName ?? "English"
        Constant.tableName = currentTableName
        
        guard let settings = dictionary[currentTableName] as? [String: Any] else { return nil }
        return settings
    }
        
    /// 解析單字等級的設定值 (排序由小到大)
    /// - Parameter settings: [String: Any]
    /// - Returns: [Settings.VocabularyLevelInformation]
    func vocabularyLevelInformations(with settings: [String: Any]) -> [Settings.VocabularyLevelInformation] {
        let array = colorSettingsArray(with: settings, key: .vocabularyLevel, type: Settings.VocabularyLevelInformation.self)
        return array.sorted { return $1.value > $0.value }
    }
    
    /// 解析精選例句類型的設定值
    /// - Parameter settings: [String: Any]
    /// - Returns: [SentenceSpeechInformation]
    func sentenceSpeechInformations(with settings: [String: Any]) -> [Settings.SentenceSpeechInformation] {
        let array = colorSettingsArray(with: settings, key: .sentenceSpeech, type: Settings.SentenceSpeechInformation.self)
        return array.sorted { return $1.value > $0.value }
    }
    
    /// 解析單字型態的設定值
    /// - Parameter settings: [String: Any]
    /// - Returns: [Settings.SentenceSpeechInformation]
    func wordSpeechInformations(with settings: [String: Any]) -> [Settings.WordSpeechInformation] {
        let array = colorSettingsArray(with: settings, key: .wordSpeech, type: Settings.WordSpeechInformation.self)
        return array.sorted { return $1.value > $0.value }
    }
    
    /// 解析HUD動畫檔案的設定值
    /// - Parameter settings: [String: Any]
    /// - Returns: [Settings.SentenceSpeechInformation]
    func animationInformations(with settings: [String: Any]) -> [Settings.AnimationInformation] {
        let array = colorSettingsArray(with: settings, key: .animation, type: Settings.AnimationInformation.self)
        return array.sorted { return $1.value > $0.value }
    }
    
    /// 解析背景動畫檔案的設定值
    /// - Parameter settings: [String: Any]
    /// - Returns: [Settings.SentenceSpeechInformation]
    func backgroundInformations(with settings: [String: Any]) -> [Settings.BackgroundInformation] {
        let array = colorSettingsArray(with: settings, key: .background, type: Settings.BackgroundInformation.self)
        return array.sorted { return $1.value > $0.value }
    }
    
    /// 解析Settings有關顏色的設定檔值
    /// - Parameters:
    ///   - settings: [String: Any]
    ///   - key: Constant.SettingsColorKey
    ///   - type: T.Type
    /// - Returns: [T]
    func colorSettingsArray<T: Decodable>(with settings: [String: Any], key: Constant.SettingsColorKey, type: T.Type) -> [T] {
        
        guard let informations = settings[key.value()] as? [String: Any] else { return [] }
        
        let array = informations.keys.compactMap { key -> T? in
            
            guard var dictionary = informations[key] as? [String: Any] else { return nil }
            dictionary["key"] = key
            
            return dictionary._jsonClass(for: T.self)
        }
        
        return array
    }
}
