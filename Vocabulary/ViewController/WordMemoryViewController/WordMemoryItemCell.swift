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
        
        configureView(for: indexPath, vocabularyList: vocabularyList)
        configureLayer()
    }
    
    /// 讀出單字
    func playWordSound() {
        
        guard indexPath.row == 0,
              let vocabularyList = vocabularyList,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        Utility.shared.speak(string: vocabularyList.word, code: settings.voice, rate: Constant.speakingSpeed)
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

// MARK: - 小工具 (function)
private extension WordMemoryItemCell {
    
    /// 有關ImageView的設定
    /// - Parameter isFavorite: Bool
    func configureImageView(isFavorite: Bool) {
        initFavoriteImageViewTapGestureRecognizer()
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
    }
    
    /// 有關基本View的設定
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - vocabularyList: VocabularyList
    func configureView(for indexPath: IndexPath, vocabularyList: VocabularyList) {
        
        self.vocabularyList = vocabularyList
        
        wordLabel.text = vocabularyList.word
        wordLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 36.0)
        
        alphabetLabel.text = vocabularyList.alphabet
        
        isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        
        buttonsHiddenSetting(with: indexPath)
        configureImageView(isFavorite: isFavorite)
    }
    
    /// 有關Layer陰影的設定
    func configureLayer() {
        
        let condition = (Self.vocabularyListArray.count % 2 == 0) ? (indexPath.row % 2 == 0) : (indexPath.row % 2 != 0)
        let backgroundColor = condition ? UIColor(rgb: "#FFFFAA") : UIColor(rgb: "#DFFFDF")
        
        layer._shadow(color: .gray, backgroundColor: backgroundColor, offset: .zero, opacity: 0.5, radius: 3.0, cornerRadius: 8.0)
    }
    
    /// FavoriteImageView點擊功能
    func initFavoriteImageViewTapGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateFavorite(_:)))
        favoriteImageView.addGestureRecognizer(recognizer)
    }
    
    /// 設定按鍵要不要顯示 => 只有最上面的一個要顯示
    /// - Parameter indexPath: IndexPath
    func buttonsHiddenSetting(with indexPath: IndexPath) {
        
        let isHidden = (indexPath.row != 0)
        
        favoriteImageView.isHidden = isHidden
        vocabularyDetailButton.isHidden = isHidden
    }
}
