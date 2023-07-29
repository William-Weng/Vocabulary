//
//  SearchWordTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/30.
//

import UIKit
import WWPrint

// MARK: - 搜尋的單字列表Cell
final class SearchWordTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    @IBOutlet weak var interpretListStackView: UIStackView!
    @IBOutlet weak var favoriteImageView: UIImageView!
    
    static var searchType: Constant.SearchType = .word
    static var vocabularyListArray: [[String : Any]] = [] { didSet { Self.updateWordsDetailArray() }}
    
    var indexPath: IndexPath = []
    
    private static var vocabularyDeteilListArray: [[String : Any]] = []
    
    private var isFavorite = false
    private var vocabularyList: VocabularyList?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        interpretListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        favoriteImageView.gestureRecognizers?.forEach({ favoriteImageView.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @IBAction func playSound(_ sender: UIButton) { playWordSound() }
    
    @objc func updateFavorite(_ recognizer: UITapGestureRecognizer) {
        isFavorite.toggle()
        updateFavorite(isFavorite, with: indexPath)
    }
    
    deinit { wwPrint("\(Self.self) deinit", isShow: Constant.isPrint) }
}

// MARK: - 小工具
private extension SearchWordTableViewCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabularyList(with indexPath: IndexPath) -> VocabularyList? {
        
        guard let list = Self.vocabularyListArray[safe: indexPath.row],
              let vocabularyList = list._jsonClass(for: VocabularyList.self)
        else {
            return nil
        }

        return vocabularyList
    }
    
    /// 取得細節單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabularyDeteilList(with indexPath: IndexPath) -> Vocabulary? {
        
        guard let listArray = Self.vocabularyDeteilListArray[safe: indexPath.row],
              let vocabulary = listArray._jsonClass(for: Vocabulary.self)
        else {
            return nil
        }
        
        return vocabulary
    }
    
    /// 更新特定單字群的列表 => in(["word", "detail"])
    static func updateWordsDetailArray() {
        let words = Self.words(with: Self.vocabularyListArray.count)
        Self.vocabularyDeteilListArray = API.shared.searchWordDetail(in: Array(words), for: Constant.currentTableName, offset: 0)
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
private extension SearchWordTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        let vocabularyDeteilArray = Self.vocabularyDeteil(for: vocabularyList.word)
                
        self.indexPath = indexPath
        self.vocabularyList = vocabularyList
        self.isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        
        wordLabel.font = Constant.currentTableName.font() ?? UIFont.systemFont(ofSize: 36.0)
        wordLabel.text = vocabularyList.word
        
        alphabetLabel.text = vocabularyList.alphabet
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        initFavoriteImageViewTapGestureRecognizer()
        
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
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        let isSuccess = API.shared.updateVocabularyFavoriteToList(vocabularyList.id, isFavorite: isFavorite, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }

        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        updateFavoriteDictionary(isFavorite, with: indexPath)
    }
    
    /// 更新暫存的我的最愛資訊
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavoriteDictionary(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard var dictionary = Self.vocabularyListArray[safe: indexPath.row] else { return }

        let favorite = isFavorite._int()
        dictionary["favorite"] = favorite
        
        Self.vocabularyListArray[indexPath.row] = dictionary
    }
}
