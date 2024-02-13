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
    
    weak var mainViewDelegate: MainViewDelegate?
    
    private lazy var pageViewControllerArray: [UIViewController] = {
        return [
            pageViewController(with: "WordCardPageViewController"),
            pageViewController(with: "WordCardPageViewController"),
            pageViewController(with: "WordCardPageViewController"),
        ]
    }()
    
    private let isInfinityLoop = true
    
    private var currentIndex = 0
    private var currentIndexOffset = 0
    private var onBoardingViewController: WWOnBoardingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        initSetting(for: segue, sender: sender)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearAction(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearAction(animated)
        unlockScreenOrientation()
    }
    
    @IBAction func lockScreenOrientation(_ sender: UIBarButtonItem) {
        lockScreenOrientationToLandscape()
    }
}

// MARK: - WWOnBoardingViewControllerDelegate
extension WordCardViewController: WWOnBoardingViewControllerDelegate {
    
    func viewControllers(onBoardingViewController: WWOnBoardingViewController) -> [UIViewController] {
        return pageViewControllerArray
    }
    
    func willChangeViewController(_ onBoardingViewController: WWOnBoardingViewController, currentIndex: Int, nextIndex: Int, pageRotateDirection: WWOnBoardingViewController.PageRotateDirection, error: WWOnBoardingViewController.OnBoardingError?) {
        willChangeViewControllerAction(onBoardingViewController: onBoardingViewController, currentIndex: currentIndex, nextIndex: nextIndex, pageRotateDirection: pageRotateDirection, error: error)
    }
    
    func didChangeViewController(_ onBoardingViewController: WWOnBoardingViewController, finishAnimating finished: Bool, transitionCompleted: Bool, currentIndex: Int, nextIndex: Int, pageRotateDirection: WWOnBoardingViewController.PageRotateDirection, error: WWOnBoardingViewController.OnBoardingError?) {
        didChangeViewControllerAction(onBoardingViewController: onBoardingViewController, finishAnimating: finished, transitionCompleted: transitionCompleted, currentIndex: currentIndex, nextIndex: nextIndex, pageRotateDirection: pageRotateDirection, error: error)
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
    }
    
    /// 找到WWOnBoardingViewController + 初始化第一頁
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func initSetting(for segue: UIStoryboardSegue, sender: Any?) {
        pageViewControllerSetting(with: currentIndex, offset: currentIndexOffset)
        onBoardingViewController = segue.destination as? WWOnBoardingViewController
        onBoardingViewController?.setting(onBoardingDelegate: self, isInfinityLoop: isInfinityLoop, currentIndex: currentIndex)
    }
    
    /// 尋找Storyboard上的ViewController for StoryboardId
    /// - Parameter indentifier: String
    /// - Returns: UIViewController
    func pageViewController(with indentifier: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: indentifier)
    }
    
    /// 處理將要換頁的動作
    /// - Parameters:
    ///   - onBoardingViewController: WWOnBoardingViewController
    ///   - currentIndex: Int
    ///   - nextIndex: Int
    ///   - pageRotateDirection: WWOnBoardingViewController.PageRotateDirection
    ///   - error: WWOnBoardingViewController.OnBoardingError?
    func willChangeViewControllerAction(onBoardingViewController: WWOnBoardingViewController, currentIndex: Int, nextIndex: Int, pageRotateDirection: WWOnBoardingViewController.PageRotateDirection, error: WWOnBoardingViewController.OnBoardingError?) {
                
        switch pageRotateDirection {
        case .right: currentIndexOffset += 1
        case .left: currentIndexOffset -= 1
        case .none: break
        }
        
        fixIndexOffset(currentIndexOffset)
        pageViewControllerSetting(with: nextIndex, offset: currentIndexOffset)
        self.currentIndex = currentIndex
    }
    
    /// 處理換頁完成的動作
    /// - Parameters:
    ///   - onBoardingViewController: WWOnBoardingViewController
    ///   - finished: Bool
    ///   - completed: Bool
    ///   - currentIndex: Int
    ///   - nextIndex: Int
    ///   - pageRotateDirection: WWOnBoardingViewController.PageRotateDirection
    ///   - error: WWOnBoardingViewController.OnBoardingError?
    func didChangeViewControllerAction(onBoardingViewController: WWOnBoardingViewController, finishAnimating finished: Bool, transitionCompleted completed: Bool, currentIndex: Int, nextIndex: Int, pageRotateDirection: WWOnBoardingViewController.PageRotateDirection, error: WWOnBoardingViewController.OnBoardingError?) {
        self.currentIndex = currentIndex
    }
    
    /// 設定單字頁的文字相關訊息
    /// - Parameters:
    ///   - index: Int
    ///   - offset: Int
    func pageViewControllerSetting(with index: Int, offset: Int) {
        guard let viewController = pageViewControllerArray[safe: index] as? WordCardPageViewController else { return }
        viewController.loadViewIfNeeded()
        viewController.configure(with: IndexPath(row: currentIndexOffset, section: 0))
    }
    
    /// 修正offset超過單字範圍的問題
    /// - Parameter offset: Int
    func fixIndexOffset(_ offset: Int) {
        if (offset < 0) { currentIndexOffset = 0 }
        if (offset > MainTableViewCell.vocabularyListArray.count - 1) { currentIndexOffset = MainTableViewCell.vocabularyListArray.count - 1 }
    }
    
    /// View將要顯示時的動作
    /// - Parameter animated: Bool
    func viewWillAppearAction(_ animated: Bool) {
        mainViewDelegate?.navigationBarHidden(false)
        mainViewDelegate?.tabBarHidden(true)
    }
    
    /// View將要消失時的動作
    /// - Parameter animated: Bool
    func viewWillDisappearAction(_ animated: Bool) {
        mainViewDelegate?.navigationBarHidden(false)
        mainViewDelegate?.tabBarHidden(false)
    }
}
