//
//  PaletteHeaderCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/9/9.
//

import UIKit

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
        myLabel.text = groupTitle(with: section)
    }
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
extension PaletteHeader {
    
    /// 載入XIB的一些基本設定
    func initViewFromXib() {
        
        let xibName = String(describing: Self.self)
        let bundle = Bundle(for: Self.self)
        
        bundle.loadNibNamed(xibName, owner: self, options: nil)
        view.frame = bounds
        addSubview(view)
    }
    
    /// 設定顏色群組的標題文字
    /// - Parameter section: Int
    /// - Returns: String?
    func groupTitle(with section: Int) -> String? {
        
        guard let colorKey = Constant.SettingsColorKey.allCases[safe: section] else { return nil }
        return colorKey.name()
    }
}
