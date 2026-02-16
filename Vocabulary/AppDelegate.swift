//
//  AppDelegate.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import WWNetworking_UIImage

// MARK: - AppDelegate
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private lazy var touchViewController = { UIStoryboard(name: "Sub", bundle: nil).instantiateViewController(withIdentifier: "TouchViewController") }()
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initSetting(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    deinit {
        touchViewController.removeFromParent()
        myPrint("\(Self.self) deinit")
    }
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
        
        initAppShortcutItem(with: application)
        
        // backgroundBarColor(.black.withAlphaComponent(0.1))
        
        _ = animationFolderUrlMaker()
        _ = WWWebImage.shared.cacheTypeSetting(.cache(), defaultImage: OthersTableViewCell.defaultImage)
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
}

