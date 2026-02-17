//
//  TouchViewController.swift
//  Vocabulary
//
//  Created by William Weng on 2025/11/1.
//

import UIKit
import WWFloatingViewController

// MARK: - WWAssistiveTouch的內容項目頁
final class TouchViewController: UIViewController {
    
    /// TouchView的Tag編號
    private enum TouchTagType: Int {
        case pencel = 101
        case recorder = 102
        case share = 103
        case download = 104
        case chat = 105
        case speedRate = 106
        case spackingVolume = 107
        case question = 108
        case perplexity = 109
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        AssistiveTouchHelper.shared.assistiveTouch.dismiss()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearAction()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearAction()
    }
    
    /// 點擊後的動作
    /// - Parameter sender: UIButton
    @IBAction func touchAction(_ sender: UIButton) {
                
        defer { AssistiveTouchHelper.shared.assistiveTouch.dismiss() }
        
        guard let touchType = TouchTagType(rawValue: sender.tag) else { return }
        
        switch touchType {
        case .pencel: Utility.shared.pencelToolPicker()
        case .recorder: Utility.shared.recording()
        case .share: Utility.shared.shareDatabase()
        case .download: Utility.shared.downloadDatabase(delegate: self)
        case .chat: Utility.shared.chat(agentType: .ollama)
        case .speedRate: Utility.shared.adjustmentSoundType(.rate)
        case .spackingVolume: Utility.shared.adjustmentSoundType(.spacking)
        case .question: Utility.shared.displaySearchView()
        case .perplexity: Utility.shared.chat(agentType: .perplexity)
        }
    }
        
    deinit {
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - UIDocumentPickerDelegate
extension TouchViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Utility.shared.downloadDocumentAction(controller, didPickDocumentsAt: urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        AssistiveTouchHelper.shared.hiddenAction(false)
    }
}

// MARK: - 小工具
private extension TouchViewController {
    
    /// 淡入動畫
    /// - Parameter duration: TimeInterval
    func viewWillAppearAction(duration: TimeInterval = 0.25) {
        
        view.alpha = 0.5
        
        UIViewPropertyAnimator(duration: duration, curve: .linear) { [unowned self] in
            view.alpha = 1.0
        }.startAnimation()
    }
    
    /// 淡出動畫
    /// - Parameter duration: TimeInterval
    func viewWillDisappearAction(duration: TimeInterval = 0.25) {
        
        view.alpha = 1.0
        
        UIViewPropertyAnimator(duration: duration, curve: .linear) { [unowned self] in
            view.alpha = 0.0
        }.startAnimation()
    }
}
