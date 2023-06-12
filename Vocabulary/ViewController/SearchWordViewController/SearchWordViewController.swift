//
//  SearchWordViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/30.
//

import UIKit
import WWPrint

// MARK: - 單字搜尋頁面
final class SearchWordViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    
    private let searchListTableViewSegue = "SearchListTableViewSegue"
    
    private var word: String = ""
    private var isAnimationStop = false
    private var disappearImage: UIImage?
    private var titleSearchBar = UISearchBar()
    private var refreshControl: UIRefreshControl!
    private var currentSearchType: Constant.SearchType = .word { didSet { switchSearchTypeAction(for: currentSearchType) }}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSearchBar(with: currentSearchType)
        initSetting()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        vocabularyListPageSetting(for: segue, sender: sender)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?._tabBarHidden(true, animated: true)
        animatedBackground(with: .search)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        tabBarController?._tabBarHidden(false, animated: true)
        pauseBackgroundAnimation()
    }
    
    /// 重新讀取資料
    /// - Parameter word: String
    @objc func reloadSearchWord(_ word: String?) {
        searchWordList(like: word)
    }
    
    /// 重新讀取資料
    /// - Parameter refreshControl: UIRefreshControl
    @objc func refreshSearchWord(_ refreshControl: UIRefreshControl) {
        let word = titleSearchBar.searchTextField.text
        searchWordList(like: word)
    }
    
    /// 切換要搜尋的類型分類
    /// - Parameter sender: UIButton
    @objc func switchSearchType(_ sender: UIButton) {
        
        let rawValue = currentSearchType.rawValue + 1
        
        currentSearchType = Constant.SearchType(rawValue: rawValue) ?? .word
        
        SearchTableViewCell.searchType = currentSearchType
        titleSearchBar.placeholder = "請輸入需要搜尋的\(currentSearchType)"
        sender.setTitle("  \(currentSearchType)  ", for: .normal)
        
        refreshSearchWord(refreshControl)
    }
    
    deinit {
        SearchTableViewCell.vocabularyListArray = []
        wwPrint("\(Self.self) deinit")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SearchWordViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return SearchTableViewCell.vocabularyListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return searchTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { performSegue(withIdentifier: searchListTableViewSegue, sender: indexPath) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { dismissKeyboard(with: titleSearchBar.searchTextField) }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { updateSearchData(for: scrollView, height: Constant.updateScrolledHeight) }
}

// MARK: - UISearchBarDelegate
extension SearchWordViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let selector = #selector(Self.reloadSearchWord(_:))
        selector._debounce(target: self, delayTime: Constant.searchDelayTime, object: searchText)
    }
}

// MARK: - UITextFieldDelegate
extension SearchWordViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard(with: textField)
        return true
    }
}

// MARK: - MainViewDelegate
extension SearchWordViewController: MainViewDelegate {
    
    func deleteRow(with indexPath: IndexPath) { deleteRowAction(with: indexPath) }
    func levelMenu(with indexPath: IndexPath) {}
    func updateLevel(_ level: Vocabulary.Level, with indexPath: IndexPath) {}
    func updateCountLabel(with indexPath: IndexPath, count: Int) {}
    func tabBarHidden(_ isHidden: Bool) {}
    func navigationBarHidden(_ isHidden: Bool) {}
}

