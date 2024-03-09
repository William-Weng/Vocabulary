//
//  WordCardViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2024/2/11.
//

import UIKit
import AVFAudio
import WWOnBoardingViewController
import WWFloatingViewController

// MARK: - 單字卡
final class WordCardViewController: UIViewController {
    
    @IBOutlet weak var orientationbButtonItem: UIBarButtonItem!
    
    var currentOrientation: UIDeviceOrientation = .unknown
    weak var mainViewDelegate: MainViewDelegate?

    private var currentLockOrientation: UIInterfaceOrientationMask = .all
    private var infinityLoopInfo: WWOnBoardingViewController.InfinityLoopInformation = (hasPrevious: false, hasNext: true)
    
    private lazy var pageViewControllerArray: [UIViewController] = {
        return [
            pageViewController(with: "WordCardPageViewController"),
            pageViewController(with: "WordCardPageViewController"),
            pageViewController(with: "WordCardPageViewController"),
        ]
    }()
        
    private var currentIndex = 0
    private var currentIndexOffset = 0
    private var onBoardingViewController: WWOnBoardingViewController?
    private var searchVocabularyViewController: SearchVocabularyViewController?

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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { initSetting(for: segue, sender: sender) }
    
    @IBAction func lockScreenOrientation(_ sender: UIBarButtonItem) { lockScreenOrientation() }
    
    @IBAction func searchVocabulary(_ sender: UIBarButtonItem) {
        searchVocabularyViewController = UIStoryboard._instantiateViewController() as SearchVocabularyViewController
        Utility.shared.presentSearchVocabularyViewController(target: self, currentView: searchVocabularyViewController?.view)
    }
}

// MARK: - WWOnBoardingViewControllerDelegate
extension WordCardViewController: WWOnBoardingViewControllerDelegate {
    
    func viewControllers(onBoardingViewController: WWOnBoardingViewController) -> [UIViewController] {
        if (MainTableViewCell.vocabularyListArray.isEmpty) { pageViewControllerArray = [UIViewController()] }
        return pageViewControllerArray
    }
    
    func infinityLoop(onBoardingViewController: WWOnBoardingViewController) -> WWOnBoardingViewController.InfinityLoopInformation {
        return infinityLoopInfo
    }
    
    func willChangeViewController(_ onBoardingViewController: WWOnBoardingViewController, currentIndex: Int, nextIndex: Int, pageRotateDirection: WWOnBoardingViewController.PageRotateDirection, error: WWOnBoardingViewController.OnBoardingError?) {
        willChangeViewControllerAction(onBoardingViewController: onBoardingViewController, currentIndex: currentIndex, nextIndex: nextIndex, pageRotateDirection: pageRotateDirection, error: error)
    }
    
    func didChangeViewController(_ onBoardingViewController: WWOnBoardingViewController, finishAnimating finished: Bool, transitionCompleted: Bool, currentIndex: Int, nextIndex: Int, pageRotateDirection: WWOnBoardingViewController.PageRotateDirection, error: WWOnBoardingViewController.OnBoardingError?) {
        didChangeViewControllerAction(onBoardingViewController: onBoardingViewController, finishAnimating: finished, transitionCompleted: transitionCompleted, currentIndex: currentIndex, nextIndex: nextIndex, pageRotateDirection: pageRotateDirection, error: error)
    }
}

// MARK: - WWFloatingViewDelegate
extension WordCardViewController: WWFloatingViewDelegate {
    
    func willAppear(_ viewController: WWFloatingViewController, completePercent: CGFloat) {}
    func appearing(_ viewController: WWFloatingViewController, fractionComplete: CGFloat) {}
    func didAppear(_ viewController: WWFloatingViewController, animatingPosition: UIViewAnimatingPosition) {}
    func willDisAppear(_ viewController: WWFloatingViewController) {}
    func didDisAppear(_ viewController: WWFloatingViewController, animatingPosition: UIViewAnimatingPosition) {}
}

// MARK: - 小工具
private extension WordCardViewController {
   
    /// 找到WWOnBoardingViewController + 初始化第一頁
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func initSetting(for segue: UIStoryboardSegue, sender: Any?) {
        pageViewControllerSetting(with: currentIndex, offset: currentIndexOffset)
        speakContent(with: currentIndex, isTypping: true)
        onBoardingViewController = segue.destination as? WWOnBoardingViewController
        onBoardingViewController?.setting(onBoardingDelegate: self, currentIndex: currentIndex)
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
        
        if let error = error { fixCurrentIndexOffset(with: error); myPrint(error); return }
        
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
        
        speakContent(with: currentIndex, isTypping: true)
        self.currentIndex = currentIndex
    }
    
