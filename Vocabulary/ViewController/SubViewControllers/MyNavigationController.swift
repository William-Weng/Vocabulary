//
//  MyNavigationController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/8.
//

import UIKit
import WWPrint

// MARK: - MyNavigationControllerDelegate
protocol MyNavigationControllerDelegate {
    func refreshRootViewController()
}

// MARK: - 自定義的UINavigationController
final class MyNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshViewControllerNotification()
    }
    
    deinit {
        NotificationCenter.default._remove(observer: self, name: .refreshViewController)
        wwPrint("\(Self.self) deinit", isShow: Constant.isPrint)
    }
}

// MARK: - 小工具
extension MyNavigationController {
    
    /// 註冊通知功能 (語言變動時更新資料)
    func refreshViewControllerNotification() {
        
        NotificationCenter.default._register(name: .refreshViewController) { _ in
            
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
