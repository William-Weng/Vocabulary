//
//  AppDelegate.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/13.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private lazy var touchViewController = { UIStoryboard(name: "Sub", bundle: nil).instantiateViewController(withIdentifier: "TouchViewController") }()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let _ = (scene as? UIWindowScene) else { return }
        
        AssistiveTouchHelper.shared.initSetting(appDelegate: self, viewController: touchViewController)
        parseUrlLink(with: scene, willConnectTo: session, options: connectionOptions)
    }
}

// MARK: - 顯示狀態
extension SceneDelegate {
    
    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}

// MARK: - 處理熱啟動 (APP已開啟) DeepLink / UniversalLink / PushNotification
extension SceneDelegate {
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        DeepLinkHelper.shared.deepLinkURL(self, open: urlContext.url)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        DeepLinkHelper.shared.universalLink(self, webpageURL: url)
    }
}

// MARK: - UNUserNotificationCenterDelegate (熱啟動)
extension SceneDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.badge, .banner, .list, .sound]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        DeepLinkHelper.shared.pushNotification(self, userInfo: userInfo)
    }
}

// MARK: - 小工具
private extension SceneDelegate {
    
    /// 處理冷啟動 (APP未開啟) DeepLink / UniversalLink / PushNotification
    /// - Parameters:
    ///   - scene: UIScene
    ///   - session: UISceneSession
    ///   - connectionOptions: UIScene.ConnectionOptions
    func parseUrlLink(with scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        if let urlContext = connectionOptions.urlContexts.first {
            DeepLinkHelper.shared.deepLinkURL(self, open: urlContext.url); return
        }
        
        if let userActivity = connectionOptions.userActivities.first, let url = userActivity.webpageURL {
            DeepLinkHelper.shared.universalLink(self, webpageURL: url); return
        }
        
        if let userActivity = connectionOptions.userActivities.first, let userInfo = userActivity.userInfo {
            DeepLinkHelper.shared.pushNotification(self, userInfo: userInfo); return
        }
    }
}
