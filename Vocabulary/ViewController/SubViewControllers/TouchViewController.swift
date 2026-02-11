//
//  TouchViewController.swift
//  Vocabulary
//
//  Created by William Weng on 2025/11/1.
//

import UIKit

final class TouchViewController: UIViewController {
    
    private enum TouchTagType: Int {
        case pencel = 101
        case recorder = 102
        case share = 103
    }
    
    private let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        appDelegate?.assistiveTouch.dismiss()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.alpha = 0.5
        
        UIViewPropertyAnimator(duration: 0.25, curve: .linear) { [unowned self] in
            view.alpha = 1.0
        }.startAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.alpha = 0.0
    }
    
    @IBAction func touchAction(_ sender: UIButton) {
        
        guard let appDelegate = appDelegate else { return }
        
        defer { appDelegate.assistiveTouch.dismiss() }
        
        guard let touchType = TouchTagType(rawValue: sender.tag) else { return }
        
        switch touchType {
        case .pencel: appDelegate.pencelToolPicker()
        case .recorder: appDelegate.recording()
        case .share: appDelegate.shareDatabase()
        }
    }
}