    /// 設定單字頁的文字相關訊息
    /// - Parameters:
    ///   - index: Int
    ///   - offset: Int
    func pageViewControllerSetting(with index: Int, offset: Int) {
        
        guard let viewController = pageViewControllerArray[safe: index] as? WordCardPageViewController else { return }
        
        title = "單字卡 - \(currentIndexOffset + 1) / \(MainTableViewCell.vocabularyListArray.count)"
        
        viewController.loadViewIfNeeded()
        viewController.configure(with: IndexPath(row: currentIndexOffset, section: 0))
    }
    
    /// 閱讀單字內容 + 打字機文字顯示
    /// - Parameters:
    ///   - index: Int
    ///   - isTypping: Bool
    func speakContent(with index: Int, isTypping: Bool = false) {
        
        guard let viewController = pageViewControllerArray[safe: index] as? WordCardPageViewController else { return }
        
        viewController.loadViewIfNeeded()
        isTypping ? viewController.typewriter() : viewController.speakContent()
    }
    
    /// 修正offset超過單字範圍的問題
    /// - Parameter offset: Int
    func fixIndexOffset(_ offset: Int) {
        
        infinityLoopInfo = (true, true)
        
        if (offset <= 0) {
            infinityLoopInfo.hasPrevious = false
            currentIndexOffset = 0; return
        }
        
        if (offset >= MainTableViewCell.vocabularyListArray.count - 1) {
            infinityLoopInfo.hasNext = false
            currentIndexOffset = MainTableViewCell.vocabularyListArray.count - 1
        }
    }
    
    /// 修正CurrentIndexOffset的問題 (在第一頁 / 最後一頁)
    /// - Parameter error: WWOnBoardingViewController.OnBoardingError
    func fixCurrentIndexOffset(with error: WWOnBoardingViewController.OnBoardingError) {
        
        switch error {
        case .firstPage: currentIndexOffset = 0
        case .lastPage: currentIndexOffset = MainTableViewCell.vocabularyListArray.count - 2
        default: break
        }
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

// MARK: - 小工具
private extension WordCardViewController {
    
    /// 鎖定畫面方向
    func lockScreenOrientation() {
        if (currentLockOrientation == .landscape) { lockScreenOrientationToPortrait(); return }
        lockScreenOrientationToLandscape()
    }
    
    /// 鎖定畫面為橫向
    func lockScreenOrientationToLandscape() {
        
        let interfaceOrientation: UIInterfaceOrientation
        
        switch currentOrientation {
        case .portrait, .portraitUpsideDown, .unknown, .faceUp, .faceDown: interfaceOrientation = .landscapeRight
        case .landscapeLeft: interfaceOrientation = .landscapeRight
        case .landscapeRight: interfaceOrientation = .landscapeLeft
        @unknown default: interfaceOrientation = .landscapeRight
        }
        
        currentLockOrientation = .landscape
        _ = Utility.shared.screenOrientation(lock: currentLockOrientation, rotate: interfaceOrientation)
    }
    
    /// 鎖定畫面為直向
    func lockScreenOrientationToPortrait() {
        
        let interfaceOrientation: UIInterfaceOrientation = .portrait
        
        currentLockOrientation = .portrait
        _ = Utility.shared.screenOrientation(lock: currentLockOrientation, rotate: interfaceOrientation)
    }
    
    /// 不鎖定畫面方向 (轉回原來的方向)
    func unlockScreenOrientation() {
        currentLockOrientation = .all
        _ = Utility.shared.screenOrientation(lock: currentLockOrientation, rotate: currentOrientation._interfaceOrientation())
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    /// 設定畫面旋轉方向的圖示
    func orientationbButtonItemSetting() {
        let name = (UIDevice.current.orientation.isLandscape) ? "Horizontal" : "Vertical"
        orientationbButtonItemImage(name: name)
    }
    
    /// 設定圖示
    /// - Parameter name: String
    func orientationbButtonItemImage(name: String) {
        orientationbButtonItem.image = UIImage(named: name)
    }
}
