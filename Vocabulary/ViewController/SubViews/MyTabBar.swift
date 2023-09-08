//
//  MyTabBar.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/3/2.
//

import UIKit

@IBDesignable
final class MyTabBar: UITabBar {

    @IBInspectable var backdropImage: UIImage = UIImage()
    @IBInspectable var buttonImage: UIImage = UIImage()
    
    private var centerButton = UIButton()
    private var backgroundImageView = UIImageView()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        centerButtonSetting()
        backgroundImageViewSetting()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return centerButtonHitTest(point, with: event)
    }
    
    @objc func centerButtonClicked(_ sender: UIButton) { NotificationCenter.default._post(name: .displayCanvasView, object: nil) }
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
private extension MyTabBar {
    
    /// [設定中間的按鈕](https://www.jianshu.com/p/e45a1c239451)
    func centerButtonSetting() {
        
        disableCenterTab()
        
        centerButton.setBackgroundImage(buttonImage, for: .normal)
        centerButton.frame.size = centerButton.currentBackgroundImage?.size ?? .zero
        centerButton.addTarget(self, action: #selector(Self.centerButtonClicked(_:)), for: .touchUpInside)
        centerButton.center = CGPoint.init(x: frame.size.width * 0.5, y: 0)
        
        if let window = self.window, window._hasSafeArea() {
            centerButton.center = CGPoint.init(x: frame.size.width * 0.5, y: 16)
        }
        
        addSubview(centerButton)
        bringSubviewToFront(centerButton)
    }
    
    /// 關閉Title是空的Tab => 防止被按到
    func disableCenterTab() {
        
        if let items = items {
            items.forEach({ item in
                guard let title = item.title else { return }
                if (title.isEmpty) { item.isEnabled = false }
            })
        }
    }
    
    /// 設定背景圖片
    func backgroundImageViewSetting() {
        
        backgroundImageView.frame = self.bounds
        backgroundImageView.backgroundColor = .clear
        backgroundImageView.image = backdropImage
        backgroundImageView.contentMode = .scaleAspectFill

        addSubview(backgroundImageView)
        sendSubviewToBack(backgroundImageView)
    }
    
    /// 讓CenterView的外緣點到有反應
    /// - Parameters:
    ///   - point: CGPoint
    ///   - event: UIEven?
    /// - Returns: UIView?
    func centerButtonHitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let _centerButton = convert(point, to: centerButton)
        
        guard !isHidden,
              centerButton.point(inside: _centerButton, with: event)
        else {
            return super.hitTest(point, with: event)
        }
        
        return centerButton
    }
}
