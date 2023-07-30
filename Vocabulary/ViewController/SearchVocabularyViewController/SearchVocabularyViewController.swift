//
//  SearchVocabularyViewController.swift
//  Vocabulary
//
//  Created by iOS on 2023/7/27.
//

import UIKit
import WWPrint

// MARK: - 快速搜尋單字小幫手
final class SearchVocabularyViewController: UIViewController {

    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var mySearchBar: UISearchBar!
    @IBOutlet weak var activityViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    private var isNeededUpdate = false
    private var currentSearchType: Constant.SearchType = .word { didSet { Utility.shared.switchSearchTypeAction(mySearchBar, for: currentSearchType) }}
    private var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        initSearchBar(with: .word)
        initSetting()
    }
    
    /// 切換要搜尋的類型分類
    /// - Parameter sender: UIButton
    @objc func switchSearchType(_ sender: UIButton) {
        
        let rawValue = currentSearchType.rawValue + 1
        
        currentSearchType = Constant.SearchType(rawValue: rawValue) ?? .word
        
        SearchVocabularyTableViewCell.searchType = currentSearchType
        mySearchBar.placeholder = "請輸入需要搜尋的\(currentSearchType)"
        sender.setTitle("  \(currentSearchType)  ", for: .normal)
        
        refreshSearchWord(refreshControl)
    }
    
    /// 重新讀取資料
    /// - Parameter word: String
    @objc func reloadSearchWord(_ word: String?) {
        searchWordList(like: word)
    }
    
    /// 重新讀取資料
    /// - Parameter refreshControl: UIRefreshControl
    @objc func refreshSearchWord(_ refreshControl: UIRefreshControl) {
        let word = mySearchBar.searchTextField.text
        searchWordList(like: word)
    }
    
    deinit {
        SearchVocabularyTableViewCell.vocabularyListArray = []
        wwPrint("\(Self.self) deinit", isShow: Constant.isPrint)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SearchVocabularyViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return SearchVocabularyTableViewCell.vocabularyListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return searchTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { self._dismissKeyboard() }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { mySearchBar.searchTextField._dismissKeyboard(); updateHeightPercentAction(with: scrollView, isNeededUpdate: isNeededUpdate) }
}

// MARK: - UITextFieldDelegate
extension SearchVocabularyViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField._dismissKeyboard(); return true }
}

// MARK: - UISearchBarDelegate
extension SearchVocabularyViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let selector = #selector(Self.reloadSearchWord(_:))
        selector._debounce(target: self, delayTime: Constant.searchDelayTime, object: searchText)
    }
}

// MARK: - 小工具
private extension SearchVocabularyViewController {
    
    /// 初始化設定
    func initSetting() {
                
        SearchVocabularyTableViewCell.searchType = currentSearchType
        SearchVocabularyTableViewCell.vocabularyListArray = []
        
        refreshControl = UIRefreshControl._build(title: Constant.reload, target: self, tintColor: .secondarySystemBackground, action: #selector(Self.refreshSearchWord(_:)))
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        
        updateActivityViewIndicatorSetting(with: 0.0, isNeededUpdate: false)
    }
    
    /// [初始化搜尋列](https://jjeremy-xue.medium.com/swift-客製化-navigation-bar-customized-navigation-bar-8e4eaf188d7c)
    /// - Parameter type: [Constant.SearchType](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/uitextfield-的-leftview-rightview-以放大鏡-密碼顯示開關為例-7813fa9fd4f1)
    func initSearchBar(with type: Constant.SearchType) {
        
        let leftButton = Utility.shared.searchTypeButtonMaker(with: type, backgroundColor: .systemRed)
        leftButton.addTarget(self, action: #selector(Self.switchSearchType(_:)), for: .touchUpInside)
        
        mySearchBar.placeholder = "請輸入需要搜尋的\(type)"
        mySearchBar.delegate = self
        mySearchBar._searchBarStyle(with: .minimal)
                
        mySearchBar.searchTextField.delegate = self
        mySearchBar.searchTextField.leftView = leftButton
        mySearchBar.searchTextField.backgroundColor = .black.withAlphaComponent(0.5)
        mySearchBar.searchTextField.textColor = .secondarySystemBackground
    }
    
    /// 產生MainTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: MainTableViewCell
    func searchTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> SearchVocabularyTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as SearchVocabularyTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 搜尋相似的單字
    /// - Parameter word: 以它為開頭的單字
    func searchWordList(like word: String?) {
        
        defer {
            
            let listCount = SearchVocabularyTableViewCell.vocabularyListArray.count
            isNeededUpdate = (listCount < Constant.searchCount) ? false : true
            
            refreshControl.endRefreshing()
            myTableView.reloadData()
        }
        
        guard let word = word?._removeWhiteSpacesAndNewlines(),
              !word.isEmpty
        else {
            SearchVocabularyTableViewCell.vocabularyListArray = []; return
        }
        
        SearchVocabularyTableViewCell.vocabularyListArray = []
        SearchVocabularyTableViewCell.vocabularyListArray = Utility.shared.vocabularyListArrayMaker(like: word, searchType: currentSearchType, for: Constant.currentTableName, offset: 0)
    }
    
    /// 增加相似的單字
    /// - Parameter word: 以它為開頭的單字
    func appendSearchWordList(like word: String?) {
        
        defer { refreshControl.endRefreshing() }
        
        guard let word = word,
              !word.isEmpty
        else {
            return
        }
        
        let oldListCount = SearchVocabularyTableViewCell.vocabularyListArray.count
        SearchVocabularyTableViewCell.vocabularyListArray += Utility.shared.vocabularyListArrayMaker(like: word, searchType: currentSearchType, for: Constant.currentTableName, offset: oldListCount)
        
        let newListCount = SearchVocabularyTableViewCell.vocabularyListArray.count
        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success); return }
        isNeededUpdate = false
    }
}

// MARK: - 下滑更新
private extension SearchVocabularyViewController {
    
    /// 下滑到底更新的動作設定
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - criticalValue: 要更新的臨界值 => 120%才更新
    ///   - isNeededUpdate: Bool
    func updateHeightPercentAction(with scrollView: UIScrollView, criticalValue: CGFloat = 1.2, isNeededUpdate: Bool) {
        
        var percent = Utility.shared.updateSearchHeightPercent(with: scrollView)
        
        if isNeededUpdate && (percent > criticalValue) {
            percent = 0.0
            Utility.shared.impactEffect()
            appendSearchWordList(like: mySearchBar.searchTextField.text)
        }

        updateActivityViewIndicatorSetting(with: percent, isNeededUpdate: isNeededUpdate)
    }
    
    /// 下滑到底更新的轉圈圈設定 => 根據百分比
    /// - Parameters:
    ///   - percent: CGFloat
    ///   - isNeededUpdate: Bool
    func updateActivityViewIndicatorSetting(with percent: CGFloat, isNeededUpdate: Bool) {
        
        activityViewIndicator.alpha = percent
        indicatorLabel.alpha = percent
        indicatorLabel.text = Utility.shared.updateActivityViewIndicatorTitle(with: percent, isNeededUpdate: isNeededUpdate)
    }
}

