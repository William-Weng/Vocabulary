//
//  SolutionTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/4.
//

import UIKit
import WWPrint

// MARK: - 複習單字解答列表
final class SolutionTableViewCell: UITableViewCell, CellReusable {
    
    static var vocabularyReviewListArray: [[String : Any]] = []
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    
    var indexPath: IndexPath = []
    
    private var vocabularyList: VocabularyList?
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @IBAction func playSound(_ sender: UIButton) { playWordSound() }
    
    deinit { wwPrint("\(Self.self) deinit") }
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
        
        alphabetLabel.text = vocabularyList.alphabet

        wordLabel.text = vocabularyList.word
        wordLabel.font = Constant.currentTableName.font() ?? UIFont.systemFont(ofSize: 36.0)
    }
    
    /// 讀出單字
    func playWordSound() {
        guard let vocabularyList = vocabularyList else { return }
        Utility.shared.speak(string: vocabularyList.word, voice: Constant.currentTableName)
    }
}
