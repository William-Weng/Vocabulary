//
//  MyTabBarController.swift
//  Vocabulary
//
//  Created by iOS on 2023/2/16.
//

import UIKit
import WWPrint

// MARK: - 自定義的UITabBarController
final class MyTabBarController: UITabBarController {
    
    static var isHidden = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewWillTransitionAction(to: size, with: coordinator)
    }
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
private extension MyTabBarController {
    
    /// 畫面旋轉後，要修正的事情 => 隱藏
    /// - Parameters:
    ///   - size: CGSize
    ///   - coordinator: UIViewControllerTransitionCoordinator
    func viewWillTransitionAction(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate { [weak self] _ in
            
            guard let this = self else { return }
                        
            this._tabBarHidden(Self.isHidden)
            NotificationCenter.default._post(name: .viewDidTransition, object: Self.isHidden)
        }
    }
}
