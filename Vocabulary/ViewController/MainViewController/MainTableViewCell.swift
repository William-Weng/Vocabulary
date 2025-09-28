//
//  MainTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import UIKit
import AVFAudio

// MARK: - 單字頁面Cell
final class MainTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var levelButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    @IBOutlet weak var favoriteImageView: UIImageView!
    
    static var vocabularyListArray: [[String : Any]] = []
    
    var indexPath: IndexPath = []
    
    private var isFavorite = false
    private var vocabularyList: VocabularyList?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        favoriteImageView.gestureRecognizers?.forEach({ favoriteImageView.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @objc func updateFavorite(_ recognizer: UITapGestureRecognizer) {
        isFavorite.toggle()
        updateFavorite(isFavorite, with: indexPath)
    }
    
    @IBAction func playSound(_ sender: UIButton) { playWordSound() }    
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
extension MainTableViewCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabularyList(with indexPath: IndexPath) -> VocabularyList? {
        guard let vocabularyList = Self.vocabularyListArray[safe: indexPath.row]?._jsonClass(for: VocabularyList.self) else { return nil }
        return vocabularyList
    }
}

// MARK: - 小工具
private extension MainTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        self.indexPath = indexPath
        self.vocabularyList = vocabularyList
        self.isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        
        countLabel.text = "\(vocabularyList.count)"
        countLabel.clipsToBounds = true
        
        alphabetLabel.text = vocabularyList.alphabet
        
        wordLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 36.0)
        wordLabel.text = vocabularyList.word
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        initLevelButtonSetting(vocabularyList: vocabularyList)
        initFavoriteImageViewTapGestureRecognizer()
    }
    
    /// [初始化等級設定](https://juejin.cn/post/6982050059500126221)
    /// - Parameter vocabularyList: VocabularyList
    func initLevelButtonSetting(vocabularyList: VocabularyList) {
        
        let info = Constant.SettingsJSON.vocabularyLevelInformations[safe: vocabularyList.level]

        levelButton.showsMenuAsPrimaryAction = true
        levelButton.menu = UIMenu(title: "請選擇等級", options: .singleSelection, children: levelMenuActionMaker())
        
        Utility.shared.levelButtonSetting(levelButton, with: info)
    }
    
    /// FavoriteImageView點擊功能
    func initFavoriteImageViewTapGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateFavorite(_:)))
        favoriteImageView.addGestureRecognizer(recognizer)
    }
    
    /// 讀出單字
    func playWordSound() {
        
        guard let vocabularyList = vocabularyList,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        Utility.shared.speak(string: vocabularyList.word, code: settings.voice)
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
    
    /// 更新LevelButton文字
    /// - Parameters:
    ///   - levelInfo: Settings.VocabularyLevelInformation
    ///   - indexPath: IndexPath
    func updateLevel(_ levelInfo: Settings.VocabularyLevelInformation, with indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath),
              let generalInfo = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.updateLevelToList(vocabularyList.id, levelInfo: levelInfo, generalInfo: generalInfo)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        Utility.shared.levelButtonSetting(levelButton, with: levelInfo)
        Utility.shared.updateLevelDictionary(levelInfo, with: indexPath)
    }
        
    /// 更新Favorite狀態
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavorite(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.updateVocabularyFavoriteToList(vocabularyList.id, info: info, isFavorite: isFavorite)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        Utility.shared.updateFavoriteDictionary(isFavorite, with: indexPath)
    }
}
