//
//  Constant.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import WWUserDefaults
import WWSQLite3Manager

// MARK: - Constant
final class Constant: NSObject {
    
    // MARK: - SettingsJSON
    final class SettingsJSON {
        
        static var vocabularyLevelInformations: [Settings.VocabularyLevelInformation] = []
        static var sentenceSpeechInformations: [Settings.SentenceSpeechInformation] = []
        static var wordSpeechInformations: [Settings.WordSpeechInformation] = []
        static var generalInformations: [Settings.GeneralInformation] = []
        static var animationInformations: [Settings.AnimationInformation] = []
        static var backgroundInformations: [Settings.BackgroundInformation] = []
    }
    
    @WWUserDefaults("CurrentTableName") static var tableName: String?
    @WWUserDefaults("ChatGPTBearerToken") static var bearerToken: String?
    
    static let webImageExpiredDays = 90
    static let autoBackupDays = 7
    static let searchCount = 10
    static let searchGuessWordDays = 14
    static let pixelSize = 192
    static let webImageCacheDelayTime = 600.0
    
    static let maxnumDownloadCount: UInt = 10
    static let duration: TimeInterval = 0.15
    static let delay: TimeInterval = 0.25
    static let autoBackupDelaySecond: TimeInterval = 2
    static let searchDelayTime: TimeInterval = 0.3
    
    static let urlScheme = "word"
    static let reload = "重新讀取"
    static let noDataUpdate = "無更新資料"
    static let databaseName = "Vocabulary.db"
    static let databaseFileExtension = "db"
    static let recordFilename = "record.wav"
    static let settingsJSON = "Settings.json"
    static let fontname = "jf-openhuninn-2.0"
    
    static var tableNameIndex = 0
    static var volume: Float = 0.1
    static var speakingSpeed: Float = 0.4
    static var updateScrolledHeight: CGFloat = 128.0
    static var updateSearchScrolledHeight: CGFloat = 96.0
    static var database: SQLite3Database?
    static var backupDirectory = FileManager.default._documentDirectory()
    static var musicFileList: [String]?
    static var playingMusicList: [Music] = []
    
    static var isPrint: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Typealias
extension Constant {
    
    typealias ExampleInfomation = (id: Int, interpret: String, example: String, translate: String)                          // 單字ID / 字義 / 例句 / 例句翻譯
    typealias GIFImageInformation = (index: Int, cgImage: CGImage, pointer: UnsafeMutablePointer<Bool>)                     // GIF動畫: (第幾張, CGImage, UnsafeMutablePointer<Bool>)
    typealias FileInfomation = (isExist: Bool, isDirectory: Bool)                                                           // 檔案相關資訊 (是否存在 / 是否為資料夾)
    typealias AppVersion = (app: String, build: String)                                                                     // APP版本號 (公開版號, 內測版號)
    typealias SystemInformation = (name: String, version: String, model: String, idiom: UIUserInterfaceIdiom)               // 系統資訊 => (iOS, 12.1, iPhone, 0)
    typealias KeyboardInfomation = (duration: Double, curve: UInt, frame: CGRect)                                           // 取得系統鍵盤的相關資訊
    typealias RGBAInformation = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)                               // [RGBA色彩模式的數值](https://stackoverflow.com/questions/28644311/how-to-get-the-rgb-code-int-from-an-uicolor-in-swift)
    typealias PaletteInformation = (color: UIColor?, backgroundColor: UIColor?)                                             // 調色盤選的顏色 (文字, 背景)
    typealias SelectedPaletteInformation = (indexPath: IndexPath?, type: PaletteViewController.ColorType?, color: UIColor?) // 調色盤選暫存色 (位置, 類型, 背景)
    typealias ChatMessage = (text: String?, isMe: Bool)                                                                     // 對話文字 (文字, 是不是自己)
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
    
    /// 由URL所產生的功能
    /// => word://append/<單字>
    enum DeepLinkAction: String {
        case append     // 加入新單字
        case search     // 搜尋該單字
        case icon       // 更換ICON
    }
    
    /// 能夠設定顏色的Settings設定檔
    enum SettingsColorKey: Int, CaseIterable {
        
        case vocabularyLevel
        case sentenceSpeech
        case wordSpeech
        case animation
        case background
        
