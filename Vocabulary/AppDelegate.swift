//
//  AppDelegate.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import AVFAudio
import WWToast
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
    private var musicLoopType: Constant.MusicLoopType = .infinity
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initSetting(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        deepLinkURL(app, open: url, options: options)
        return true
    }
        
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - AVAudioPlayerDelegate
extension AppDelegate: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { audioPlayerDidFinishPlayingAction(player, successfully: flag) }
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) { replayMusic(with: player) }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) { if let error = error { myPrint(error) }}
}

// MARK: - AVAudioRecorderDelegate
extension AppDelegate: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        guard let recordlayer = AVAudioPlayer._build(audioURL: recorder.url, fileTypeHint: .wav, delegate: nil) else { return }
        
        self.recordlayer = recordlayer
        recordlayer.play()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) { myPrint(error) }
}

// MARK: - 小工具 (公開)
extension AppDelegate {
        
    /// [初始化資料表 / 資料庫](https://apppeterpan.medium.com/還模擬器一個乾乾淨淨的-xcode-console-a630992448d5)
    func initDatabase() {
        
        let result = WWSQLite3Manager.shared.connent(for: .documents, filename: Constant.databaseName)
        
        switch result {
        case .failure(_): Utility.shared.flashHUD(with: .fail)
        case .success(let database):
            
            Constant.database = database
            Constant.SettingsJSON.generalInformations.forEach { info in _ = createDatabase(database, info: info) }
            
            myPrint(database.fileURL)
        }
    }
    
    /// 初始化設定值 => Settings.json
    func initSettings() {
        
        guard let parseSettingsDictionary = parseSettingsDictionary(with: Constant.settingsJSON),
              let dictionary = settingsDictionary(with: Constant.tableName, dictionary: parseSettingsDictionary),
              let settings = dictionary["settings"] as? [String: Any]
        else {
            return
        }
        
        Constant.tableNameIndex = Utility.shared.tableNameIndex(Constant.tableName)
                
        Constant.SettingsJSON.generalInformations = generalInformations(with: parseSettingsDictionary)
        Constant.SettingsJSON.vocabularyLevelInformations = vocabularyLevelInformations(with: settings)
        Constant.SettingsJSON.sentenceSpeechInformations = sentenceSpeechInformations(with: settings)
        Constant.SettingsJSON.wordSpeechInformations = wordSpeechInformations(with: settings)
        Constant.SettingsJSON.animationInformations = animationInformations(with: settings)
        Constant.SettingsJSON.backgroundInformations = backgroundInformations(with: settings)
    }
    
    /// 解析預設的SettingsJSON的設定檔
    /// - Parameter filename: String
    /// - Returns: String?
    func parseDefaultSettingsJSON(with filename: String) -> String? {
        
        guard let fileURL = Optional.some(Bundle.main.bundleURL.appendingPathComponent(filename)),
              let jsonString = FileManager.default._readText(from: fileURL)
        else {
            return nil
        }
        
        return jsonString
    }
    
    /// 解析使用者自訂的SettingsJSON的設定檔
    /// - Parameter filename: String
    /// - Returns: String?
    func parseUserSettingsJSON(with filename: String) -> String? {
        
        guard let url = FileManager.default._documentDirectory()?.appendingPathComponent(Constant.settingsJSON),
              let jsonString = FileManager.default._readText(from: url)
        else {
            return nil
        }
        
        return jsonString
    }
    
