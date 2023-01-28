//
//  VolumeViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/28.
//

import UIKit
import WWPrint
import WWSlider

// MARK: - 設定背景音樂音量大小
final class VolumeViewController: UIViewController {
    
    @IBOutlet weak var volumeProgressSlider: WWSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initProgressSlider()
        initSetting()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.dismiss(animated: true)
    }
}

// MARK: - SliderDeleagte
extension VolumeViewController: SliderDeleagte {
    
    func valueChange(identifier: String, currentValue: CGFloat, maximumValue: CGFloat, isVertical: Bool) -> SliderInfomation {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return SliderInfomation(text: "0 %", icon: nil) }
        
        let percent = Int(currentValue / maximumValue * 100)
        _ = appDelegate.musicVolumeSetting(Float(percent) * 0.01)
                
        return SliderInfomation(text: "\(percent) %", icon: nil)
    }
}

// MARK: - 小工具
extension VolumeViewController {
    
    /// 初始化WWSlider
    func initProgressSlider() {
        volumeProgressSlider.layoutIfNeeded()
        volumeProgressSlider.myDeleagte = self
    }
    
    /// 初始化音量大小
    func initSetting() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let volume = appDelegate.musicVolume()
        else {
            return
        }
        
        let maximumValue = volumeProgressSlider.frame.height
        let currentValue = CGFloat(volume) * maximumValue
        
        volumeProgressSlider.currentValue = currentValue
        volumeProgressSlider.configure(id: "volumeProgressView", initValue: "\(Int(volume * 100)) %", font: .systemFont(ofSize: 24), icon: nil, type: .segmented(100))
    }
}
