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
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var correctCountLabel: UILabel!
    @IBOutlet weak var mistakeCountLabel: UILabel!
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @IBAction func playSound(_ sender: UIButton) { playWordSound() }
    
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
        
        wordLabel.font = Constant.currentTableName.font() ?? UIFont.systemFont(ofSize: 36.0)
        wordLabel.text = "\(vocabularyReviewList.word)"
        
        correctCountLabel.text = "\(vocabularyReviewList.correctCount)"
        mistakeCountLabel.text = "\(vocabularyReviewList.mistakeCount)"
    }
    
    /// 讀出單字
    func playWordSound() {
        guard let vocabularyReviewList = vocabularyReviewList else { return }
        Utility.shared.speak(string: vocabularyReviewList.word, voice: Constant.currentTableName)
    }
}
