//
//  PaletteTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/9/8.
//

import UIKit

// MARK: - 調色盤Cell
final class PaletteTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var myView: UIView!
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myImageBaseView: UIView!
    
    static weak var paletteViewDelegate: PaletteViewDelegate?
    static var colorSettings: [[ColorSettings]] = []
    
    var indexPath: IndexPath = []
    
    private var gifImageView: UIImageView?
    private var isAnimationStop = false
    private var animationBlock: ((URL) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isAnimationStop = false
        animationBlock = nil
        myView.gestureRecognizers?.forEach({ myView.removeGestureRecognizer($0) })
        myLabel.gestureRecognizers?.forEach({ myLabel.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    /// 選擇文字顏色
    /// - Parameter sender: UITapGestureRecognizer
    @objc func selectTextColor(_ sender: UITapGestureRecognizer) {
        
        let info: Constant.PaletteInformation = (myLabel.textColor, myView.backgroundColor)
        Self.paletteViewDelegate?.palette(with: indexPath, colorType: .text, info: info)
    }
    
    /// 選擇背景顏色
    /// - Parameter sender: UITapGestureRecognizer
    @objc func selectBackgroundColor(_ sender: UITapGestureRecognizer) {
        
        let info: Constant.PaletteInformation = (myLabel.textColor, myView.backgroundColor)
        Self.paletteViewDelegate?.palette(with: indexPath, colorType: .background, info: info)
    }
    
    /// 選擇GIF圖片
    /// - Parameter sender: UITapGestureRecognizer
    @objc func animationGallery(_ sender: UITapGestureRecognizer) {
        Self.paletteViewDelegate?.gallery(with: indexPath)
    }
    
    deinit {
        myPrint("\(Self.self) init")
    }
}

// MARK: - 小工具
extension PaletteTableViewCell {
    
    /// 取得該分類的總設定值
    /// - Parameter section: Int
    /// - Returns: [ColorSettings]?
    static func colorSettings(with section: Int) -> [ColorSettings]? {
        
        let settings = Self.colorSettings[safe: section]
        return settings
    }
    
    /// 取得該設定值
    /// - Parameter indexPath: IndexPath
    /// - Returns: ColorSettings?
    static func colorSetting(with indexPath: IndexPath) -> ColorSettings? {
        
        let setting = Self.colorSettings[safe: indexPath.section]?[safe: indexPath.row]
        return setting
    }
}

// MARK: - 小工具
private extension PaletteTableViewCell {
    
    /// 初始化設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let colorSetting = Self.colorSettings[safe: indexPath.section],
              let settings = colorSetting[safe: indexPath.row]
        else {
            return
        }
        
        self.indexPath = indexPath
        
        myLabel.text = settings.name
        myLabel.textColor = UIColor(rgb: settings.color)
        myView.backgroundColor = UIColor(rgb: settings.backgroundColor)
        
        gestureRecognizerSetting(with: indexPath, settings: settings)
    }
    
    /// 設定點下去的功能
    /// - Parameter indexPath: IndexPath
    func gestureRecognizerSetting(with indexPath: IndexPath, settings: ColorSettings) {
        
        guard let key = Constant.SettingsColorKey(rawValue: indexPath.section) else { return }
                
        switch key {
        case .sentenceSpeech, .vocabularyLevel, .wordSpeech:
            myLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Self.selectTextColor(_:))))
            myView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Self.selectBackgroundColor(_:))))

        case .animation, .background:
            myView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Self.animationGallery(_:))))
        }
    }
    
    /// 被點選到的顏色資訊
    /// - Returns: Constant.PaletteInformation
    func selectColorInformation() -> Constant.PaletteInformation {
        
        let info: Constant.PaletteInformation = (myLabel.textColor, myView.backgroundColor)
        return info
    }
}

// MARK: - GIF動畫
extension PaletteTableViewCell {
    
    /// 執行GIF動畫
    func executeAnimation(with indexPath: IndexPath) {
        
        guard let colorSetting = Self.colorSettings[safe: indexPath.section],
              let key = Constant.SettingsColorKey(rawValue: indexPath.section),
              let setting = colorSetting[safe: indexPath.row]
        else {
            return
        }
        
        var filename: String?
        
        let folderType: Constant.AnimationGifFolder = (key == .animation) ? .animation : .background
        
        if let setting = setting as? AnimationSettings { filename = setting.filename }
        if let url = Constant.AnimationGifType(rawValue: setting.key)?.fileURL(with: folderType, filename: filename) {
            isAnimationStop = false
            animationBlock?(url)
        }
    }
    
    /// 移除GIF動畫Block
    func removeGifBlock() {
        
        animationBlock = nil
        isAnimationStop = true
        myImageBaseView.subviews.forEach { $0.removeFromSuperview() }
        gifImageView = nil
    }
    
    /// 初始化GIF動畫Block
    func initGifBlockSetting() {
        
        let gifImageView = UIImageView()
        
        gifImageView.contentMode = .scaleAspectFit
        gifImageView._autolayout(on: myImageBaseView)
        self.gifImageView = gifImageView
        
        animationBlock = {
            
            _ = gifImageView._GIF(url: $0) { [weak self] result in
                
                guard let this = self else { return }
                
                switch result {
                case .failure(let error): myPrint(error)
                case .success(let info):
                    info.pointer.pointee = this.isAnimationStop
                    if (this.isAnimationStop) { this.gifImageView?.image = nil }
                }
            }
        }
    }
}
