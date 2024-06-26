//
//  SentenceTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng 2023/2/6.
//

import UIKit

// MARK: - 例句列表
final class SentenceTableViewCell: UITableViewCell, CellReusable {
    
    static var sentenceListArray: [[String : Any]] = []
    
    @IBOutlet weak var exampleLabel: UILabel!
    @IBOutlet weak var translateLabel: UILabel!
    @IBOutlet weak var speechButton: UIButton!
    @IBOutlet weak var favoriteImageView: UIImageView!
    
    static weak var sentenceViewDelegate: SentenceViewDelegate?
    
    var indexPath: IndexPath = []
    
    private var isFavorite = false
    private var sentenceList: VocabularySentenceList?
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @objc func persentNetDictionary(_ sender: UITapGestureRecognizer) { Self.sentenceViewDelegate?.wordDictionary(with: indexPath) }

    @objc func updateFavorite(_ recognizer: UITapGestureRecognizer) {
        isFavorite.toggle()
        updateFavorite(isFavorite, with: indexPath)
    }

    @IBAction func playSound(_ sender: UIButton) { playExampleSound() }
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
extension SentenceTableViewCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func sentenceList(with indexPath: IndexPath) -> VocabularySentenceList? {
        guard let sentenceList = Self.sentenceListArray[safe: indexPath.row]?._jsonClass(for: VocabularySentenceList.self) else { return nil }
        return sentenceList
    }
}

// MARK: - 小工具
private extension SentenceTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let sentenceList = Self.sentenceList(with: indexPath) else { return }
        
        let info = Constant.SettingsJSON.sentenceSpeechInformations[safe: sentenceList.speech]

        self.accessoryView = accessoryViewMaker()
        self.indexPath = indexPath
        self.sentenceList = sentenceList
        self.isFavorite = ((sentenceList.favorite ?? 0) != 0)
        
        translateLabel.text = sentenceList.translate
        
        exampleLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 24.0)
        exampleLabel.text = sentenceList.example
        
        speechButtonSetting(speechButton, with: info)
        speechButton.showsMenuAsPrimaryAction = true
        speechButton.menu = UIMenu(title: "請選擇分類", options: .singleSelection, children: speechMenuActionMaker())
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        initFavoriteImageViewTapGestureRecognizer()
    }
    
    /// FavoriteImageView點擊功能
    func initFavoriteImageViewTapGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateFavorite(_:)))
        favoriteImageView.addGestureRecognizer(recognizer)
    }
    
    /// 讀出例句
    func playExampleSound() {
        
        guard let sentenceList = sentenceList,
              let example = sentenceList.example,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        Utility.shared.speak(string: example, code: settings.voice)
    }
    
    /// 最右側的箭頭View
    /// - Returns: UIImageView
    func accessoryViewMaker() -> UIImageView {
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "NextArrow"))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(Self.persentNetDictionary(_:)))
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapRecognizer)
        
        return imageView
    }
    
    /// 產生LevelButton選到時的動作
    /// - Returns: [UIAction]
    func speechMenuActionMaker() -> [UIAction] {
        let actions = Constant.SettingsJSON.sentenceSpeechInformations.map { return speechActionMaker(with: $0) }
        return actions
    }
    
    /// 產生LevelButton選到時的動作
    /// - Parameter info: Settings.SentenceSpeechInformation
    /// - Returns: UIAction
    func speechActionMaker(with info: Settings.SentenceSpeechInformation) -> UIAction {
        
        let action = UIAction(title: info.name) { [weak self] _ in
            
            guard let this = self else { return }
                            
            this.updateSpeech(info, with: this.indexPath)
            this.updateLevelDictionary(info, with:this.indexPath)
        }
        
        return action
    }
    
    /// 更新SpeechButton文字
    /// - Parameters:
    ///   - speechInfo: Settings.SentenceSpeechInformation
    ///   - indexPath: IndexPath
    func updateSpeech(_ speechInfo: Settings.SentenceSpeechInformation, with indexPath: IndexPath) {
        
        guard let sentenceList = Self.sentenceList(with: indexPath),
              let generalInfo = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.updateSentenceSpeechToList(sentenceList.id, speechInfo: speechInfo, generalInfo: generalInfo)

        if (!isSuccess) { Utility.shared.flashHUD(with: .fail) }
        speechButtonSetting(speechButton, with: speechInfo)
    }
    
    /// speechButton文字顏色設定
    /// - Parameters:
    ///   - button: UIButton
    ///   - info: Settings.SentenceSpeechInformation?
    func speechButtonSetting(_ button: UIButton, with info: Settings.SentenceSpeechInformation?) {
        
        button.setTitle(info?.name ?? "一般", for: .normal)
        button.setTitleColor(UIColor(rgb: info?.color ?? "#ffffff"), for: .normal)
        button.backgroundColor = UIColor(rgb: info?.backgroundColor ?? "#000000")
    }
    
    /// 更新Favorite狀態
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavorite(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard let sentenceList = Self.sentenceList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }

        let isSuccess = API.shared.updateSentenceFavoriteToList(sentenceList.id, isFavorite: isFavorite, info: info)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }

        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        updateFavoriteDictionary(isFavorite, with: indexPath)
    }
    
    /// 更新暫存的單字內容列表資訊
    /// - Parameters:
    ///   - info: Settings.SentenceSpeechInformation
    ///   - indexPath: IndexPath
    func updateLevelDictionary(_ info: Settings.SentenceSpeechInformation, with indexPath: IndexPath) {
        
        guard var dictionary = Self.sentenceListArray[safe: indexPath.row] else { return }
        
        dictionary["speech"] = info.value
        Self.sentenceListArray[indexPath.row] = dictionary
    }
    
    /// 更新暫存的我的最愛資訊
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavoriteDictionary(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard var dictionary = Self.sentenceListArray[safe: indexPath.row] else { return }

        let favorite = isFavorite._int()
        dictionary["favorite"] = favorite

        Self.sentenceListArray[indexPath.row] = dictionary
    }
}
