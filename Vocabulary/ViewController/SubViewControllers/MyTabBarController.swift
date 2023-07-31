//
//  MyTabBarController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/16.
//

import UIKit
import PencilKit
import WWPrint

// MARK: - 自定義的UITabBarController
final class MyTabBarController: UITabBarController {
    
    static var isHidden = true
    
    private let safeAreaGap = 24.0
    
    private var canvasView: PKCanvasView?
    private var toolPicker: PKToolPicker?
    private var dismissButton: UIButton?
    private var cleanDrawingButton: UIButton?
    private var diameter = 36.0
    private var gap = 32.0

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCanvasViewAction()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewWillTransitionAction(to: size, with: coordinator)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dismissButton?.center = dismissButtonCenter(gap: gap)
        cleanDrawingButton?.center = cleanDrawingButtonCenter(gap: gap)
        tabBarStatus(isHidden: Self.isHidden, animated: false)
    }

    @objc func dismissCanvasView(_ sender: UIButton) { removeCanvasView() }
    @objc func cleanCanvasDrawing(_ sender: UIButton) { cleanDrawing() }
    
    deinit {
        NotificationCenter.default._remove(observer: self, name: .displayCanvasView)
        wwPrint("\(Self.self) deinit", isShow: Constant.isPrint)
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
    
    /// 畫面旋轉後，要修正的事情 => 隱藏
    /// - Parameters:
    ///   - size: CGSize
    ///   - coordinator: UIViewControllerTransitionCoordinator
    func viewWillTransitionAction(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate { [weak self] _ in
            
            guard let this = self else { return }
            this.tabBarStatus(isHidden: Self.isHidden)
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
        
        NotificationCenter.default._register(name: .displayCanvasView) { [weak self] _ in
            
            guard let this = self else { return }
            
            this.canvasViewSetting()
            this.canvasViewButtonsSetting()
        }
    }
    
    /// 畫布設定
    func canvasViewSetting() {
        
        canvasView = PKCanvasView._build(onView: view, delegate: self)
        
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
        
        dismissButton = actionButtonMaker(diameter, gap: gap, imageName: "Close")
        cleanDrawingButton = actionButtonMaker(diameter, gap: gap, imageName: "Clean")
        
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
    ///   - gap: 與右上角的間隔
    ///   - imageName: 圖片名稱
    /// - Returns: UIButton
    func actionButtonMaker(_ diameter: CGFloat, gap: CGFloat, imageName: String) -> UIButton {
        
        let button = UIButton()
        
        button.frame.size = CGSize(width: diameter, height: diameter)
        button.setBackgroundImage(UIImage(named: imageName), for: .normal)
        button.backgroundColor = .clear

        return button
    }
    
    /// 設定dismissButton的位置
    /// - Parameter gap: CGFloat
    /// - Returns: CGPoint
    func dismissButtonCenter(gap: CGFloat) -> CGPoint {
        
        var center = CGPoint(x: view.frame.width - gap, y: gap)
        if let window = view.window, window._hasSafeArea() { center = CGPoint(x: view.frame.width - gap, y: gap + safeAreaGap) }
        
        return center
    }
    
    /// 設定cleanDrawingButton的位置
    /// - Parameter gap: CGFloat
    /// - Returns: CGPoint
    func cleanDrawingButtonCenter(gap: CGFloat) -> CGPoint {
        
        var center = CGPoint(x: gap, y: gap)
        if let window = view.window, window._hasSafeArea() { center = CGPoint(x: gap, y: gap + safeAreaGap) }
        
        return center
    }
    
    /// 移除畫布
    func removeCanvasView() {
        
        canvasView?.removeFromSuperview()
        
        canvasView = nil
        toolPicker = nil
        dismissButton = nil
        cleanDrawingButton = nil
    }
    
    /// 清空畫布
    func cleanDrawing() { canvasView?.drawing = PKDrawing() }
}
