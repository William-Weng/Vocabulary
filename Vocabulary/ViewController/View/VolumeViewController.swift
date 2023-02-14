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
    
    enum AdjustmentSoundType {
        case volume     // 音量大小
        case rate       // 語速快慢
    }
    
    var soundType: AdjustmentSoundType = .volume
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var volumeProgressSlider: WWSlider!
    
    private var isInitSetting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initProgressSlider()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismissAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initSetting()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateWidth(isLandscape: isLandscape(with: view.frame.size))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewWillTransitionAction(to: size, with: coordinator)
    }
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - SliderDeleagte
extension VolumeViewController: SliderDeleagte {
    
    func valueChange(identifier: String, currentValue: CGFloat, maximumValue: CGFloat, isVertical: Bool) -> SliderInfomation {
        let percent = valueChangePercent(identifier: identifier, currentValue: currentValue, maximumValue: maximumValue, isVertical: isVertical) ?? 0
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
        
        guard !isInitSetting,
              let percent = sliderVolume()
        else {
            return
        }
        
        let currentValue = currentValueMaker(with: percent)
        
        isInitSetting = true
        
        volumeProgressSlider.currentValue = currentValue
        volumeProgressSlider.configure(id: "volumeProgressView", initValue: "\(Int(percent * 100)) %", font: .systemFont(ofSize: 24), icon: nil, type: .segmented(100))
    }
    
    /// 取得實際的高度值
    /// - Parameters:
    ///   - percent: 百分比
    /// - Returns: CGFloat
    func currentValueMaker(with percent: Float) -> CGFloat {
        
        let maximumValue = volumeProgressSlider.frame.height
        let currentValue = CGFloat(percent) * maximumValue
                
        return currentValue
    }
    
    /// Slider數值變動時的百分比值設定
    /// - Parameters:
    ///   - identifier: String
    ///   - currentValue: WWSlider內部的高度
    ///   - maximumValue: WWSlider高度最大值
    ///   - isVertical: Bool
    /// - Returns: Int?
    func valueChangePercent(identifier: String, currentValue: CGFloat, maximumValue: CGFloat, isVertical: Bool) -> Int? {
        
        let percent = Int(currentValue / maximumValue * 100)
        
        switch soundType {
        case .volume:
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
            _ = appDelegate.musicVolumeSetting(Float(percent) * 0.01)
        case .rate:
            Constant.speakingSpeed = Float(percent) * 0.01 + 0.00001
        }

        return percent
    }
    
    /// 取得一開始的數值大小
    /// - Returns: Float?
    func sliderVolume() -> Float? {
                
        switch soundType {
        case .volume:
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let musicVolume = appDelegate.musicVolume()
            else {
                return nil
            }
            
            return musicVolume
            
        case .rate: return Constant.speakingSpeed
        }
    }
    
    /// [修正畫面旋轉後，畫面數據比例不對的問題](https://stackoverflow.com/questions/26943808/ios-how-to-run-a-function-after-device-has-rotated-swift)
    /// - Parameters:
    ///   - size: CGSize
    ///   - coordinator: UIViewControllerTransitionCoordinator
    func viewWillTransitionAction(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate { [weak self] _ in
            
            guard let this = self else { return }
            
            let percent = this.sliderVolume() ?? 0
            let constant = this.currentValueMaker(with: percent)
            
            this.updateWidth(isLandscape: this.isLandscape(with: size))
            this.volumeProgressSlider.currentValue = constant
            _ = this.volumeProgressSlider.valueSetting(constant: constant, info: (text: "\(Int(percent * 100)) %", icon: nil))
        }
    }
    
    /// 該Slider的寬度
    /// - Returns: Double
    func currentWidth(isLandscape: Bool) -> Double {
        let width = (!isLandscape) ? 128.0 : 72.0
        return width
    }
    
    /// 更新寬度
    func updateWidth(isLandscape: Bool) {
        
        let width = currentWidth(isLandscape: isLandscape)
        
        widthConstraint.constant = width
        volumeProgressSlider.layer.cornerRadius = width * 0.5
    }
    
    /// 判斷是不是橫著放？
    /// - Parameter size: CGSize
    /// - Returns: Bool
    func isLandscape(with size: CGSize) -> Bool {
        return size.width > size.height
    }

    /// 回到上一頁
    func dismissAction() {
        
        self.dismiss(animated: true) {
            
            guard let keyWindow = UIWindow._keyWindow(),
                  let rootViewController = keyWindow.rootViewController,
                  let tabBarController = rootViewController as? UITabBarController
            else {
                return
            }
            
            tabBarController._tabBarHidden(false, animated: true)
        }
    }
}
