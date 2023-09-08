//
//  PaletteTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/9/8.
//

import UIKit

final class PaletteTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var myView: UIView!
    @IBOutlet weak var myLabel: UILabel!
    
    static var paletteViewDelegate: PaletteViewDelegate?
    static var colorKeys: [Constant.SettingsColorKey] = []

    var indexPath: IndexPath = []
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
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
    
    deinit {
        myPrint("\(Self.self) init")
    }
}

// MARK: - 小工具
extension PaletteTableViewCell {
    
    /// 初始化設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let coloeKey = Self.colorKeys[safe: indexPath.section],
              let info = coloeKey.informations()?[safe: indexPath.row]
        else {
            return
        }
        
        myLabel.text = info.name
        myLabel.textColor = UIColor(rgb: info.color)
        myLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Self.selectTextColor(_:))))
        
        myView.backgroundColor = UIColor(rgb: info.backgroundColor)
        myView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Self.selectBackgroundColor(_:))))
    }
    
    /// 被點選到的顏色資訊
    /// - Returns: Constant.PaletteInformation
    func selectColorInformation() -> Constant.PaletteInformation {
        
        let info: Constant.PaletteInformation = (myLabel.textColor, myView.backgroundColor)
        return info
    }
}
