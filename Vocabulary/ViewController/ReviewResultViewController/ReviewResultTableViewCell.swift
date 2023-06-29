//
//  ReviewResultTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/7.
//

import UIKit
import WWPrint

// MARK: - 複習單字結果的Cell
final class ReviewResultTableViewCell: UITableViewCell, CellReusable {

    static var reviewResultListArray: [[String : Any]] = []

    var indexPath: IndexPath = []
    
    private var vocabularyReviewList: VocabularyReviewList?
    private var isFavorite = false
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var correctCountLabel: UILabel!
    @IBOutlet weak var mistakeCountLabel: UILabel!
    @IBOutlet weak var favoriteImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        favoriteImageView.gestureRecognizers?.forEach({ favoriteImageView.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @IBAction func playSound(_ sender: UIButton) { playWordSound() }
    
    @objc func updateFavorite(_ recognizer: UITapGestureRecognizer) {
        isFavorite.toggle()
        updateFavorite(isFavorite, with: indexPath)
    }
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
extension ReviewResultTableViewCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func reviewResultList(with indexPath: IndexPath) -> VocabularyReviewList? {
        guard let vocabularyReviewList = Self.reviewResultListArray[safe: indexPath.row]?._jsonClass(for: VocabularyReviewList.self) else { return nil }
        return vocabularyReviewList
    }
}

// MARK: - 小工具
private extension ReviewResultTableViewCell {
    
    /// 畫面設定
    func configure(for indexPath: IndexPath) {
        
        guard let vocabularyReviewList = Self.reviewResultList(with: indexPath) else { return }
        
        self.indexPath = indexPath
        self.vocabularyReviewList = vocabularyReviewList
        self.isFavorite = ((vocabularyReviewList.favorite ?? 0) != 0)

        wordLabel.font = Constant.currentTableName.font() ?? UIFont.systemFont(ofSize: 36.0)
        wordLabel.text = "\(vocabularyReviewList.word)"
        
        correctCountLabel.text = "\(vocabularyReviewList.correctCount)"
        mistakeCountLabel.text = "\(vocabularyReviewList.mistakeCount)"
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        initFavoriteImageViewTapGestureRecognizer()
    }
    
    /// 讀出單字
    func playWordSound() {
        guard let vocabularyReviewList = vocabularyReviewList else { return }
        Utility.shared.speak(string: vocabularyReviewList.word, voice: Constant.currentTableName)
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

        guard let vocabularyReviewList = Self.reviewResultList(with: indexPath) else { return }
        
        let isSuccess = API.shared.updateVocabularyFavoriteToList(vocabularyReviewList.wordId, isFavorite: isFavorite, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        updateFavoriteDictionary(isFavorite, with: indexPath)
    }
    
    /// 更新暫存的我的最愛資訊
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavoriteDictionary(_ isFavorite: Bool, with indexPath: IndexPath) {

        guard var dictionary = Self.reviewResultListArray[safe: indexPath.row] else { return }

        let favorite = isFavorite._int()
        dictionary["favorite"] = favorite

        Self.reviewResultListArray[indexPath.row] = dictionary
    }
}
