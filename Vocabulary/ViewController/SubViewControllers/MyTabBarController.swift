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
    
    private var canvasView: PKCanvasView?
    private var toolPicker: PKToolPicker?
    private var dismissButton: UIButton?
    
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
        dismissButtonSetting()
        tabBarStatus(isHidden: Self.isHidden, animated: false)
    }

    @objc func dismissCanvasView(_ sender: UIButton) { removeCanvasView() }
    
    deinit {
        NotificationCenter.default._remove(observer: self, name: .displayCanvasView)
        wwPrint("\(Self.self) deinit")
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
        }
    }
    
    /// 畫布設定
    func canvasViewSetting() {
        canvasView = PKCanvasView._build(onView: view, delegate: self)
        toolPicker = PKToolPicker._build(with: canvasView!)
        canvasView?.becomeFirstResponder()
    }
    
    /// 取消畫布的按鈕設定
    func dismissButtonSetting() {
        
        guard let canvasView = canvasView else { return }
        
        dismissButton?.removeFromSuperview()
        dismissButton = dismissButtonMaker()
        
        if let dismissButton = dismissButton {
            dismissButton.addTarget(self, action: #selector(Self.dismissCanvasView(_:)), for: .touchUpInside)
            canvasView.addSubview(dismissButton)
        }
    }
    
    /// 產生關閉畫布按鈕
    /// - Parameters:
    ///   - diameter: 直徑
    ///   - gap: 與右上角的間隔
    /// - Returns: UIButton
    func dismissButtonMaker(_ diameter: CGFloat = 36, gap: CGFloat = 32, imageName: String = "Close") -> UIButton {
        
        let button = UIButton()
        
        button.frame.size = CGSize(width: diameter, height: diameter)
        button.center = CGPoint(x: view.frame.width - gap, y: gap)
        button.setBackgroundImage(UIImage(named: imageName), for: .normal)
        button.backgroundColor = .clear
        
        if let window = view.window, window._hasSafeArea() {
            button.center = CGPoint(x: view.frame.width - gap, y: gap + 24.0)
        }
        
        return button
    }
    
    /// 移除畫布
    func removeCanvasView() {
        canvasView?.removeFromSuperview()
        canvasView = nil
        toolPicker = nil
        dismissButton = nil
    }
}
