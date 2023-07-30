//
//  AppDelegate.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import AVFAudio
import WWPrint
import WWSQLite3Manager
import WWNetworking_UIImage
import WWAppInstallSource

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private let audioPlayerQueue = DispatchQueue(label: "github.com/William-Weng/Vocabulary")
    
    private var audioPlayer: AVAudioPlayer?
    private var recordlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initSetting(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        deepLinkURL(url)
        return true
    }
    
    @objc func replayMusic(_ notificaiton: Notification) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let this = self else { return }
            this.audioPlayer?._play(queue: this.audioPlayerQueue)
        }
    }
    
    deinit { wwPrint("\(Self.self) deinit", isShow: Constant.isPrint) }
}

// MARK: - AVAudioRecorderDelegate
extension AppDelegate: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        guard let recordlayer = AVAudioPlayer._build(audioURL: recorder.url, fileTypeHint: .wav, delegate: nil) else { return }
        
        self.recordlayer = recordlayer
        recordlayer.play()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) { wwPrint(error, isShow: Constant.isPrint) }
}

// MARK: - 小工具
extension AppDelegate {
    
    /// 初始化設定
    /// - Parameters:
    ///   - application: UIApplication
    ///   - launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    func initSetting(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        
        _ = WWWebImage.initDatabase(for: .caches, expiredDays: 90)
        
        initCurrentTableName()
        initDatabase()
        backgroundPlayAudio()
        appVersionShortcutItem(with: application)
        
        backgroundBarColor(.black.withAlphaComponent(0.1))
        audioInterruptionNotification()
        
        _ = animationFolderUrlMaker()
    }
    
    /// 初始化資料表 / 資料庫
    func initDatabase() {
        
        let result = WWSQLite3Manager.shared.connent(for: .documents, filename: Constant.databaseName)
        
        switch result {
        case .failure(_): Utility.shared.flashHUD(with: .fail)
        case .success(let database):
            
            Constant.database = database
            Constant.VoiceCode.allCases.forEach { _ = createDatabase(database, for: $0) }
            
            wwPrint(database.fileURL, isShow: Constant.isPrint)
        }
    }
    
    /// 播放背景音樂
    /// - Parameters:
    ///   - music: 音樂檔案
    ///   - volume: 音量大小
    /// - Returns: Bool
    func playBackgroundMusic(with music: Music, volume: Float) -> Bool {
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        guard let audioPlayer = musicPlayerMaker(with: music) else { return false }
        
        self.audioPlayer = audioPlayer
        
        audioPlayer.volume = volume
        audioPlayer.numberOfLoops = -1
        audioPlayer.prepareToPlay()
        audioPlayer._play(queue: audioPlayerQueue)
        
        return true
    }
    
    /// 取得背景音樂音量大小
    /// - Returns: Float
    func musicVolume() -> Float? { return audioPlayer?.volume }
    
    /// 設定背景音樂聲音大小
    /// - Parameter volume: Float
    /// - Returns: Float
    func musicVolumeSetting(_ volume: Float) -> Float? {
        Constant.volume = volume
        audioPlayer?.volume = Constant.volume
        return musicVolume()
    }
    
    /// 錄製聲音
    func recordWave() -> Bool {
        guard let recordURL = FileManager.default._temporaryDirectory()._appendPath("record.wav") else { return false }
        return recordSound(with: recordURL)
    }
    
    /// 停止錄製聲音
    /// - Returns: Bool
    func stopRecordingWave() -> Bool { stopRecorder() }
}

// MARK: - 小工具
private extension AppDelegate {
    
    /// 取得之前設定的資料庫名稱
    func initCurrentTableName() {
        
        guard let tableName = Constant.tableName,
              let voiceCode = Constant.VoiceCode(rawValue: tableName)
        else {
            return
        }
        
        Constant.currentTableName = voiceCode
    }
    
    /// 建立該語言的資料庫群
    /// - Parameters:
    ///   - database: SQLite3Database
    ///   - tableName: Constant.VoiceCode
    /// - Returns: [SQLite3Database.ExecuteResult]
    func createDatabase(_ database: SQLite3Database, for tableName: Constant.VoiceCode) -> [SQLite3Database.ExecuteResult] {
        
        let result = [
            database.create(tableName: tableName.rawValue, type: Vocabulary.self, isOverwrite: false),
            database.create(tableName: tableName.vocabularyList(), type: VocabularyList.self, isOverwrite: false),
            database.create(tableName: tableName.vocabularyReviewList(), type: VocabularyReviewList.self, isOverwrite: false),
            database.create(tableName: tableName.vocabularySentenceList(), type: VocabularySentenceList.self, isOverwrite: false),
            database.create(tableName: tableName.bookmarks(), type: BookmarkSite.self, isOverwrite: false),
        ]
        
        return result
    }
    
