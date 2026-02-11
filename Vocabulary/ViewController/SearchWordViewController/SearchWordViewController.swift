//
//  SearchWordViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/30.
//

import UIKit

// MARK: - 單字搜尋頁面
final class SearchWordViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var activityViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    var searchText: String?
    
    private let searchListTableViewSegue = "SearchListTableViewSegue"

    private var isAnimationStop = false
    private var isNeededUpdate = false
    private var disappearImage: UIImage?
    private var titleSearchBar = UISearchBar()
    private var refreshControl: UIRefreshControl!
    private var currentSearchType: Constant.SearchType = .word { didSet { Utility.shared.switchSearchTypeAction(titleSearchBar, for: currentSearchType) }}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSearchBar(with: currentSearchType, text: searchText)
        initSetting()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        vocabularyListPageSetting(for: segue, sender: sender)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?._tabBarHidden(true)
        animatedBackground(with: .search)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        tabBarController?._tabBarHidden(false)
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
        
        SearchWordTableViewCell.searchType = currentSearchType
        titleSearchBar.placeholder = "請輸入需要搜尋的\(currentSearchType)"
        sender.setTitle("  \(currentSearchType)  ", for: .normal)
        
        refreshSearchWord(refreshControl)
    }
    
    deinit {
        SearchWordTableViewCell.vocabularyListArray = []
        NotificationCenter.default._remove(observer: self, name: .viewDidTransition)
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SearchWordViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return SearchWordTableViewCell.vocabularyListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return searchTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { performSegue(withIdentifier: searchListTableViewSegue, sender: indexPath) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { titleSearchBar.searchTextField._dismissKeyboard(); updateHeightPercentAction(with: scrollView, isNeededUpdate: isNeededUpdate) }
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField._dismissKeyboard(); return true }
}

// MARK: - MainViewDelegate
extension SearchWordViewController: MainViewDelegate {
    
    func deleteRow(with indexPath: IndexPath) { deleteRowAction(with: indexPath) }
    func updateCountLabel(with indexPath: IndexPath, count: Int) {}
    func tabBarHidden(_ isHidden: Bool) {}
    func navigationBarHidden(_ isHidden: Bool) {}
}

// MARK: - 小工具
private extension SearchWordViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        SearchWordTableViewCell.searchType = currentSearchType
        SearchWordTableViewCell.vocabularyListArray = []
        
        refreshControl = UIRefreshControl._build(title: Constant.reload, target: self, action: #selector(Self.refreshSearchWord(_:)))
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        
        viewDidTransitionAction()
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
    }
    
    /// [初始化搜尋列](https://jjeremy-xue.medium.com/swift-客製化-navigation-bar-customized-navigation-bar-8e4eaf188d7c)
    /// - Parameter type: [Constant.SearchType](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/uitextfield-的-leftview-rightview-以放大鏡-密碼顯示開關為例-7813fa9fd4f1)
    func initSearchBar(with type: Constant.SearchType, text: String?) {
        
        let leftButton = Utility.shared.searchTypeButtonMaker(with: type, backgroundColor: .systemRed)
        leftButton.addTarget(self, action: #selector(Self.switchSearchType(_:)), for: .touchUpInside)
        
        titleSearchBar.placeholder = "請輸入需要搜尋的\(type)"
        titleSearchBar.delegate = self
        titleSearchBar.searchTextField.text = text
        titleSearchBar.searchTextField.delegate = self
        titleSearchBar.searchTextField.leftView = leftButton
        
        if let text = text { searchBar(titleSearchBar, textDidChange: text) }
        
        navigationItem.titleView = titleSearchBar
    }
            
    /// 產生MainTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: MainTableViewCell
    func searchTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> SearchWordTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as SearchWordTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 刪除該列資料
    /// - Parameter indexPath: IndexPath
    func deleteRowAction(with indexPath: IndexPath) {
        SearchWordTableViewCell.vocabularyListArray.remove(at: indexPath.row)
        myTableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    /// 動畫背景設定
    /// - Parameter type: Constant.AnimationGifType
    func animatedBackground(with type: Constant.AnimationGifType) {
        
        guard let gifUrl = type.fileURL(with: .background) else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): myPrint(error)
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
            
            let listCount = SearchWordTableViewCell.vocabularyListArray.count
            isNeededUpdate = (listCount < Constant.searchCount) ? false : true
            
            refreshControl.endRefreshing()
            myTableView.reloadData()
        }
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let word = word?._removeWhiteSpacesAndNewlines(),
              !word.isEmpty
        else {
            SearchWordTableViewCell.vocabularyListArray = []; return
        }
        
        SearchWordTableViewCell.vocabularyListArray = []
        SearchWordTableViewCell.vocabularyListArray = Utility.shared.vocabularyListArrayMaker(like: word, searchType: currentSearchType, info: info, offset: 0)
    }
    
    /// 增加相似的單字
    /// - Parameter word: 以它為開頭的單字
    func appendSearchWordList(like word: String?) {
        
        defer { refreshControl.endRefreshing() }
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let word = word,
              !word.isEmpty
        else {
            return
        }
        
        let oldListCount = SearchWordTableViewCell.vocabularyListArray.count
        SearchWordTableViewCell.vocabularyListArray += Utility.shared.vocabularyListArrayMaker(like: word, searchType: currentSearchType, info: info, offset: oldListCount)
        
        let newListCount = SearchWordTableViewCell.vocabularyListArray.count
        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success); return }
        isNeededUpdate = false
    }
    
    /// 設定單字列表頁的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func vocabularyListPageSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? ListViewController,
              let indexPath = sender as? IndexPath,
              let vocabularyList = SearchWordTableViewCell.vocabularyListArray[safe: indexPath.row]?._jsonClass(for: VocabularyList.self)
        else {
            return
        }
        
        viewController.vocabularyList = vocabularyList
        viewController.vocabularyListIndexPath = indexPath
        viewController.mainViewDelegate = self
    }
    
    /// 畫面旋轉的動作
    func viewDidTransitionAction() {
        NotificationCenter.default._register(name: .viewDidTransition) { _ in Utility.shared.updateScrolledHeightSetting() }
    }
}

// MARK: - 下滑更新
private extension SearchWordViewController {
    
    /// 下滑到底更新的動作設定
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - criticalValue: 要更新的臨界值 => 120%才更新
    ///   - isNeededUpdate: Bool
    func updateHeightPercentAction(with scrollView: UIScrollView, criticalValue: CGFloat = 1.2, isNeededUpdate: Bool) {
        
        var percent = Utility.shared.updateHeightPercent(with: scrollView, navigationController: navigationController)
        
        if isNeededUpdate && (percent > criticalValue) {
            percent = 0.0
            Utility.shared.impactEffect()
            appendSearchWordList(like: titleSearchBar.searchTextField.text)
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