        /// 以文字去搜找Key值
        /// - Parameter value: String?
        /// - Returns: SettingsColorKey?
        static func findKey(_ value: String?) -> SettingsColorKey? {
            
            guard let value = value else { return nil }
            
            let key = Self.allCases.first { value == $0.value() }
            return key
        }
        
        /// 取得Key值
        /// - Returns: String
        func value() -> String {
            
            switch self {
            case .vocabularyLevel: return "vocabularyLevel"
            case .sentenceSpeech: return "sentenceSpeech"
            case .wordSpeech: return "wordSpeech"
            case .animation: return "animation"
            case .background: return "background"
            }
        }
        
        /// 顯示名稱
        /// - Returns: String
        func name() -> String {
            
            switch self {
            case .vocabularyLevel: return "單字等級"
            case .sentenceSpeech: return "精選例句"
            case .wordSpeech: return "單字詞性"
            case .animation: return "提示動畫"
            case .background: return "背景動畫"
            }
        }
        
        /// 取得Settings的相關數值
        /// - Returns: [Decodable]
        func informations() -> [ColorSettings]? {
            
            switch self {
            case .vocabularyLevel: return Constant.SettingsJSON.vocabularyLevelInformations
            case .sentenceSpeech: return Constant.SettingsJSON.sentenceSpeechInformations
            case .wordSpeech: return Constant.SettingsJSON.wordSpeechInformations
            case .animation: return Constant.SettingsJSON.animationInformations
            case .background: return Constant.SettingsJSON.backgroundInformations
            }
        }
    }
    
    /// Tabbar的首頁ViewController
    enum TabbarRootViewController {
        
        case Main       // 單字記憶
        case Sentence   // 精選例句
        case Solution   // 複習單字
        case Other      // 其它設定
        
        /// TabbarViewController的selectedIndex
        /// - Returns: Int
        func index() -> Int {
            
            switch self {
            case .Main: return 0
            case .Sentence: return 1
            case .Solution: return 3
            case .Other: return 4
            }
        }
    }
    
    /// 複習單字結果排列
    enum ReviewResultType: CaseIterable {
        
        case alphabet
        case updateTime
        case correctCount
        case mistakeCount
        
        /// 顯示Title
        /// - Returns: String
        func value() -> String {
            switch self {
            case .alphabet: return "字母順序"
            case .updateTime: return "更新時間"
            case .correctCount: return "正確數量"
            case .mistakeCount: return "錯誤數量"
            }
        }
    }
    
    /// GIF動畫分類資料夾
    enum AnimationGifFolder {
        
        case animation
        case background
        
        func url() -> URL? {
            
            switch self {
            case .animation: return Constant.FileFolder.animation.url()
            case .background: return Constant.FileFolder.animation.url()
            }
        }
    }
    
    /// GIF動畫Type
    enum AnimationGifType: String {
        
        case success
        case fail
        case reading
        case working
        case studing
        case search
        case palette
        case review
        case nice
        case speak
        case shudder
        case solution
        case sentence
        case others
        case talking
        case loading
        case chatting

        /// 檔案路徑
        /// - Returns: URL?
        /// - Parameter folder: AnimationGifFolder
        func fileURL(with folder: AnimationGifFolder, filename: String? = nil) -> URL? {
            
            guard let info = self.info(with: folder),
                  let backgroundFolderUrl = folder.url()
            else {
                return nil
            }
            
            return backgroundFolderUrl._appendPath(filename ?? info.filename)
        }
        
        /// 取得Settings上的資訊
        /// - Parameter folder: AnimationGifFolder
        /// - Returns: AnimationSettings?
        func info(with folder: AnimationGifFolder) -> AnimationSettings? {
            
            switch folder {
            case .animation: return Constant.SettingsJSON.animationInformations.first { $0.key == self.rawValue }
            case .background: return Constant.SettingsJSON.backgroundInformations.first { $0.key == self.rawValue }
            }
        }
    }
    
    /// [info.plist上的Key值](https://ithelp.ithome.com.tw/articles/10206444)
    enum InfoPlistKey: String {
        case CFBundleShortVersionString = "CFBundleShortVersionString"      // Version版本號 => 1.0.0
        case CFBundleVersion = "CFBundleVersion"                            // Build的代號 => 202001011
    }
    