// MARK: - 小工具
private extension SearchWordViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        SearchTableViewCell.searchType = currentSearchType
        SearchTableViewCell.vocabularyListArray = []
        
        refreshControl = UIRefreshControl._build(title: "重新讀取", target: self, action: #selector(Self.refreshSearchWord(_:)))
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
    }
    
    /// [初始化搜尋列](https://jjeremy-xue.medium.com/swift-客製化-navigation-bar-customized-navigation-bar-8e4eaf188d7c)
    /// - Parameter type: [Constant.SearchType](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/uitextfield-的-leftview-rightview-以放大鏡-密碼顯示開關為例-7813fa9fd4f1)
    func initSearchBar(with type: Constant.SearchType) {
        
        titleSearchBar.placeholder = "請輸入需要搜尋的\(type)"
        titleSearchBar.delegate = self
        titleSearchBar.searchTextField.delegate = self
        titleSearchBar.searchTextField.leftView = searchTypeButtonMaker(with: type, backgroundColor: .systemRed)
        
        navigationItem.titleView = titleSearchBar
    }
    
    /// 設定搜尋的類型按鈕 => 單字 / 字義
    /// - Parameters:
    ///   - title: String
    ///   - backgroundColor: UIColor
    /// - Returns: UIButton
    func searchTypeButtonMaker(with type: Constant.SearchType, backgroundColor: UIColor) -> UIButton {
        
        let button = UIButton()
        
        button.backgroundColor = type.backgroundColor()
        button.setTitle("  \(type)  ", for: .normal)
        button.layer._maskedCorners(radius: 8.0)
        button.addTarget(self, action: #selector(Self.switchSearchType(_:)), for: .touchUpInside)
        
        return button
    }
        
    /// 產生MainTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: MainTableViewCell
    func searchTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> SearchTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as SearchTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 下滑到底更新資料
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - height: CGFloat
    func updateSearchData(for scrollView: UIScrollView, height: CGFloat) {
        
        let contentOffsetY = scrollView.contentOffset.y
        let offset = scrollView.frame.height + contentOffsetY - height
        let contentHeight = scrollView.contentSize.height
        
        if (contentOffsetY < 0) { return }
        if (offset > contentHeight) { appendSearchWordList(like: titleSearchBar.searchTextField.text) }
    }
    
    /// 刪除該列資料
    /// - Parameter indexPath: IndexPath
    func deleteRowAction(with indexPath: IndexPath) {
        SearchTableViewCell.vocabularyListArray.remove(at: indexPath.row)
        myTableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    /// 動畫背景設定
    /// - Parameter type: Utility.HudGifType
    func animatedBackground(with type: Utility.HudGifType) {
        
        guard let gifUrl = type.fileURL() else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
                        
            switch result {
            case .failure(let error): wwPrint(error)
            case .success(let info):
                info.pointer.pointee = this.isAnimationStop
                if (this.isAnimationStop) { this.myImageView.image = this.disappearImage }
            }
        }
    }
    
    /// 暫停背景動畫
    func pauseBackgroundAnimation() {
        disappearImage = myImageView.image
        isAnimationStop = true
    }
    
    /// 搜尋相似的單字
    /// - Parameter word: 以它為開頭的單字
    func searchWordList(like word: String?) {
        
        defer {
            refreshControl.endRefreshing()
            myTableView.reloadData()
        }
        
        SearchTableViewCell.vocabularyListArray = []
        
        guard let word = word?._removeWhiteSpacesAndNewlines(),
              !word.isEmpty
        else {
            return
        }
        
        SearchTableViewCell.vocabularyListArray = vocabularyListArrayMaker(like: word, searchType: currentSearchType, for: Constant.currentTableName, offset: 0)
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
        
        let oldListCount = SearchTableViewCell.vocabularyListArray.count
        SearchTableViewCell.vocabularyListArray += vocabularyListArrayMaker(like: word, searchType: currentSearchType, for: Constant.currentTableName, offset: oldListCount)
        
        let newListCount = SearchTableViewCell.vocabularyListArray.count
        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success) }
    }
    
    /// 設定單字列表頁的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func vocabularyListPageSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? ListViewController,
              let indexPath = sender as? IndexPath,
              let vocabularyList = SearchTableViewCell.vocabularyListArray[safe: indexPath.row]?._jsonClass(for: VocabularyList.self)
        else {
            return
        }
        
        viewController.vocabularyList = vocabularyList
        viewController.vocabularyListIndexPath = indexPath
        viewController.mainViewDelegate = self
    }
    
    /// [退鍵盤](https://medium.com/彼得潘的-swift-ios-app-開發教室/uitextfield如何讓鍵盤消失-)
    /// - Parameter textField: UITextField
    func dismissKeyboard(with textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    /// 切換搜尋類型的相關動作
    /// - Parameter searchType: SearchType
    func switchSearchTypeAction(for searchType: Constant.SearchType) {
        
        guard let leftButton = titleSearchBar.searchTextField.leftView as? UIButton else { return }
        
        leftButton.setTitle("  \(searchType)  ", for: .normal)
        leftButton.backgroundColor = searchType.backgroundColor()
        titleSearchBar.placeholder = "請輸入需要搜尋的\(searchType)"
    }
    
    /// 取得單字列表 for 分類
    /// - Parameters:
    ///   - text: String
    ///   - searchType: Constant.SearchType
    ///   - tableName: Constant.VoiceCode
    ///   - offset: Int
    /// - Returns: [[String : Any]]
    func vocabularyListArrayMaker(like text: String, searchType: Constant.SearchType, for tableName: Constant.VoiceCode, offset: Int) -> [[String : Any]] {
        
        let dictionary: [[String : Any]]
        
        switch searchType {
        case .word:
            dictionary = API.shared.searchList(like: text, searchType: currentSearchType, for: Constant.currentTableName, offset: offset)
            
        case .interpret:
            
            let array = API.shared.searchList(like: text, searchType: currentSearchType, for: Constant.currentTableName, count: nil, offset: 0)
            let words = array.compactMap { $0._jsonClass(for: Vocabulary.self)?.word }
            
            dictionary = API.shared.searchWordListDetail(in: words, for: Constant.currentTableName, offset: offset)
        }
        
        return dictionary
    }
}
