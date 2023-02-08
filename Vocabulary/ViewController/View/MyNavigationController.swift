//
//  MyNavigationController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/8.
//

import UIKit
import WWPrint

protocol MyNavigationControllerDelegate {
    func refreshRootViewController()
}

// MARK: - 自定義的UINavigationController
final class MyNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotification()
    }
    
    deinit {
        wwPrint("deinit \(Self.self)")
    }
}

// MARK: - 小工具
extension MyNavigationController {
    
    /// 註冊通知功能 (資料庫變動時更新資料)
    func registerNotification() {
        
        NotificationCenter.default._register(name: Constant.notificationName) { _ in
            
            _ = self._popToRootViewController() { [weak self] in
                
                guard let this = self,
                      let myNavigationControllerDelegate = this._rootViewController() as? MyNavigationControllerDelegate
                else {
                    return
                }
                
                myNavigationControllerDelegate.refreshRootViewController()
            }
        }
    }
}
