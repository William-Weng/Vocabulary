//
//  AssistiveTouchHelper.swift
//  Vocabulary
//
//  Created by William.Weng on 2026/2/12.
//

import UIKit
import WWAssistiveTouch

// MARK: - AssistiveTouchHelper (單例)
final class AssistiveTouchHelper: NSObject {
    
    static let shared = AssistiveTouchHelper()
    
    var assistiveTouch: WWAssistiveTouch!
        
    private override init() {}
}

// MARK: - WWAssistiveTouch.Delegate
extension AssistiveTouchHelper: WWAssistiveTouch.Delegate {
    
    func assistiveTouch(_ assistiveTouch: WWAssistiveTouch, isTouched: Bool) {
        if (isTouched) { assistiveTouch.display() }
    }
    
    func assistiveTouch(_ assistiveTouch: WWAssistiveTouch, status: WWAssistiveTouch.Status) {}
}

// MARK: - 公開函數
extension AssistiveTouchHelper {
    
    /// 初始化浮動按鈕
    /// - Parameters:
    ///   - appDelegate: SceneDelegate?
    ///   - viewController: UIViewController?
    func initSetting(appDelegate: SceneDelegate?, viewController: UIViewController?) {
        
        guard let appDelegate = appDelegate,
              let window = appDelegate.window,
              let viewController = viewController
        else {
            return
        }
        
        let size = CGSize(width: 56, height: 56)
        let origin = CGPoint(x: window.bounds.width, y: window.bounds.height - 216)
                
        assistiveTouch = WWAssistiveTouch(touchViewController: viewController, frame: .init(origin: origin, size: size), icon: .touchMain, isAutoAdjust: true, delegate: self)
    }
    
    /// AssistiveTouch是否顯示 (動畫)
    /// - Parameter isHidden: Bool
    func hiddenAction(_ isHidden: Bool) {
        
        let this = self
        assistiveTouch.alpha = isHidden ? 1.0 : 0.0

        let animator = UIViewPropertyAnimator(duration: Constant.replay, curve: .easeInOut) {
            this.assistiveTouch.alpha = !isHidden ? 1.0 : 0.0
        }
        
        if !isHidden {
            assistiveTouch.isHidden = false
        } else {
            animator.addCompletion { _ in this.assistiveTouch.isHidden = true }
        }
        
        animator.startAnimation()
    }
}
