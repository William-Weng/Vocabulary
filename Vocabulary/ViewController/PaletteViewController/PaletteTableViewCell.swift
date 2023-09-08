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
    
    static var colorKeys = Constant.SettingsColorKey.allCases
    
    var indexPath: IndexPath = []
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
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
        myView.backgroundColor = UIColor(rgb: info.backgroundColor)
    }
}
