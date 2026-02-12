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
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        DeepLinkHelper.shared.deepLinkURL(app, open: url, options: options)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        DeepLinkHelper.shared.universalLink(application, continue: userActivity)
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
        
        initAssistiveTouch(appDelegate: self, touchViewController: touchViewController)
        initAppShortcutItem(with: application)

        initAudioPlaySetting()
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
    
    /// [設定ShortcutItem](https://www.jianshu.com/p/e49b8bfea475)
    /// - Parameter application: UIApplication
    func initAppShortcutItem(with application: UIApplication) {
        
        let launchTimeShortcutItem = Utility.shared.appLaunchTimeShortcutItem(with: application)
        let versionShortcutItem = Utility.shared.appVersionShortcutItem(with: application)
        
        application.shortcutItems = [launchTimeShortcutItem, versionShortcutItem]
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
}

