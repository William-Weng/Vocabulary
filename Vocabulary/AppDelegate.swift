//
//  AppDelegate.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//
// [defaults write com.apple.dt.Xcode DVTEnableCoreDevice enabled / defaults delete com.apple.dt.Xcode DVTEnableCoreDevice](https://github.com/filsv/iOSDeviceSupport)
// override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
// override var shouldAutorotate: Bool { return false }

import UIKit
import AVFAudio
import WWPrint
import WWToast
import WWSQLite3Manager
import WWNetworking_UIImage
import WWAppInstallSource
import WWAssistiveTouch
import WWNormalizeAudioPlayer

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, OrientationLockable {
    
    var window: UIWindow?
    var orientationLock: UIInterfaceOrientationMask?
    var assistiveTouch: WWAssistiveTouch!

    private let audioPlayer: WWNormalizeAudioPlayer = .init()
    
    private lazy var touchViewController = { UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TouchViewController") }()
    
    private var recordPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var musicLoopType: Constant.MusicLoopType = .infinity
    private var currentMusic: Music?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initSetting(application, didFinishLaunchingWithOptions: launchOptions)
        initAssistiveTouch(window: window, touchViewController: touchViewController)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        deepLinkURL(app, open: url, options: options)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        universalLink(application, continue: userActivity)
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock ?? .all
    }

    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - AVAudioRecorderDelegate
extension AppDelegate: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        guard let recordlayer = AVAudioPlayer._build(audioURL: recorder.url, fileTypeHint: .wav, delegate: nil) else { return }
                
        self.recordPlayer = recordlayer
        recordlayer.play()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) { myPrint(error) }
}

// MARK: - WWAssistiveTouch.Delegate
extension AppDelegate: WWAssistiveTouch.Delegate {
    
    func assistiveTouch(_ assistiveTouch: WWAssistiveTouch, isTouched: Bool) {
        if (isTouched) { assistiveTouch.display() }
    }
    
    func assistiveTouch(_ assistiveTouch: WWAssistiveTouch, status: WWAssistiveTouch.Status) {}
}

// MARK: - WWNormalizeAudioPlayer.Delegate
extension AppDelegate: WWNormalizeAudioPlayer.Deleagte {
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, callbackType: AVAudioPlayerNodeCompletionCallbackType, didFinishPlaying audioFile: AVAudioFile) {
        print("== \(musicLoopType) ==")
        audioPlayerDidFinishPlayingAction(player)
    }
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, audioFile: AVAudioFile, totalTime: TimeInterval, currentTime: TimeInterval) {}
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, error: any Error) {}
}

// MARK: - 小工具 (公開)
extension AppDelegate {
    
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
        
        guard let parseSettingsDictionary = parseSettingsDictionary(with: Constant.settingsJSON),
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
    
    /// 初始化播放器設定
    func initAudioPlaySetting() {
        audioPlayer.delegate = self
        audioPlayer.isHiddenProgress = true
        audioPlayer.volume = 0.1
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
}

// MARK: - 小工具 (公開)
extension AppDelegate {
    
    /// 播放音樂
    /// - Parameters:
    ///   - music: 音樂檔案
    ///   - volume: 音量大小
    ///   - loopType: MusicLoopType
    /// - Returns: Bool
    func playMusic(with music: Music?, volume: Float, musicLoopType: Constant.MusicLoopType) -> Bool {
        
        guard let music = music,
              let audioUrl = music.fileURL()
        else {
            return false
        }
        
        self.currentMusic = music
        self.musicLoopType = musicLoopType
        
        print("<< \(audioUrl.lastPathComponent) >>")
        
        audioPlayer.play(with: audioUrl)
        musicPlayerHint(audioPlayer)
        
        return true
    }
    
    /// 停止播放音樂
    func stopMusic() -> Bool {
        musicLoopType = .mute
        audioPlayer.stop()
        return true
    }
    
    /// 取得背景音樂音量大小
    /// - Returns: Float
    func musicVolume() -> Float { return audioPlayer.volume }
    
