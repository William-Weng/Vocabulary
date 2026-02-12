//
//  TalkingViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/17.
//

import UIKit

// MARK: - 錄音功能
final class TalkingViewController: UIViewController {

    @IBOutlet weak var myImageView: UIImageView!
    
    private var isAnimationStop = false
    private var disappearImage: UIImage?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        AssistiveTouchHelper.shared.hiddenAction(false)
        disappearImage = myImageView.image
        isAnimationStop = true
        _ = RecorderHelper.shared.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AssistiveTouchHelper.shared.hiddenAction(true)
        animatedBackground(with: .talking)
        _ = RecorderHelper.shared.start()
    }
    
    deinit {
        isAnimationStop = true
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - 小工具
private extension TalkingViewController {
        
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
                
                if (this.isAnimationStop) {
                    this.myImageView.image = this.disappearImage
                    this.dismiss(animated: true)
                }
            }
        }
    }
}
