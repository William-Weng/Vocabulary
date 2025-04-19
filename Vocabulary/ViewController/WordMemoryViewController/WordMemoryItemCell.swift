//
//  WordMemoryItemCell.swift
//  Vocabulary
//
//  Created by William Weng on 2025/4/19.
//

import UIKit

// MARK: - 單字記憶Cell
final class WordMemoryItemCell: UICollectionViewCell, CellReusable {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    @IBOutlet weak var favoriteImageView: UIImageView!
    @IBOutlet weak var vocabularyDetailButton: UIButton!
    @IBOutlet weak var removeItemButton: UIButton!
    
    static weak var wordMemoryDelegate: WordMemoryDelegate?
    static var vocabularyListArray: [[String : Any]] = []

    var indexPath: IndexPath = []
    
    private var isFavorite = false
    private var vocabularyList: VocabularyList?
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath) {
        self.indexPath = indexPath
        configure(for: indexPath)
    }
    
    @objc func updateFavorite(_ recognizer: UITapGestureRecognizer) {
        isFavorite.toggle()
        updateFavorite(isFavorite, with: indexPath)
    }
    
    @IBAction func removeItem(_ sender: UIButton) {
        Self.wordMemoryDelegate?.deleteItem()
    }
    
    @IBAction func gotoVocabularyDetailPage(_ sender: UIButton) {
        Self.wordMemoryDelegate?.itemDetail(with: indexPath)
    }
    
    deinit {
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - 小工具 (static function)
extension WordMemoryItemCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabularyList(with indexPath: IndexPath) -> VocabularyList? {
        guard let vocabularyList = Self.vocabularyListArray[safe: indexPath.row]?._jsonClass(for: VocabularyList.self) else { return nil }
        return vocabularyList
    }
}

// MARK: - 小工具 (function)
extension WordMemoryItemCell {
    
    /// 畫面設定  (畫面顏色要重新設定)
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        let condition = (Self.vocabularyListArray.count % 2 == 0) ? (indexPath.row % 2 == 0) : (indexPath.row % 2 != 0)

        wordLabel.text = vocabularyList.word
        wordLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 36.0)
        
        alphabetLabel.text = vocabularyList.alphabet
        
        self.backgroundColor = condition ? UIColor(rgb: "#FFFFAA") : UIColor(rgb: "#DFFFDF")
        self.isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        self.vocabularyList = vocabularyList
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        initFavoriteImageViewTapGestureRecognizer()
        
        buttonsHiddenSetting(with: indexPath)
    }
    
    /// 讀出單字
    func playWordSound() {
        
        guard indexPath.row == 0,
              let vocabularyList = vocabularyList,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        Utility.shared.speak(string: vocabularyList.word, code: settings.voice)
    }
    
    /// 設定按鍵要不要顯示 => 只有最上面的一個要顯示
    /// - Parameter indexPath: IndexPath
    func buttonsHiddenSetting(with indexPath: IndexPath) {
        
        let isHidden = (indexPath.row != 0)
        
        favoriteImageView.isHidden = isHidden
        vocabularyDetailButton.isHidden = isHidden
        removeItemButton.isHidden = isHidden
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
    
    /// FavoriteImageView點擊功能
    func initFavoriteImageViewTapGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateFavorite(_:)))
        favoriteImageView.addGestureRecognizer(recognizer)
    }
}
