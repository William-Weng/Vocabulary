//
//  WordCardPageViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2024/2/12.
//

import UIKit
import WWTypewriterLabel

// MARK: - 單字卡內容
final class WordCardPageViewController: UIViewController {

    @IBOutlet weak var wordLabel: WWTypewriterLabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    @IBOutlet weak var speechLabel: UILabel!
    @IBOutlet weak var interpretLabel: UILabel!
    @IBOutlet weak var exampleLabel: WWTypewriterLabel!
    @IBOutlet weak var translateLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
    private var isFavorite = false
    private var indexPath = IndexPath()
    private var vocabularyList: VocabularyList?
    private var vocabulary: Vocabulary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    @objc func playWordSound(_ gesture: UITapGestureRecognizer) { playSound(string: wordLabel.text) }
    @objc func playExampleSound(_ gesture: UITapGestureRecognizer) { playSound(string: exampleLabel.text) }
    
    @IBAction func favoriteAction(_ sender: UIButton) { updateFavorite(!isFavorite, with: indexPath) }
    
    /// 設定文字 / 外觀
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath) {
        
        guard let vocabularyList = MainTableViewCell.vocabularyList(with: indexPath),
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        ListTableViewCell.exmapleList = API.shared.searchWordDetailList(vocabularyList.word, for: .default(settings.key))
        
        guard let vocabulary = ListTableViewCell.vocabulary(with: IndexPath(row: 0, section: 0)),
              let info = Constant.SettingsJSON.wordSpeechInformations[safe: vocabulary.speech]
        else {
            return
        }
        
        self.indexPath = indexPath
        self.vocabularyList = vocabularyList
        self.vocabulary = vocabulary
        
        isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        favoriteButton.setBackgroundImage(Utility.shared.favoriteIcon(isFavorite), for: .normal)
        
        wordLabel.text = vocabularyList.word
        alphabetLabel.text = vocabularyList.alphabet
        interpretLabel.text = vocabulary.interpret
        exampleLabel.text = vocabulary.example
        translateLabel.text = vocabulary.translate
        speechLabelSetting(speechLabel, with: info)
    }
    
    /// 閱讀文字內容
    func speakContent() {
        playSound(string: vocabularyList?.word)
        playSound(string: vocabulary?.example)
    }
    
    /// 打字機文字顯示
    func typewriter() {
        wordLabel.start(fps: 5, stringType: .general(vocabularyList?.word))
        exampleLabel.start(fps: 10, stringType: .general(vocabulary?.example))
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
        exampleLabel.isUserInteractionEnabled = true
        wordLabel.addGestureRecognizer(wordGesture)
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
    
    /// 更新Favorite狀態
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavorite(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard let vocabularyList = MainTableViewCell.vocabularyList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.updateVocabularyFavoriteToList(vocabularyList.id, info: info, isFavorite: isFavorite)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        favoriteButton.setBackgroundImage(Utility.shared.favoriteIcon(isFavorite), for: .normal)
        Utility.shared.updateFavoriteDictionary(isFavorite, with: indexPath)
    }
}