    /// 設定背景音樂聲音大小
    /// - Parameter volume: Float
    /// - Returns: Float
    func musicVolumeSetting(_ volume: Float) -> Float {
        Constant.volume = volume
        audioPlayer.volume = Constant.volume
        return audioPlayer.volume
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

// MARK: - TouchView
extension AppDelegate {
    
    /// AssistiveTouch是否顯示
    /// - Parameter isHidden: Bool
    func assistiveTouchHidden(_ isHidden: Bool) {
        
        let this = self
        assistiveTouch.alpha = isHidden ? 1.0 : 0.0

        let animator = UIViewPropertyAnimator(duration: Constant.replay, curve: .easeInOut) {
            this.assistiveTouch.alpha = !isHidden ? 1.0 : 0.0
        }
        
        if !isHidden {
            assistiveTouch.isHidden = false
        } else {
            animator.addCompletion { _ in this.assistiveTouch.isHidden = true }
        }
        
        animator.startAnimation()
    }
    
    /// 彈出畫筆工作列
    func pencelToolPicker() {
        NotificationCenter.default._post(name: .displayCanvasView, object: nil)
    }
    
    /// 彈出錄音界面
    func recording() {
        _ = Utility.shared.presentViewController(target: window?.rootViewController, identifier: "TalkingViewController")
    }
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
        initAudioPlaySetting()
        
        appShortcutItem(with: application)
        backgroundBarColor(.black.withAlphaComponent(0.1))
        if #available(iOS 26.0, *) { backgroundBarColor(.clear) }
        
        _ = animationFolderUrlMaker()
        _ = WWWebImage.shared.cacheTypeSetting(.cache(), defaultImage: OthersTableViewCell.defaultImage)
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
        
        guard let animationFolderUrl = Constant.FileFolder.animation.url() else { return nil }
        
        let result = FileManager.default._createDirectory(with: animationFolderUrl, path: "")
        
        switch result {
        case .failure(let error): myPrint(error); return nil
        case .success(let isSuccess): return (!isSuccess) ? nil : animationFolderUrl
        }
    }
    
    /// 設定Bar的背景色
    /// - Parameter color: UIColor
    func backgroundBarColor(_ color: UIColor) {
        UINavigationBar.appearance()._backgroundColor(color)
        UITabBar.appearance()._backgroundColor(color)
    }
    
    /// [音樂檔名提示](http://furnacedigital.blogspot.com/2010/12/avfoundation.html)
    /// - Parameter player: WWNormalizeAudioPlayer
    func musicPlayerHint(_ player: WWNormalizeAudioPlayer) {
        
        guard let window = self.window,
              let time = player.totalTime()._time(unitsStyle: .positional, allowedUnits: [.minute, .second], behavior: .pad)
        else {
            return
        }
        
        let text = "[\(time)] \(player.audioFile.url.lastPathComponent)"
        let backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        WWToast.shared.setting(backgroundViewColor: backgroundColor)
        WWToast.shared.makeText(text, targetFrame: window.frame)
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
    
    /// 音樂播完後的動作 => 全曲隨機 / 全曲循環
    /// - Parameters:
    ///   - player: AVAudioPlayer
    ///   - flag: Bool
    func audioPlayerDidFinishPlayingAction(_ player: WWNormalizeAudioPlayer) {
        
        switch musicLoopType {
        case .infinity: break
        case .mute: currentMusic = nil
        case .loop: currentMusic = Constant.playingMusicList._popFirst()
        case .shuffle: currentMusic = Constant.playingMusicList.popLast()
        }
        
        if (Constant.playingMusicList.isEmpty) { Constant.playingMusicList = Utility.shared.musicList(for: musicLoopType) }
        _ = playMusic(with: currentMusic, volume: Constant.volume, musicLoopType: musicLoopType)
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

// MARK: - PencilKit
private extension AppDelegate {
    
    /// 初始化浮動按鈕
    /// - Parameters:
    ///   - window: UIWindow?
    ///   - viewController: UIViewController?
    func initAssistiveTouch(window: UIWindow?, touchViewController: UIViewController?) {
        
        guard let window, let touchViewController else { return }
        
        let size = CGSize(width: 56, height: 56)
        let origin = CGPoint(x: window.bounds.width, y: window.bounds.height - 216)
        
        assistiveTouch = WWAssistiveTouch(touchViewController: touchViewController, frame: .init(origin: origin, size: size), icon: .touchMain, isAutoAdjust: true, delegate: self)
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
        case .icon: alternateAppIcon(with: components)
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
        
        tabbarRootViewController(with: .Main) { viewController in
            if let viewController = viewController as? MainViewController { viewController.appendWord(with: String(word)) }
        }
    }
    
    /// 由DeepLink功能搜尋該單字 (word://search/<單字>)
    /// - Parameter components: URLComponents
    func searchWord(with components: URLComponents) {
        
        guard let word = components.path.split(separator: "/").first else { return }
        
        tabbarRootViewController(with: .Main) { viewController in
            if let viewController = viewController as? MainViewController { viewController.searchWord(with: String(word)) }
        }
    }
    
    /// 由DeepLink功能更新APP圖示 (word://icon/<index>)
    /// - Parameter components: URLComponents
    func alternateAppIcon(with components: URLComponents) {
                
        guard let index = components.path.split(separator: "/").first else { return }
        
        tabbarRootViewController(with: .Main) { viewController in
            if let viewController = viewController as? MainViewController { viewController.alternateIcons(with: String(index)) }
        }
    }
    
    /// [使用UniversalLink功能的相關設定](https://medium.com/zrealm-ios-dev/ios-deferred-deep-link-延遲深度連結實作-swift-b08ef940c196)
    /// => [在info.plist設定](https://medium.com/zrealm-ios-dev/universal-links-新鮮事-12c5026da33d)
    /// - Parameters:
    ///   - app: UIApplication
    ///   - userActivity: NSUserActivity
    func universalLink(_ application: UIApplication, continue userActivity: NSUserActivity) {}
}

