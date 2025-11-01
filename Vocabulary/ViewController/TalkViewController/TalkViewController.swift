//
//  TalkViewController.swift
//  Vocabulary
//
//  Created by William Weng on 2025/11/1.
//

import UIKit

// MARK: - TalkViewController
final class TalkViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    
    private var isAnimationStop = false
    private var disappearImage: UIImage?
    private var gifImageView: UIImageView?
    
    enum ViewSegueType: String {
        case aiTalking = "AITalkingSegue"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatedBackground(with: .chatting)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }
    
    @IBAction func aiTalking(_ sender: UIButton) {
        performSegue(withIdentifier: ViewSegueType.aiTalking.rawValue, sender: sender)
    }
    
    deinit {
        removeGifBlock()
        myPrint("deinit => \(Self.self)")
    }
}

// MARK: - 小工具
private extension TalkViewController {
    
    /// 初始化
    func initSetting() {
        viewDidTransitionAction()
    }
    
    /// 畫面旋轉的動作 (更新appendButton的位置 / TableView的Inset位置)
    func viewDidTransitionAction() {
        
        NotificationCenter.default._register(name: .viewDidTransition) { _ in
            Utility.shared.updateScrolledHeightSetting()
        }
    }
    
    /// 暫停背景動畫
    func pauseBackgroundAnimation() {
        disappearImage = myImageView.image
        isAnimationStop = true
    }
}

// MARK: - gif工具
private extension TalkViewController {
    
    /// 移除GIF動畫Block
    func removeGifBlock() {
        
        isAnimationStop = true
        gifImageView?.removeFromSuperview()
        gifImageView = nil
    }
    
    /// 動畫背景設定
    /// - Parameter type: Constant.AnimationGifType
    func animatedBackground(with type: Constant.AnimationGifType) {
        
        guard let gifUrl = type.fileURL(with: .background) else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): myPrint(error)
            case .success(let info):
                info.pointer.pointee = this.isAnimationStop
                if (this.isAnimationStop) { this.myImageView.image = this.disappearImage }
            }
        }
    }
}
