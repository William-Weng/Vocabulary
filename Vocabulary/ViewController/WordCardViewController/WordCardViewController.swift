//
//  WordCardViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2024/2/11.
//

import UIKit
import WWPrint

// MARK: - 單字卡
final class WordCardViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wwPrint("")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lockScreenOrientationToLandscape()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unlockScreenOrientation()
    }
}

// MARK: - 小工具
private extension WordCardViewController {
    
    /// 鎖定畫面為橫向
    func lockScreenOrientationToLandscape() {
        _ = Utility.shared.screenOrientation(lock: .landscape, rotate: .landscapeRight)
    }
    
    /// 不鎖定畫面方向
    func unlockScreenOrientation() {
        _ = Utility.shared.screenOrientation(lock: .all, rotate: .portrait)
        UIViewController.attemptRotationToDeviceOrientation()
        tabBarController?.tabBar.isHidden = false
        tabBarController?._tabBarHidden(false, animated: true)
    }
}
