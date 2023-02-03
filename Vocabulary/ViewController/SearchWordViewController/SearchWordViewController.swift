//
//  SearchWordViewController.swift
//  Vocabulary
//
//  Created by iOS on 2023/1/30.
//

import UIKit
import WWPrint

// MARK: - 單字搜尋頁面
final class SearchWordViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    
    private var word: String = ""
    private var isAnimationStop = false
    private var disappearImage: UIImage?
    private var titleSearchBar = UISearchBar()
    private var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSearchBar()
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
        self.reloadSearchWord(word)
        Utility.shared.flashHUD(with: .success)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SearchWordViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return SearchTableViewCell.vocabularyListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return searchTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { performSegue(withIdentifier: "SearchListTableViewSegue", sender: indexPath) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { dismissKeyboard(with: titleSearchBar.searchTextField) }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { updateSearchData(for: scrollView) }
}

// MARK: - UISearchBarDelegate
extension SearchWordViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let selector = #selector(Self.reloadSearchWord(_:))
        selector._debounce(target: self, delayTime: 1.0, object: searchText)
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
    
    /// 刪除該列資料
    /// - Parameter indexPath: IndexPath
    func deleteRow(with indexPath: IndexPath) {
        SearchTableViewCell.vocabularyListArray.remove(at: indexPath.row)
        myTableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    func levelMenu(with indexPath: IndexPath) {}
    func updateCountLabel(with indexPath: IndexPath, count: Int) {}
}

// MARK: - 小工具
private extension SearchWordViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        SearchTableViewCell.vocabularyListArray = []
        
        refreshControl = UIRefreshControl._build(target: self, action: #selector(Self.refreshSearchWord(_:)))
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
    }
    
    /// [初始化搜尋列](https://jjeremy-xue.medium.com/swift-客製化-navigation-bar-customized-navigation-bar-8e4eaf188d7c)
    func initSearchBar() {
        navigationItem.titleView = titleSearchBar
        titleSearchBar.placeholder = "請輸入要需搜尋的單字"
        titleSearchBar.delegate = self
        titleSearchBar.searchTextField.delegate = self
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
    func updateSearchData(for scrollView: UIScrollView, height: CGFloat = 128.0) {
        
        let offset = scrollView.frame.height + scrollView.contentOffset.y - height
        let height = scrollView.contentSize.height
        
        if (offset > height) { appendSearchWordList(like: titleSearchBar.searchTextField.text) }
    }
    
    /// 動畫背景設定
    /// - Parameter type: Utility.HudGifType
    func animatedBackground(with type: Utility.HudGifType) {
        
        guard let gifUrl = Bundle.main.url(forResource: type.rawValue, withExtension: nil) else { return }
        
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
        
        guard let word = word,
              !word.isEmpty
        else {
            return
        }
        
        SearchTableViewCell.vocabularyListArray = API.shared.searchWordList(like: word, for: Constant.currentTableName, offset: 0)
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
        SearchTableViewCell.vocabularyListArray += API.shared.searchWordList(like: word, for: Constant.currentTableName, offset: oldListCount)

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
    func dismissKeyboard(with textField: UITextField) {
        textField.resignFirstResponder()
    }
}