    /// 單字內容的資料庫名稱
    enum DataTableType {
        
        case `default`(_ language: String)      // 單字的資料庫名稱 (English)
        case list(_ language: String)           // 單字列表的資料庫名稱 (EnglishList)
        case review(_ language: String)         // 複習單字列表的資料庫名稱 (EnglishReview)
        case sentence(_ language: String)       // 常用例句的資料庫名稱 (EnglishSentence)
        case bookmarkSite(_ language: String)   // 常用書籤 (EnglishBookmarkSite)
        
        /// 產生資料表名稱
        /// => English / EnglishList / EnglishReview / EnglishSentence / EnglishBookmarkSite
        /// - Returns: String
        func name() -> String {
            
            switch self {
            case .`default`(let language): return language
            case .list(let language): return "\(language)List"
            case .review(let language): return "\(language)Review"
            case .sentence(let language): return "\(language)Sentence"
            case .bookmarkSite(let language): return "\(language)BookmarkSite"
            }
        }
    }
    
    /// 自定義錯誤
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }
        
        case notOpenURL
        case notImage
        case isEmpty
        case notSupports
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {
            switch self {
            case .notOpenURL: return "打開URL錯誤"
            case .notImage: return "不是圖片檔"
            case .isEmpty: return "資料是空的"
            case .notSupports: return "功能不支援"
            }
        }
    }
    
    /// 問題等級
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
        
        case images = "Images"
        case music = "Music"
        case animation = "Animation"
        
        /// 產生URL
        /// - Returns: URL?
        func url() -> URL? { return FileManager.default._documentDirectory()?.appendingPathComponent(self.rawValue, isDirectory: false) }
    }
    
    /// 要搜尋的類型分類
    enum SearchType: Int, CaseIterable, CustomStringConvertible {
        
        var description: String { toString() }
        
        case word = 0       // 單字
        case interpret = 1  // 字義
        case alphabet = 2   // 音標字母
        
        /// 轉成中文字
        /// - Returns: String
        func toString() -> String {
            switch self {
            case .word: return "單字"
            case .interpret: return "字義"
            case .alphabet: return "音標"
            }
        }
        
        /// 轉成欄位名稱
        /// - Returns: String
        func field() -> String {
            switch self {
            case .word: return "word"
            case .interpret: return "interpret"
            case .alphabet: return "alphabet"
            }
        }
        
        /// 背景色
        /// - Returns: UIColor
        func backgroundColor() -> UIColor {
            switch self {
            case .word: return .darkGray
            case .interpret: return .systemBlue
            case .alphabet: return .systemPink
            }
        }
    }
    
    /// 單字相關的動作功能 => CRUD
    enum WordActionType {
        case append     // 新增
        case update     // 修改
        case delete     // 刪除
        case search     // 查詢
    }
    
    /// 音樂播放類型
    enum MusicLoopType {
        
        case mute
        case infinity
        case loop
        case shuffle

        /// 播放次數
        /// - Returns: Int
        func number() -> Int {
            
            switch self {
            case .mute: return 0
            case .infinity: return -1
            case .loop: return 0
            case .shuffle: return 0
            }
        }
        
        /// 說明文字
        /// - Returns: String
        func toString() -> String {
            
            switch self {
            case .mute: return "靜音"
            case .infinity: return "單曲循環"
            case .loop: return "全曲循環"
            case .shuffle: return "全曲隨機"
            }
        }
    }
    
    /// [比對用的NSPredicate](https://zh-tw.coderbridge.com/series/01d31194cb3c428d9ca2575c91e8b997/posts/11802227e6ad4e52b027d66f8f527f03)
    enum Predicate {
        
        case matches(regex: String) // [正則表達式 (正規式)](https://swift.gg/2019/11/19/nspredicate-objective-c/)

        /// [產生NSPredicate](https://www.jianshu.com/p/bfdacbdf37a7)
        /// - Returns: NSPredicate
        func build() -> NSPredicate {
            switch self {
            case .matches(let regex): return NSPredicate(format: "SELF MATCHES %@", regex)
            }
        }
    }
}
