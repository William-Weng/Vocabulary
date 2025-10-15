//
//  PaletteHeaderCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/9/9.
//

import UIKit

// MARK: - 調色盤設定Header
final class PaletteHeader: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var myLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViewFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initViewFromXib()
    }
    
    func configure(with section: Int) {
        myLabel.text = Self.groupColorKey(with: section)?.name()
        myLabel.clipsToBounds = true
    }
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
extension PaletteHeader {
    
    /// 設定顏色群組的標題設定值
    /// - Parameter section: Int
    /// - Returns: String?
    static func groupColorKey(with section: Int) -> Constant.SettingsColorKey? {
        
        guard let colorKey = Constant.SettingsColorKey.allCases[safe: section] else { return nil }
        return colorKey
    }
}

// MARK: - 小工具
private extension PaletteHeader {
    
    /// 載入XIB的一些基本設定
    func initViewFromXib() {
        
        let xibName = String(describing: Self.self)
        let bundle = Bundle(for: Self.self)
        
        bundle.loadNibNamed(xibName, owner: self, options: nil)
        view.frame = bounds
        addSubview(view)
    }
}
