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
    
    @WWUserDefaults("CurrentTableName") static var tableName: String?
    
    static let webImageExpiredDays = 90
    static let duration: TimeInterval = 0.15
    static let autoBackupDays = 7
    static let searchCount = 10
    static let autoBackupDelaySecond: TimeInterval = 2
    static let searchDelayTime: TimeInterval = 0.3
    static let databaseName = "Vocabulary.db"
    static let databaseFileExtension = "db"
    static let urlScheme = "word"
    static let reload = "重新讀取"
    static let noDataUpdate = "無更新資料"
    static let recordFilename = "record.wav"
    static let settingsJSON = "Settings.json"
    
    static var volume: Float = 0.1
    static var speakingSpeed: Float = 0.4
    static var updateScrolledHeight: CGFloat = 128.0
    static var updateSearchScrolledHeight: CGFloat = 96.0
    static var database: SQLite3Database?
    static var backupDirectory = FileManager.default._documentDirectory()
    static var musicFileList: [String]?
    static var playingMusicList: [Music] = []
    static var vocabularyLevelInformations: [VocabularyLevelInformation] = []
    static var sentenceSpeechInformations: [SentenceSpeechInformation] = []
    static var wordSpeechInformations: [WordSpeechInformation] = []
    
    static var isPrint: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var currentTableName: Constant.VoiceCode = .english {
        didSet {
            tableName = currentTableName.rawValue
            NotificationCenter.default._post(name: .refreshViewController)
        }
    }
}

// MARK: - Typealias
extension Constant {
    
    typealias ExampleInfomation = (id: Int, interpret: String, example: String, translate: String)              // 單字ID / 字義 / 例句 / 例句翻譯
    typealias GIFImageInformation = (index: Int, cgImage: CGImage, pointer: UnsafeMutablePointer<Bool>)         // GIF動畫: (第幾張, CGImage, UnsafeMutablePointer<Bool>)
    typealias FileInfomation = (isExist: Bool, isDirectory: Bool)                                               // 檔案相關資訊 (是否存在 / 是否為資料夾)
    typealias AppVersion = (app: String, build: String)                                                         // APP版本號 (公開版號, 內測版號)
    typealias SystemInformation = (name: String, version: String, model: String, idiom: UIUserInterfaceIdiom)   // 系統資訊 => (iOS, 12.1, iPhone, 0)
    typealias KeyboardInfomation = (duration: Double, curve: UInt, frame: CGRect)                               // 取得系統鍵盤的相關資訊
    typealias RGBAInformation = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)                                       // [RGBA色彩模式的數值](https://stackoverflow.com/questions/28644311/how-to-get-the-rgb-code-int-from-an-uicolor-in-swift)
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
    }
    
    /// 能夠設定顏色的Settings設定檔
    enum SettingsColorKey: String {
        
        case vocabularyLevel
        case sentenceSpeech
        case wordSpeech
        
        /// 顯示名稱
        /// - Returns: String
        func name() -> String {
            switch self {
            case .vocabularyLevel: return "單字等級"
            case .sentenceSpeech: return "精選例句"
            case .wordSpeech: return "單字型態"
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
    
    /// HUD動畫Type
    enum HudGifType: String {
        
        case success = "Success.gif"
        case fail = "Fail.gif"
        case reading = "Reading.gif"
        case working = "Working.gif"
        case studing = "Studing.gif"
        case search = "Search.gif"
        case review = "Review.gif"
        case nice = "Nice.gif"
        case speak = "Speak.gif"
        case shudder = "Shudder.gif"
        case solution = "Solution.gif"
        case sentence = "Sentence.gif"
        case others = "Others.gif"
        case download = "Download.gif"
        case talking = "Talking.gif"

        /// 檔案路徑
        /// - Returns: URL?
        func fileURL() -> URL? {
            let backgroundFolderUrl = Constant.FileFolder.animation.url()
            return backgroundFolderUrl?._appendPath(self.rawValue)
        }
    }
    
    /// [info.plist上的Key值](https://ithelp.ithome.com.tw/articles/10206444)
    enum InfoPlistKey: String {
        case CFBundleShortVersionString = "CFBundleShortVersionString"      // Version版本號 => 1.0.0
        case CFBundleVersion = "CFBundleVersion"                            // Build的代號 => 202001011
    }
    
    /// 單字內容的資料庫名稱
    enum VoiceCode: String, CaseIterable {
        
        case english = "English"
        case japanese = "Japenese"
        case french = "French"
        case korean = "Korean"
        
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
            }
        }
        
        /// [找出定義或字源的URL](https://youtu.be/cC1tlq5NUHM)
        /// - Parameter word: 要查詢的單字
        /// - Returns: String
        func defineVocabularyURL(with word: String) -> String {
            return "https://www.google.com/search?q=define+\(word)"
        }
        
        /// 字典名稱
        /// - Returns: String
        func name() -> String {
            
            switch self {
            case .english: return "\(flagEmoji()) 英文字典"
            case .japanese: return "\(flagEmoji()) 日文字典"
            case .french: return "\(flagEmoji()) 法文字典"
            case .korean: return "\(flagEmoji()) 韓文字典"
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
            case .korean: return 300
            }
        }
    }
    
    /// 自定義錯誤
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }
        
        case notOpenURL
        case notImage
        case isEmpty
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {
            switch self {
            case .notOpenURL: return "打開URL錯誤"
            case .notImage: return "不是圖片檔"
            case .isEmpty: return "資料是空的"
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
        
        case word = 0       // 單字
        case interpret = 1  // 字義
        
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