    /// [重新播放音樂](https://juejin.cn/post/7163440404480655367)
    /// - Parameter notificaiton: Notification
    func replayMusic(with player: AVAudioPlayer) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let this = self else { return }
            player._play(queue: this.audioPlayerQueue)
        }
    }
    
    /// 播放背景音樂
    /// - Parameters:
    ///   - music: 音樂檔案
    ///   - volume: 音量大小
    ///   - loopType: MusicLoopType
    /// - Returns: Bool
    func playBackgroundMusic(with music: Music?, volume: Float, musicLoopType: Constant.MusicLoopType) -> Bool {
                
        _ = stopMusic()
        self.musicLoopType = musicLoopType
                
        guard let music = music,
              let audioPlayer = musicPlayerMaker(with: music)
        else {
            return false
        }
        
        self.audioPlayer = audioPlayer
        
        audioPlayer.volume = volume
        audioPlayer.numberOfLoops = musicLoopType.number()
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        audioPlayer._play(queue: audioPlayerQueue)
        
        return true
    }
    
    /// 停止播放音樂
    func stopMusic() -> Bool {
        
        audioPlayer?.stop()
        audioPlayer = nil
        
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
    /// - Returns: Bool
    func recordWave() -> Bool {
        guard let recordURL = FileManager.default._temporaryDirectory()._appendPath(Constant.recordFilename) else { return false }
        return recordSound(with: recordURL)
    }
    
    /// 停止錄製聲音
    /// - Returns: Bool
    func stopRecordingWave() -> Bool { stopRecorder() }
}

// MARK: - 小工具
private extension AppDelegate {
    
    /// 初始化設定
    /// - Parameters:
    ///   - application: UIApplication
    ///   - launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    func initSetting(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
                
        initSettings()
        initDatabase()
        
        backgroundPlayAudio()
        appShortcutItem(with: application)
        backgroundBarColor(.black.withAlphaComponent(0.1))
        
        _ = animationFolderUrlMaker()
        _ = WWWebImage.initDatabase(for: .caches, expiredDays: Constant.webImageExpiredDays)
    }
        
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
    
    /// 建立存放GIF動畫的資料夾
    /// - Returns: 資料夾的URL
    func animationFolderUrlMaker() -> URL? {
        
        guard let musicFolderUrl = Constant.FileFolder.animation.url() else { return nil }
        
        let result = FileManager.default._createDirectory(with: musicFolderUrl, path: "")
        
        switch result {
        case .failure(let error): myPrint(error); return nil
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
                
        musicPlayerHint(audioPlayer)
        
        return audioPlayer
    }
    
    /// [音樂檔名提示](http://furnacedigital.blogspot.com/2010/12/avfoundation.html)
    /// - Parameter player: AVAudioPlayer
    func musicPlayerHint(_ player: AVAudioPlayer) {
        
        guard let window = self.window,
              let filename = player.url?.lastPathComponent,
              let duration = player.duration._time(unitsStyle: .positional)
        else {
            return
        }
        
        let backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        WWToast.shared.makeText(targetFrame: window.frame, text: "[\(duration)] \(filename)", backgroundColor: backgroundColor)
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
        case .failure(let error): myPrint(error); return false
        case .success(let isSuccess): return isSuccess
        }
    }
    
    /// 停止錄音
    /// - Returns: Bool
    func stopRecorder() -> Bool {
        
        guard let result = audioRecorder?._stop() else { return false }
        
        switch result {
        case .failure(let error): myPrint(error); return false
        case .success(let isSuccess): return isSuccess
        }
    }
    
    /// [背景播放音樂 => Background Modes](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/設定-background-mode-在背景播放音樂-9bab5db75cc9)
    func backgroundPlayAudio() { try? AVAudioSession.sharedInstance().setCategory(.playback) }
    
    /// 音樂播完後的動作 => 全曲隨機 / 全曲循環
    /// - Parameters:
    ///   - player: AVAudioPlayer
    ///   - flag: Bool
    func audioPlayerDidFinishPlayingAction(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        guard (player == audioPlayer) else { return }
        
        let currentMusic: Music?
        
        switch musicLoopType {
        case .mute: currentMusic = nil
        case .infinity: currentMusic = nil
        case .loop: currentMusic = Constant.playingMusicList._popFirst()
        case .shuffle: currentMusic = Constant.playingMusicList.popLast()
        }
        
        if (Constant.playingMusicList.isEmpty) { Constant.playingMusicList = Utility.shared.musicList(for: musicLoopType) }
        _ = playBackgroundMusic(with: currentMusic, volume: Constant.volume, musicLoopType: musicLoopType)
    }
    
    /// [設定ShortcutItem](https://www.jianshu.com/p/e49b8bfea475)
    /// - Parameter application: UIApplication
    func appShortcutItem(with application: UIApplication) {
        
        let launchTimeShortcutItem = appLaunchTimeShortcutItem(with: application)
        let versionShortcutItem = appVersionShortcutItem(with: application)
        
        application.shortcutItems = [launchTimeShortcutItem, versionShortcutItem]
    }
    
    /// 產生版本號的ShortcutItem
    /// - Parameter application: UIApplication
    /// - Returns: UIApplicationShortcutItem
    func appVersionShortcutItem(with application: UIApplication) -> UIApplicationShortcutItem {
        
        let version = Bundle.main._appVersion()
        let installType = WWAppInstallSource.shared.detect() ?? .Simulator
        let info = UIDevice._systemInformation()
        let icon = UIApplicationShortcutIcon(type: .confirmation)
        let title = "v\(version.app) (\(version.build))"
        let subtitle = "\(info.name) \(info.version) by \(installType.rawValue)"
        let shortcutItem = UIApplicationShortcutItem._build(localizedTitle: title, localizedSubtitle: subtitle, icon: icon)
        
        return shortcutItem
    }
    
    /// 產生該上次使用時間的ShortcutItem
    /// - Parameter application: UIApplication
    /// - Returns: UIApplicationShortcutItem
    func appLaunchTimeShortcutItem(with application: UIApplication) -> UIApplicationShortcutItem {
        
        let icon = UIApplicationShortcutIcon(type: .time)
        let title = "上次使用時間"
        let subtitle = "\(Date()._localTime(timeZone: .current))"
        let shortcutItem = UIApplicationShortcutItem._build(localizedTitle: title, localizedSubtitle: subtitle, icon: icon)
        
        return shortcutItem
    }
}

