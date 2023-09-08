//
//  ViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/2.
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
    func configure(with vocabulary: Vocabulary, textColor: UIColor = .label) { configure(for: vocabulary, textColor: textColor) }
    
    deinit { myPrint("\(Self.self) deinit") }
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
    func configure(for vocabulary: Vocabulary, textColor: UIColor = .label) {
        
        guard let info = Constant.SettingsJSON.wordSpeechInformations[safe: vocabulary.speech] else { return }
        
        speechLabelSetting(speechLabel, with: info)
        
        interpretLabel.text = vocabulary.interpret
        interpretLabel.textColor = textColor
    }
    
    /// speechLabel文字顏色設定
    /// - Parameters:
    ///   - label: UILabel
    ///   - info: Settings.WordSpeechInformation?
    func speechLabelSetting(_ label: UILabel, with info: Settings.WordSpeechInformation) {
        
        label.text = info.name
        label.textColor = UIColor(rgb: info.color)
        label.backgroundColor = UIColor(rgb: info.backgroundColor)
    }
}
