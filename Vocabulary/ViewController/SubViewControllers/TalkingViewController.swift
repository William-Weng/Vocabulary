//
//  TalkingViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/17.
//

import UIKit
import WWPrint

// MARK: - 錄音功能
final class TalkingViewController: UIViewController {

    @IBOutlet weak var myImageView: UIImageView!
    
    private var isAnimationStop = false
    private var disappearImage: UIImage?
    private var appDelegate: AppDelegate? { get { return UIApplication.shared.delegate as? AppDelegate } }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        disappearImage = myImageView.image
        isAnimationStop = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animatedBackground(with: .talking)
        recordWave()
    }
    
    deinit {
        isAnimationStop = true
        wwPrint("\(Self.self) deinit", isShow: Constant.isPrint)
    }
}

// MARK: - 小工具
private extension TalkingViewController {
        
    /// 動畫背景設定
    /// - Parameter type: Utility.HudGifType
    func animatedBackground(with type: Constant.HudGifType) {
        
        guard let gifUrl = type.fileURL() else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): wwPrint(error, isShow: Constant.isPrint)
            case .success(let info):
                
                info.pointer.pointee = this.isAnimationStop
                
                if (this.isAnimationStop) {
                    this.stopRecording()
                    this.myImageView.image = this.disappearImage
                    this.dismiss(animated: true)
                }
            }
        }
    }
    
    /// 開始錄音
    func recordWave() {
        guard let appDelegate = appDelegate else { return }
        _ = appDelegate.recordWave()
    }
    
    /// 停止錄音
    func stopRecording() {
        guard let appDelegate = appDelegate else { return }
        _ = appDelegate.stopRecordingWave()
    }
}