// MARK: - Settings.json
private extension AppDelegate {
        
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
    
    /// 解析完整的SettingsJSON的設定檔
    /// - Returns: [String: Any]?
    func parseSettingsDictionary(with filename: String) -> [String: Any]? {
                
        guard var jsonString = parseDefaultSettingsJSON(with: filename) else { return nil }
        if let _jsonString = parseUserSettingsJSON(with: filename) { jsonString = _jsonString }
        
        return jsonString._jsonObject() as? [String: Any]
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

// MARK: - for Deep Link
private extension AppDelegate {
    
    /// [使用UrlScheme功能的相關設定](https://youtu.be/OyzFPrVIlQ8)
    /// => [在info.plist設定](https://cg2010studio.com/2014/11/13/ios-客製化-url-scheme-custom-url-scheme/)
    /// - Parameters:
    ///   - app: UIApplication
    ///   - url: URL
    ///   - options: [UIApplication.OpenURLOptionsKey : Any]
    func deepLinkURL(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) {
        
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
        case .search: searchWord(with: components)
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
        _ = navigationController._popToRootViewController { completion(viewController) }
    }
}

// MARK: - Deep Link Action
private extension AppDelegate {
    
    /// 由DeepLink功能加入新單字 (word://append/<單字>)
    /// - Parameter components: URLComponents
    func appendWord(with components: URLComponents) {
        
        guard let word = components.path.split(separator: "/").first else { return }
        
        tabbarRootViewController(with: Constant.TabbarRootViewController.Main) { viewController in
            if let viewController = viewController as? MainViewController { viewController.appendWord(with: String(word)) }
        }
    }
    
    /// 由DeepLink功能搜尋該單字 (word://search/<單字>)
    /// - Parameter components: URLComponents
    func searchWord(with components: URLComponents) {
        
        guard let word = components.path.split(separator: "/").first else { return }
        
        tabbarRootViewController(with: Constant.TabbarRootViewController.Main) { viewController in
            if let viewController = viewController as? MainViewController { viewController.searchWord(with: String(word)) }
        }
    }
}

