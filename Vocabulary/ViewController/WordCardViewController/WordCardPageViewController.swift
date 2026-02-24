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
    @IBOutlet weak var levelButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    
    private var isFavorite = false
    private var indexPath = IndexPath()
    private var vocabularyList: VocabularyList?
    private var vocabulary: Vocabulary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    @objc func playWordSound(_ gesture: UITapGestureRecognizer) {
        playSound(string: wordLabel.text)
        wordLabel.start(fps: 5, stringType: .general(vocabularyList?.word))
    }
    
    @objc func playExampleSound(_ gesture: UITapGestureRecognizer) {
        playSound(string: exampleLabel.text)
        exampleLabel.start(fps: 15, stringType: .general(vocabulary?.example))
    }
    
    @IBAction func favoriteAction(_ sender: UIButton) {
        isFavorite.toggle()
        updateFavorite(isFavorite, with: indexPath)
    }
    
    /// 設定文字 / 外觀
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath) {
        
        guard let vocabularyList = WordMemoryItemCell.vocabularyList(with: indexPath),
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
        
        initSetting(vocabulary: vocabulary)
        initSetting(vocabularyList: vocabularyList)
        speechLabelSetting(speechLabel, with: info)
    }
    
    /// 閱讀文字內容 (單字 + 範例)
    func speakContent() {
        
        guard let word = vocabularyList?.word,
              let example = vocabulary?.example
        else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constant.duration) { [unowned self] in
            playSound(string: "\(word). \(example)")
        }
    }
    
    /// 打字機文字顯示 (文字效果)
    /// - Parameter isSpeak: Bool
    func typewriter(isSpeak: Bool = true) {
        
        if (isSpeak) { speakContent() }
        
        wordLabel.start(fps: 5, stringType: .general(vocabularyList?.word))
        exampleLabel.start(fps: 10, stringType: .general(vocabulary?.example))
    }
    
    deinit { myPrint("\(Self.self) deinit") }
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
    
    /// 初始化有關單字的設定
    /// - Parameter vocabularyList: VocabularyList
    func initSetting(vocabularyList: VocabularyList) {
           
        self.vocabularyList = vocabularyList
        
        isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        favoriteButton.setBackgroundImage(Utility.shared.favoriteIcon(isFavorite), for: .normal)
        
        countLabel.text = "\(vocabularyList.count)"
        countLabel.clipsToBounds = true
        
        wordLabel.text = vocabularyList.word
        alphabetLabel.text = vocabularyList.alphabet
        
        initLevelButtonSetting(vocabularyList: vocabularyList)
    }
    
    /// 初始化有關單字內容的設定
    /// - Parameter vocabulary: Vocabulary
    func initSetting(vocabulary: Vocabulary) {
           
        self.vocabulary = vocabulary
        
        interpretLabel.text = vocabulary.interpret
        exampleLabel.text = vocabulary.example
        translateLabel.text = vocabulary.translate
    }
    
    /// 讀出文字句子
    /// - Parameter string: String?
    func playSound(string: String?) {
        
        guard let string = string,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        Utility.shared.speak(string: string, code: settings.voice, rate: Constant.speakingSpeed, volume: Constant.speakingVolume)
    }
    
    /// speechLabel文字顏色設定
    /// - Parameters:
    ///   - label: UILabel
    ///   - info: Settings.WordSpeechInformation?
    func speechLabelSetting(_ label: UILabel, with info: Settings.WordSpeechInformation) {
        
        label.clipsToBounds = true
        label.text = info.name
        label.textColor = UIColor(rgb: info.color)
        label.backgroundColor = UIColor(rgb: info.backgroundColor)
    }
    
    /// 初始化等級設定
    /// - Parameter vocabularyList: VocabularyList
    func initLevelButtonSetting(vocabularyList: VocabularyList) {
        
        let info = Constant.SettingsJSON.vocabularyLevelInformations[safe: vocabularyList.level]

        levelButton.showsMenuAsPrimaryAction = true
        levelButton.menu = UIMenu(title: "請選擇等級", options: .singleSelection , children: levelMenuActionMaker())
        
        Utility.shared.levelButtonSetting(levelButton, with: info)
    }
    
    /// 產生LevelButton選到時的動作
    /// - Returns: [UIAction]
    func levelMenuActionMaker() -> [UIAction] {
        let actions = Constant.SettingsJSON.vocabularyLevelInformations.map { return levelActionMaker($0) }
        return actions
    }
    
    /// 產生LevelButton選到時的動作
    /// - Returns: [UIAction]
    func levelActionMaker(_ info: Settings.VocabularyLevelInformation) -> UIAction {
        
        let action = UIAction(title: info.name) { [weak self] _ in
            guard let this = self else { return }
            this.updateLevel(info, with: this.indexPath)
        }
        
        return action
    }
    
    /// 更新Favorite狀態
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavorite(_ isFavorite: Bool, with indexPath: IndexPath) {
                
        guard let vocabularyList = WordMemoryItemCell.vocabularyList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
                
        let isSuccess = API.shared.updateVocabularyFavoriteToList(vocabularyList.id, info: info, isFavorite: isFavorite)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        favoriteButton.setBackgroundImage(Utility.shared.favoriteIcon(isFavorite), for: .normal)
        Utility.shared.updateFavoriteDictionary(isFavorite, with: indexPath)
    }
    
    /// 更新LevelButton文字
    /// - Parameters:
    ///   - levelInfo: Settings.VocabularyLevelInformation
    ///   - indexPath: IndexPath
    func updateLevel(_ levelInfo: Settings.VocabularyLevelInformation, with indexPath: IndexPath) {
        
        guard let vocabularyList = WordMemoryItemCell.vocabularyList(with: indexPath),
              let generalInfo = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.updateLevelToList(vocabularyList.id, levelInfo: levelInfo, generalInfo: generalInfo)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        Utility.shared.levelButtonSetting(levelButton, with: levelInfo)
        Utility.shared.updateLevelDictionary(levelInfo, with: indexPath)
    }
}
