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

    let audioPlayer: WWNormalizeAudioPlayer = .init()
    
    var window: UIWindow?
    var orientationLock: UIInterfaceOrientationMask?
    var musicLoopType: Constant.MusicLoopType = .infinity
    
    private lazy var touchViewController = { UIStoryboard(name: "Sub", bundle: nil).instantiateViewController(withIdentifier: "TouchViewController") as? TouchViewController }()
    
    private var recordPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var currentMusic: Music?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initSetting(application, didFinishLaunchingWithOptions: launchOptions)
        initAssistiveTouch(appDelegate: self, touchViewController: touchViewController)
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

// MARK: - UIDocumentPickerDelegate
extension AppDelegate: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Utility.shared.downloadDocumentAction(controller, didPickDocumentsAt: urls)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        AssistiveTouchHelper.shared.hiddenAction(false)
    }
}

// MARK: - WWNormalizeAudioPlayer.Delegate
extension AppDelegate: WWNormalizeAudioPlayer.Deleagte {
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, callbackType: AVAudioPlayerNodeCompletionCallbackType, didFinishPlaying audioFile: AVAudioFile) {
        audioPlayerDidFinishPlayingAction(player)
    }
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, audioFile: AVAudioFile, totalTime: TimeInterval, currentTime: TimeInterval) {}
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, error: any Error) {}
}

// MARK: - 小工具 (公開)
extension AppDelegate {
    
    /// 初始化播放器設定
    func initAudioPlaySetting() {
        _ = audioPlayer.setSession(category: .playback)
        audioPlayer.delegate = self
        audioPlayer.isHiddenProgress = true
        audioPlayer.volume = 0.1
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
        
        audioPlayer.play(with: audioUrl)
        musicPlayerHint(audioPlayer)
        
        return true
    }
    
    /// 停止播放音樂
    func stopMusic() -> Bool {
        musicLoopType = .stop
        audioPlayer.stop()
        return true
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
        
        SettingHelper.shared.initSettings()
        SettingHelper.shared.initDatabase()
        initAudioPlaySetting()
        
        appShortcutItem(with: application)
        backgroundBarColor(.black.withAlphaComponent(0.1))
        
        _ = animationFolderUrlMaker()
        _ = WWWebImage.shared.cacheTypeSetting(.cache(), defaultImage: OthersTableViewCell.defaultImage)
    }
    
    /// 初始化浮動按鈕
    /// - Parameters:
    ///   - appDelegate: AppDelegate?
    ///   - viewController: UIViewController?
    func initAssistiveTouch(appDelegate: AppDelegate?, touchViewController: TouchViewController?) {
        touchViewController?.appDelegate = self
        AssistiveTouchHelper.shared.initSetting(appDelegate: appDelegate, touchViewController: touchViewController)
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
        
        let itemAppearance = UIBarButtonItemAppearance()
        itemAppearance.normal.backgroundImage = nil
    }
    
    func backgroundBarColor() {
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
        case .stop: currentMusic = nil
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

