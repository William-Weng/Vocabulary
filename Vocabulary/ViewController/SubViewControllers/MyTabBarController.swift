//
//  MyTabBarController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/16.
//

import UIKit
import PencilKit

// MARK: - 自定義的UITabBarController
final class MyTabBarController: UITabBarController {
    
    static var isHidden = true
    
    private let safeAreaGap = 24.0
    private let diameter = 36.0
    private let buttonPoint = CGPoint(x: 32.0, y: 44.0)
    
    private var canvasView: PKCanvasView?
    private var toolPicker: PKToolPicker?
    private var dismissButton: UIButton?
    private var cleanDrawingButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        registerCanvasViewAction()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewWillTransitionAction(to: size, with: coordinator)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dismissButton?.center = dismissButtonCenter(origin: buttonPoint)
        cleanDrawingButton?.center = cleanDrawingButtonCenter(origin: buttonPoint)
        tabBarStatus(isHidden: Self.isHidden, animated: false)
    }

    @objc func dismissCanvasView(_ sender: UIButton) { removeCanvasView() }
    @objc func cleanCanvasDrawing(_ sender: UIButton) { cleanDrawing() }
    
    deinit {
        NotificationCenter.default._remove(observer: self, name: .displayCanvasView)
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - PKCanvasViewDelegate
extension MyTabBarController: PKCanvasViewDelegate {
    
    func canvasViewDidFinishRendering(_ canvasView: PKCanvasView) {
        tabBarStatus(isHidden: Self.isHidden, animated: false)
    }
}

// MARK: - 小工具
private extension MyTabBarController {
    
    /// 初始化設定
    func initSetting() {
        view.tintColor = .systemBlue
    }
    
    /// 畫面旋轉後，要修正的事情 => 隱藏
    /// - Parameters:
    ///   - size: CGSize
    ///   - coordinator: UIViewControllerTransitionCoordinator
    func viewWillTransitionAction(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate { [unowned self] _ in
            tabBarStatus(isHidden: Self.isHidden)
        }
    }
    
    /// TabBar的顯示隱藏狀態
    /// - Parameters:
    ///   - isHidden: Bool
    ///   - animated: Bool
    func tabBarStatus(isHidden: Bool, animated: Bool = true) {
        self._tabBarHidden(isHidden, animated: animated)
        NotificationCenter.default._post(name: .viewDidTransition, object: isHidden)
    }
    
    /// 註冊CanvasView的顯示設定
    func registerCanvasViewAction() {
        
        NotificationCenter.default._register(name: .displayCanvasView) { [unowned self] _ in
            canvasViewSetting()
            canvasViewButtonsSetting()
        }
    }
    
    /// 畫布設定
    func canvasViewSetting() {
        
        canvasView = PKCanvasView._build(onView: view, delegate: self)
        assistiveTouchHidden(true)
                
        if let canvasView = canvasView {
            toolPicker = PKToolPicker._build(with: canvasView)
            canvasView.becomeFirstResponder()
        }
    }
    
    /// 畫布的按鈕設定
    func canvasViewButtonsSetting() {
        
        guard let canvasView = canvasView else { return }
        
        dismissButton?.removeFromSuperview()
        cleanDrawingButton?.removeFromSuperview()
        
        dismissButton = actionButtonMaker(diameter, imageName: "Close")
        cleanDrawingButton = actionButtonMaker(diameter, imageName: "Clean")
        
        guard let dismissButton = dismissButton,
              let cleanDrawingButton = cleanDrawingButton
        else {
            return
        }
        
        dismissButton.addTarget(self, action: #selector(Self.dismissCanvasView(_:)), for: .touchUpInside)
        cleanDrawingButton.addTarget(self, action: #selector(Self.cleanCanvasDrawing(_:)), for: .touchUpInside)
        
        canvasView.addSubview(dismissButton)
        canvasView.addSubview(cleanDrawingButton)
    }
    
    /// 產生關閉畫布按鈕
    /// - Parameters:
    ///   - diameter: 直徑
    ///   - imageName: 圖片名稱
    /// - Returns: UIButton
    func actionButtonMaker(_ diameter: CGFloat, imageName: String) -> UIButton {
        
        let button = UIButton()
        
        button.frame.size = CGSize(width: diameter, height: diameter)
        button.setBackgroundImage(UIImage(named: imageName), for: .normal)
        button.backgroundColor = .clear

        return button
    }
    
    /// 設定dismissButton的位置
    /// - Parameter origin: CGPoint
    /// - Returns: CGPoint
    func dismissButtonCenter(origin: CGPoint) -> CGPoint {
        
        var center = CGPoint(x: view.frame.width - origin.x, y: origin.y)
        if let window = view.window, window._hasSafeArea() { center = CGPoint(x: view.frame.width - origin.x, y: origin.y + safeAreaGap) }
        
        return center
    }
    
    /// 設定cleanDrawingButton的位置
    /// - Parameter origin: CGPoint
    /// - Returns: CGPoint
    func cleanDrawingButtonCenter(origin: CGPoint) -> CGPoint {
        
        var center = origin
        if let window = view.window, window._hasSafeArea() { center = CGPoint(x: origin.x, y: origin.y + safeAreaGap) }
        
        return center
    }
    
    /// 移除畫布
    func removeCanvasView() {
        
        assistiveTouchHidden(false)
        canvasView?.removeFromSuperview()
        
        canvasView = nil
        toolPicker = nil
        dismissButton = nil
        cleanDrawingButton = nil
    }
    
    /// AssistiveTouch是否顯示
    /// - Parameter isHidden: Bool
    func assistiveTouchHidden(_ isHidden: Bool) {
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        delegate.assistiveTouch.alpha = isHidden ? 1.0 : 0.0

        let animator = UIViewPropertyAnimator(duration: Constant.replay, curve: .easeInOut) {
            delegate.assistiveTouch.alpha = !isHidden ? 1.0 : 0.0
        }
        
        if !isHidden {
            delegate.assistiveTouch.isHidden = false
        } else {
            animator.addCompletion { _ in delegate.assistiveTouch.isHidden = true }
        }
        
        animator.startAnimation()
    }
    
    /// 清空畫布
    func cleanDrawing() { canvasView?.drawing = PKDrawing() }
}
