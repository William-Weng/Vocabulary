//
//  WordCardViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2024/2/11.
//

import UIKit
import WWOnBoardingViewController

// MARK: - 單字卡
final class WordCardViewController: UIViewController {
    
    @IBOutlet weak var orientationbButtonItem: UIBarButtonItem!
    
    var currentOrientation: UIDeviceOrientation = .unknown
    
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
        orientationbButtonItemSetting()
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        orientationbButtonItemSetting()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        initSetting(for: segue, sender: sender)
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
        
        var interfaceOrientation: UIInterfaceOrientation = .landscapeRight

        switch currentOrientation {
        case .portrait, .portraitUpsideDown, .unknown, .faceUp, .faceDown: interfaceOrientation = .landscapeRight
        case .landscapeLeft: interfaceOrientation = .landscapeRight
        case .landscapeRight: interfaceOrientation = .landscapeLeft
        @unknown default: break
        }
        
        _ = Utility.shared.screenOrientation(lock: .landscape, rotate: interfaceOrientation)
    }
    
    /// 不鎖定畫面方向 (轉回原來的方向)
    func unlockScreenOrientation() {
        
        var interfaceOrientation: UIInterfaceOrientation = .unknown
        
        switch currentOrientation {
        case .portrait: interfaceOrientation = .portrait
        case .portraitUpsideDown: interfaceOrientation = .portraitUpsideDown
        case .landscapeLeft: interfaceOrientation = .landscapeRight
        case .landscapeRight: interfaceOrientation = .landscapeLeft
        case .unknown, .faceUp, .faceDown: interfaceOrientation = .unknown
        @unknown default: break
        }
        
        _ = Utility.shared.screenOrientation(lock: .all, rotate: interfaceOrientation)
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    /// 設定畫面旋轉方向的圖示
    func orientationbButtonItemSetting() {
        let imageName = (UIDevice.current.orientation.isLandscape) ? "Horizontal" : "Vertical"
        orientationbButtonItem.image = UIImage(named: imageName)
    }
    
    /// 找到WWOnBoardingViewController + 初始化第一頁
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func initSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        pageViewControllerSetting(with: currentIndex, offset: currentIndexOffset)
        speakContent(with: currentIndex)
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
        
        speakContent(with: currentIndex)
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
    
    /// 閱讀單字內容
    /// - Parameters:
    ///   - index: Int
    ///   - offset: Int
    func speakContent(with index: Int) {
        
        guard let viewController = pageViewControllerArray[safe: index] as? WordCardPageViewController else { return }
        
        viewController.loadViewIfNeeded()
        viewController.speakContent()
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