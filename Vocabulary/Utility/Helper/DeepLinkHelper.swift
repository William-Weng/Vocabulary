//
//  DeepLinkHelper.swift
//  Vocabulary
//
//  Created by iOS on 2026/2/12.
//

import UIKit

// MARK: - DeepLinkHelper (單例)
final class DeepLinkHelper: NSObject {
    
    static let shared = DeepLinkHelper()
    
    private override init() {}
}

// MARK: - for Deep Link
extension DeepLinkHelper {
    
    /// [使用UrlScheme功能的相關設定](https://youtu.be/OyzFPrVIlQ8)
    /// => [在info.plist設定](https://cg2010studio.com/2014/11/13/ios-客製化-url-scheme-custom-url-scheme/)
    /// - Parameters:
    ///   - sceneDelegate: SceneDelegate
    ///   - url: URL
    func deepLinkURL(_ sceneDelegate: SceneDelegate, open url: URL) {
        
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
    
    /// [使用UniversalLink功能的相關設定](https://medium.com/zrealm-ios-dev/ios-deferred-deep-link-延遲深度連結實作-swift-b08ef940c196)
    /// => [在info.plist設定](https://medium.com/zrealm-ios-dev/universal-links-新鮮事-12c5026da33d)
    /// - Parameters:
    ///   - sceneDelegate: SceneDelegate
    ///   - webpageURL: URL
    func universalLink(_ sceneDelegate: SceneDelegate, webpageURL: URL) {}
    
    /// 處理推播送來的資訊
    /// - Parameters:
    ///   - sceneDelegate: SceneDelegate
    ///   - userInfo: [AnyHashable : Any]
    func pushNotification(_ sceneDelegate: SceneDelegate, userInfo: [AnyHashable : Any]) {}
}

// MARK: - 小工具
private extension DeepLinkHelper {
    
    
    /// 取得Tabbar上的ViewController
    /// - Parameters:
    ///   - index: Int
    ///   - completion: (UIViewController) -> Void
    func tabbarRootViewController(with rootViewController: Constant.TabbarRootViewController, completion: @escaping ((UIViewController) -> Void)) {
        
        guard let appDelegate = Utility.shared.appDelegate,
              let tabBarController = appDelegate.window?.rootViewController as? MyTabBarController,
              let navigationController = tabBarController.viewControllers?[safe: rootViewController.index()] as? MyNavigationController,
              let viewController = navigationController.viewControllers.first
        else {
            return
        }
        
        tabBarController.selectedIndex = rootViewController.index()
        _ = navigationController._popToRootViewController { completion(viewController) }
    }
    
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
}
