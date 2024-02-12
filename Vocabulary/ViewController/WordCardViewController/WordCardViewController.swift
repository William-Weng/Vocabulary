//
//  WordCardViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2024/2/11.
//

import UIKit
import WWPrint
import WWOnBoardingViewController

// MARK: - 單字卡
final class WordCardViewController: UIViewController {
    
    private lazy var pageViewControllerArray: [UIViewController] = {
        return [
            pageViewController(with: "WordCardPageViewController"),
            pageViewController(with: "WordCardPageViewController"),
            pageViewController(with: "WordCardPageViewController"),
        ]
    }()
    
    private let currentPage = 0
    private let isInfinityLoop = true
    private var onBoardingViewController: WWOnBoardingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        initSetting(for: segue, sender: sender)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lockScreenOrientationToLandscape()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unlockScreenOrientation()
    }
}

// MARK: - WWOnBoardingViewControllerDelegate
extension WordCardViewController: WWOnBoardingViewControllerDelegate {
    
    func viewControllers(onBoardingViewController: WWOnBoardingViewController) -> [UIViewController] {
        return pageViewControllerArray
    }
    
    func willChangeViewController(_ onBoardingViewController: WWOnBoardingViewController, currentIndex: Int, nextIndex: Int, pageRotateDirection: WWOnBoardingViewController.PageRotateDirection, error: WWOnBoardingViewController.OnBoardingError?) {
    }
    
    func didChangeViewController(_ onBoardingViewController: WWOnBoardingViewController, finishAnimating finished: Bool, transitionCompleted: Bool, currentIndex: Int, nextIndex: Int, pageRotateDirection: WWOnBoardingViewController.PageRotateDirection, error: WWOnBoardingViewController.OnBoardingError?) {
    }
}

// MARK: - 小工具
private extension WordCardViewController {
    
    /// 鎖定畫面為橫向
    func lockScreenOrientationToLandscape() {
        _ = Utility.shared.screenOrientation(lock: .landscape, rotate: .landscapeRight)
        tabBarController?._tabBarHidden(true, animated: true)
    }
    
    /// 不鎖定畫面方向
    func unlockScreenOrientation() {
        _ = Utility.shared.screenOrientation(lock: .all, rotate: .portrait)
        UIViewController.attemptRotationToDeviceOrientation()
        tabBarController?.tabBar.isHidden = false
        tabBarController?._tabBarHidden(false, animated: true)
    }
}

// MARK: - 小工具
private extension WordCardViewController {
    
    /// 找到WWOnBoardingViewController
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func initSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        onBoardingViewController = segue.destination as? WWOnBoardingViewController
        onBoardingViewController?.setting(onBoardingDelegate: self, isInfinityLoop: isInfinityLoop, currentIndex: currentPage)
    }
    
    /// 尋找Storyboard上的ViewController for StoryboardId
    /// - Parameter indentifier: String
    /// - Returns: UIViewController
    func pageViewController(with indentifier: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: indentifier)
    }
}
