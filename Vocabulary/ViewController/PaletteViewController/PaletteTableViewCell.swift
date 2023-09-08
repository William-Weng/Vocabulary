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
    static var colorKeys = Constant.SettingsColorKey.allCases

    var indexPath: IndexPath = []
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        myView.gestureRecognizers?.forEach({ myView.removeGestureRecognizer($0) })
        myLabel.gestureRecognizers?.forEach({ myLabel.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @objc func selectTextColor(_ sender: UITapGestureRecognizer) {
        
        let info: Constant.PaletteInformation = (.white, .black)
        Self.paletteViewDelegate?.palette(with: indexPath, info: info)
    }
    
    @objc func selectBackgroundColor(_ sender: UITapGestureRecognizer) {
        
        let info: Constant.PaletteInformation = (.white, .black)
        Self.paletteViewDelegate?.palette(with: indexPath, info: info)
    }
}

// MARK: - 小工具
extension PaletteTableViewCell {
    
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
}