    /// 建立存放GIF動畫的資料夾
    /// - Returns: 資料夾的URL
    func animationFolderUrlMaker() -> URL? {
        
        guard let musicFolderUrl = Constant.FileFolder.animation.url() else { return nil }
        
        let result = FileManager.default._createDirectory(with: musicFolderUrl, path: "")
        
        switch result {
        case .failure(let error): wwPrint(error, isShow: Constant.isPrint); return nil
        case .success(let isSuccess): return (!isSuccess) ? nil : musicFolderUrl
        }
    }
    
    /// 設定Bar的背景色
    /// - Parameter color: UIColor
    func backgroundBarColor(_ color: UIColor) {
        UINavigationBar.appearance()._backgroundColor(color)
        UITabBar.appearance()._backgroundColor(color)
    }
    
    /// 音樂播放器
    /// - Parameter music: Music
    /// - Returns: AVAudioPlayer?
    func musicPlayerMaker(with music: Music) -> AVAudioPlayer? {
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        guard let audioURL = music.fileURL(),
              let audioPlayer = AVAudioPlayer._build(audioURL: audioURL, fileTypeHint: music.fileType(), delegate: nil)
        else {
            return nil
        }
        
        return audioPlayer
    }
    
    /// 註冊音樂被中斷的通知 (Safari播放單字聲音時，音樂會被中斷)
    func audioInterruptionNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(Self.replayMusic(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    /// 開始錄音 (.wav)
    /// - Parameter recordURL: URL
    /// - Returns: Bool
    func recordSound(with recordURL: URL) -> Bool {
        
        _ = audioRecorder?._stop()
        
        guard let audioRecorder = AVAudioRecorder._build(recordURL: recordURL) else { return false }

        self.audioRecorder = audioRecorder
        audioRecorder.delegate = self
        
        let result = audioRecorder._record()
        
        switch result {
        case .failure(let error): wwPrint(error, isShow: Constant.isPrint); return false
        case .success(let isSuccess): return isSuccess
        }
    }
    
    /// 停止錄音
    /// - Returns: Bool
    func stopRecorder() -> Bool {
        
        guard let result = audioRecorder?._stop() else { return false }
        
        switch result {
        case .failure(let error): wwPrint(error, isShow: Constant.isPrint); return false
        case .success(let isSuccess): return isSuccess
        }
    }
    
    /// [背景播放音樂 => Background Modes](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/設定-background-mode-在背景播放音樂-9bab5db75cc9)
    func backgroundPlayAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    /// 設定ShortcutItem
    /// - Parameter application: UIApplication
    func appVersionShortcutItem(with application: UIApplication) {
        
        let version = Bundle.main._appVersion()
        let installType = WWAppInstallSource.shared.detect() ?? .Simulator
        let info = UIDevice._systemInformation()
        let icon = UIApplicationShortcutIcon(type: .love)
        let title = "v\(version.app ?? "0.0.0") (\(version.build ?? "0"))"
        let subtitle = "\(info.name) \(info.version) for \(installType.rawValue)"
        let shortcutItem = UIApplicationShortcutItem._build(localizedTitle: title, localizedSubtitle: subtitle, icon: icon)
        
        application.shortcutItems = [shortcutItem]
    }
}

// MARK: - for Deep Link
extension AppDelegate {
    
    /// [使用UrlScheme功能的相關設定](https://youtu.be/OyzFPrVIlQ8)
    /// => [在info.plist設定](https://cg2010studio.com/2014/11/13/ios-客製化-url-scheme-custom-url-scheme/)
    func deepLinkURL(_ url: URL) {
        
        guard let components = url._components(),
              Constant.urlScheme == components.scheme?.lowercased()
        else {
            return
        }
        
        guard let host = components.host?.lowercased(),
              let action = Constant.DeepLinkAction(rawValue: host)
        else {
            return
        }
        
        switch action {
        case .append: appendWord(with: components)
        }
    }
    
    /// 由DeepLink功能加入新單字 (word://append/<新單字>)
    /// - Parameter components: URLComponents
    func appendWord(with components: URLComponents) {

        guard let word = components.path.split(separator: "/").first else { return }
        
        tabbarRootViewController(with: Constant.TabbarRootViewController.Main) { viewController in
            if let viewController = viewController as? MainViewController { viewController.appendWord(with: String(word)) }
        }
    }
    
    /// 取得Tabbar上的ViewController
    /// - Parameters:
    ///   - index: Int
    ///   - completion: (UIViewController) -> Void
    func tabbarRootViewController(with rootViewController: Constant.TabbarRootViewController, completion: @escaping ((UIViewController) -> Void)) {
        
        guard let tabBarController = window?.rootViewController as? MyTabBarController,
              let navigationController = tabBarController.viewControllers?[safe: rootViewController.index()] as? MyNavigationController,
              let viewController = navigationController.viewControllers.first
        else {
            return
        }
        
        tabBarController.selectedIndex = rootViewController.index()
        
        _ = navigationController._popToRootViewController {
            completion(viewController)
        }
    }
}

