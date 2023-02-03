//
//  ViewController.swift
//  Vocabulary
//
//  Created by iOS on 2023/2/2.
//

import UIKit

// MARK: - 搜尋結果單字詞性 / 解譯
final class InterpretView: UIView {

    @IBOutlet var view: UIView!
    
    @IBOutlet weak var speechLabel: UILabel!
    @IBOutlet weak var interpretLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViewFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initViewFromXib()
    }
    
    /// 相關畫面設定
    /// - Parameter vocabulary: Vocabulary
    func configure(with vocabulary: Vocabulary) { configure(for: vocabulary) }
}

// MARK: - 小工具
private extension InterpretView {
    
    /// 載入XIB的一些基本設定
    func initViewFromXib() {
        
        let xibName = String(describing: Self.self)
        let bundle = Bundle(for: Self.self)
        
        bundle.loadNibNamed(xibName, owner: self, options: nil)
        view.frame = bounds
        addSubview(view)
    }
    
    /// 畫面設定
    /// - Parameter vocabulary: Vocabulary
    func configure(for vocabulary: Vocabulary) {
        
        let speechType = Vocabulary.Speech(rawValue: vocabulary.speech) ?? .noue
        
        speechLabel.text = speechType.value()
        speechLabel.backgroundColor = speechType.backgroundColor()
        
        interpretLabel.text = vocabulary.interpret
    }
}
