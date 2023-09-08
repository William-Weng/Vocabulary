//
//  SearchVocabularyTableViewCell.swift
//  Vocabulary
//
//  Created by iOS on 2023/7/27.
//

import UIKit

// MARK: - 搜尋的單字列表Cell
final class SearchVocabularyTableViewCell: UITableViewCell, CellReusable {
    
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
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
private extension SearchVocabularyTableViewCell {
    
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
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        let words = Self.words(with: Self.vocabularyListArray.count)
        Self.vocabularyDeteilListArray = API.shared.searchWordDetail(in: Array(words), info: info, offset: 0)
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
private extension SearchVocabularyTableViewCell {
        
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        let vocabularyDeteilArray = Self.vocabularyDeteil(for: vocabularyList.word)
                
        self.indexPath = indexPath
        self.vocabularyList = vocabularyList
        self.isFavorite = ((vocabularyList.favorite ?? 0) != 0)
        
        wordLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 36.0)
        wordLabel.text = vocabularyList.word
        
        alphabetLabel.text = vocabularyList.alphabet
                
        favoriteImageViewSetting(isFavorite: isFavorite)
        
        initFavoriteImageViewTapGestureRecognizer()
        
        vocabularyDeteilArray.forEach { vocabulary in
            
            let subLabel = InterpretView()
            subLabel.configure(with: vocabulary, textColor: .secondarySystemBackground)
            
            interpretListStackView.addArrangedSubview(subLabel)
        }
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
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.updateVocabularyFavoriteToList(vocabularyList.id, info: info, isFavorite: isFavorite)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }

        favoriteImageViewSetting(isFavorite: isFavorite)
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
    
    /// 設定favoriteImageView的圖片顏色
    /// - Parameter isFavorite: Bool
    func favoriteImageViewSetting(isFavorite: Bool) {
        
        favoriteImageView.image = UIImage(named: "Notice_On")?.withRenderingMode(.alwaysTemplate)
        favoriteImageView.tintColor = !isFavorite ? .lightGray : .systemRed
    }
}
