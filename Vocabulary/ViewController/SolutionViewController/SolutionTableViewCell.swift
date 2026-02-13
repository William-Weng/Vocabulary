//
//  SolutionTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/4.
//

import UIKit

// MARK: - 複習單字解答列表
final class SolutionTableViewCell: UITableViewCell, CellReusable {
    
    static var vocabularyReviewListArray: [[String : Any]] = []
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    @IBOutlet weak var favoriteImageView: UIImageView!
    
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
extension SolutionTableViewCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabularyReviewList(with indexPath: IndexPath) -> VocabularyList? {
        guard let vocabularyList = Self.vocabularyReviewListArray[safe: indexPath.row]?._jsonClass(for: VocabularyList.self) else { return nil }
        return vocabularyList
    }
}

// MARK: - 小工具
private extension SolutionTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyReviewList(with: indexPath) else { return }
        
        self.indexPath = indexPath
        self.vocabularyList = vocabularyList
        self.isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        
        alphabetLabel.text = vocabularyList.alphabet

        wordLabel.text = vocabularyList.word
        wordLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 36.0)
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        initFavoriteImageViewTapGestureRecognizer()
    }
    
    /// 讀出單字
    func playWordSound() {
        
        guard let vocabularyList = vocabularyList,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        Utility.shared.speak(string: vocabularyList.word, code: settings.voice, rate: Constant.speakingSpeed, volume: Constant.speakingVolume)
    }
    
    /// FavoriteImageView點擊功能
    func initFavoriteImageViewTapGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateFavorite(_:)))
        favoriteImageView.addGestureRecognizer(recognizer)
    }

    /// 更新Favorite狀態
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavorite(_ isFavorite: Bool, with indexPath: IndexPath) {

        guard let vocabularyReviewList = Self.vocabularyReviewList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.updateVocabularyFavoriteToList(vocabularyReviewList.id, info: info, isFavorite: isFavorite)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        updateFavoriteDictionary(isFavorite, with: indexPath)
    }

    /// 更新暫存的我的最愛資訊
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavoriteDictionary(_ isFavorite: Bool, with indexPath: IndexPath) {

        guard var dictionary = Self.vocabularyReviewListArray[safe: indexPath.row] else { return }

        let favorite = isFavorite._int()
        dictionary["favorite"] = favorite

        Self.vocabularyReviewListArray[indexPath.row] = dictionary
    }
}
