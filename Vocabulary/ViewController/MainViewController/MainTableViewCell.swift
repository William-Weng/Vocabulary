//
//  MainTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import UIKit
import WWPrint
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
    
    deinit { wwPrint("\(Self.self) deinit") }
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
        
        let level = Vocabulary.Level(rawValue: vocabularyList.level) ?? .easy
        
        self.indexPath = indexPath
        self.vocabularyList = vocabularyList
        self.isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        
        countLabel.text = "\(vocabularyList.count)"
        alphabetLabel.text = vocabularyList.alphabet
        
        wordLabel.font = Constant.currentTableName.font() ?? UIFont.systemFont(ofSize: 36.0)
        wordLabel.text = vocabularyList.word
        
        levelButton.setTitle(level.value(), for: .normal)
        levelButton.backgroundColor = level.backgroundColor()
        levelButton.showsMenuAsPrimaryAction = true
        levelButton.menu = UIMenu(title: "請選擇等級", children: levelMenuActionMaker())
        
        favoriteImageView.image = (!isFavorite) ? UIImage(imageLiteralResourceName: "Notice_Off") : UIImage(imageLiteralResourceName: "Notice_On")
        initFavoriteImageViewTapGestureRecognizer()
    }
    
    /// FavoriteImageView點擊功能
    func initFavoriteImageViewTapGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateFavorite(_:)))
        favoriteImageView.addGestureRecognizer(recognizer)
    }
    
    /// 讀出單字
    func playWordSound() {
        guard let vocabularyList = vocabularyList else { return }
        Utility.shared.speak(string: vocabularyList.word, voice: Constant.currentTableName)
    }
    
    /// 產生LevelButton選到時的動作
    /// - Returns: [UIAction]
    func levelMenuActionMaker() -> [UIAction] {
        
        let actions = Vocabulary.Level.allCases.map { level in
            
            let action = UIAction(title: level.value()) { [weak self] action in
                guard let this = self else { return }
                this.updateLevel(level, with: this.indexPath)
            }
            return action
        }
        
        return actions
    }
    
    /// 更新LevelButton文字
    /// - Parameters:
    ///   - level: Vocabulary.Level
    ///   - indexPath: IndexPath
    func updateLevel(_ level: Vocabulary.Level, with indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        let isSuccess = API.shared.updateLevelToList(vocabularyList.id, level: level, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        levelButton.setTitle(level.value(), for: .normal)
        levelButton.backgroundColor = level.backgroundColor()
        
        updateLevelDictionary(level, with: indexPath)
    }
    
    /// 更新Favorite狀態
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavorite(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        let isSuccess = API.shared.updateVocabularyFavoriteToList(vocabularyList.id, isFavorite: isFavorite, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        favoriteImageView.image = (!isFavorite) ? UIImage(imageLiteralResourceName: "Notice_Off") : UIImage(imageLiteralResourceName: "Notice_On")
        updateFavoriteDictionary(isFavorite, with: indexPath)
    }
    
    /// 更新暫存的單字列表資訊
    /// - Parameters:
    ///   - level: Vocabulary.Level
    ///   - indexPath: IndexPath
    func updateLevelDictionary(_ level: Vocabulary.Level, with indexPath: IndexPath) {
        
        guard var dictionary = Self.vocabularyListArray[safe: indexPath.row] else { return }
        
        dictionary["level"] = level.rawValue
        Self.vocabularyListArray[indexPath.row] = dictionary
    }
    
    /// 更新暫存的我的最愛資訊
    /// - Parameters:
    ///   - level: Vocabulary.Level
    ///   - indexPath: IndexPath
    func updateFavoriteDictionary(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard var dictionary = Self.vocabularyListArray[safe: indexPath.row] else { return }
        
        let favorite = isFavorite._int()
        dictionary["favorite"] = favorite
        
        Self.vocabularyListArray[indexPath.row] = dictionary
    }
}
