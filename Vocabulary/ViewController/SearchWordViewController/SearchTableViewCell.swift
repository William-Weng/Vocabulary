//
//  SearchTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/30.
//

import UIKit
import WWPrint

// MARK: - 單字列表Cell
final class SearchTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    @IBOutlet weak var interpretListStackView: UIStackView!

    static var vocabularyListArray: [[String : Any]] = [] {
        didSet { Self.updateWordsDetailArray() }
    }
    
    private static var vocabularyDeteilListArray: [[String : Any]] = []
    
    var indexPath: IndexPath = []
    
    private var vocabularyList: VocabularyList?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        interpretListStackView.arrangedSubviews.forEach { subViews in
            subViews.removeFromSuperview()
        }
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    deinit { wwPrint("\(Self.self) deinit") }
    
    @IBAction func playSound(_ sender: UIButton) { playWordSound() }
}

// MARK: - 小工具
private extension SearchTableViewCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabularyList(with indexPath: IndexPath) -> VocabularyList? {
        guard let vocabularyList = Self.vocabularyListArray[safe: indexPath.row]?._jsonClass(for: VocabularyList.self) else { return nil }
        return vocabularyList
    }
    
    /// 取得細節單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabularyDeteilList(with indexPath: IndexPath) -> Vocabulary? {
        guard let vocabulary = Self.vocabularyDeteilListArray[safe: indexPath.row]?._jsonClass(for: Vocabulary.self) else { return nil }
        return vocabulary
    }
    
    /// 更新特定單字群的列表 => in(["word", "detail"])
    static func updateWordsDetailArray() {
        let words = Self.words(with: SearchTableViewCell.vocabularyListArray.count)
        SearchTableViewCell.vocabularyDeteilListArray = API.shared.searchWordDetail(in: Array(words), for: Constant.currentTableName, offset: 0)
    }
    
    /// 取得整體的word列表
    /// - Parameter count: Int
    /// - Returns: Set<String>
    static func words(with count: Int) -> Set<String> {
        
        var words: Set<String> = []
        
        for index in 0..<count {
            guard let vocabularyList = Self.vocabularyList(with: IndexPath(row: index, section: 0)) else { continue }
            words.insert(vocabularyList.word)
        }
        
        return words
    }
    
    /// 取得該單字的列表
    /// - Parameter word: String
    /// - Returns: [Vocabulary]
    static func vocabularyDeteil(for word: String) -> [Vocabulary] {
        
        var vocabularyArray: [Vocabulary] = []
        
        for index in 0..<Self.vocabularyDeteilListArray.count {
            
            guard let detailList = Self.vocabularyDeteilList(with: IndexPath(row: index, section: 0)),
                  word == detailList.word
            else {
                continue
            }
            
            vocabularyArray.append(detailList)
        }
        
        return vocabularyArray
    }
}

// MARK: - 小工具
private extension SearchTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        let vocabularyDeteilArray = Self.vocabularyDeteil(for: vocabularyList.word)
        
        self.indexPath = indexPath
        self.vocabularyList = vocabularyList
        
        wordLabel.font = Constant.currentTableName.font() ?? UIFont.systemFont(ofSize: 36.0)
        wordLabel.text = vocabularyList.word
        
        alphabetLabel.text = vocabularyList.alphabet

        vocabularyDeteilArray.forEach { vocabulary in

            let subLabel = InterpretView()
            subLabel.configure(with: vocabulary)
            
            interpretListStackView.addArrangedSubview(subLabel)
        }
    }
    
    /// 讀出單字
    func playWordSound() {
        guard let vocabularyList = vocabularyList else { return }
        Utility.shared.speak(string: vocabularyList.word, voice: Constant.currentTableName)
    }
}
