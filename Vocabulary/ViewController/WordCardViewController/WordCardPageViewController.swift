//
//  WordCardPageViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2024/2/12.
//

import UIKit

// MARK: - 單字卡內容
final class WordCardPageViewController: UIViewController {

    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    @IBOutlet weak var speechLabel: UILabel!
    @IBOutlet weak var interpretLabel: UILabel!
    @IBOutlet weak var exampleLabel: UILabel!
    @IBOutlet weak var translateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    @objc func playWordSound(_ gesture: UITapGestureRecognizer) { playSound(string: wordLabel.text) }
    @objc func playExampleSound(_ gesture: UITapGestureRecognizer) { playSound(string: exampleLabel.text) }
    
    /// 設定文字 / 外觀
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath) {
        
        guard let list = MainTableViewCell.vocabularyList(with: indexPath),
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        ListTableViewCell.exmapleList = API.shared.searchWordDetailList(list.word, for: .default(settings.key))
        
        guard let vocabulary = ListTableViewCell.vocabulary(with: IndexPath(row: 0, section: 0)),
              let info = Constant.SettingsJSON.wordSpeechInformations[safe: vocabulary.speech]
        else {
            return
        }
        
        wordLabel.text = list.word
        alphabetLabel.text = list.alphabet
        interpretLabel.text = vocabulary.interpret ?? "----"
        exampleLabel.text = vocabulary.example ?? "----"
        translateLabel.text = vocabulary.translate ?? "----"
        speechLabelSetting(speechLabel, with: info)
    }
}

// MARK: - 小工具
private extension WordCardPageViewController {
    
    /// 初始化設定
    func initSetting() {
        initGestureSetting()
        initLabelSetting()
    }
    
    /// Label設定
    func initLabelSetting() {
        wordLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 48.0)
        exampleLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 24.0)
    }
    
    /// 初始化Label點擊功能
    func initGestureSetting() {
        
        let wordGesture = UITapGestureRecognizer(target: self, action: #selector(WordCardPageViewController.playWordSound(_:)))
        let exampleGesture = UITapGestureRecognizer(target: self, action: #selector(WordCardPageViewController.playExampleSound(_:)))

        wordLabel.isUserInteractionEnabled = true
        wordLabel.addGestureRecognizer(wordGesture)
        exampleLabel.isUserInteractionEnabled = true
        exampleLabel.addGestureRecognizer(exampleGesture)
    }
    
    /// 讀出文字句子
    /// - Parameter string: String?
    func playSound(string: String?) {
        
        guard let string = string,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        Utility.shared.speak(string: string, code: settings.voice)
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
