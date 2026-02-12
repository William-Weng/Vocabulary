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
import WWNetworking_UIImage
import WWNormalizeAudioPlayer

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, OrientationLockable {
    
    var window: UIWindow?
    var orientationLock: UIInterfaceOrientationMask?
    
    private lazy var touchViewController = { UIStoryboard(name: "Sub", bundle: nil).instantiateViewController(withIdentifier: "TouchViewController") as? TouchViewController }()
    
    private var recordPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    
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

    deinit {
        touchViewController?.removeFromParent()
        touchViewController = nil
        myPrint("\(Self.self) deinit")
    }
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

// MARK: - 小工具 (公開)
extension AppDelegate {
    
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
        MusicHelper.shared.initAudioPlaySetting()
        
        initAssistiveTouch(appDelegate: self, touchViewController: touchViewController)
        initAppShortcutItem(with: application)

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
}

