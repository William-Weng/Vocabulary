//
//  ReviewResultViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/7.
//

import UIKit
import WWPrint

// MARK: - 複習單字的結果
final class ReviewResultViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var searchBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var activityViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!

    private let reviewDetailSegue = "ReviewDetailSegue"
    private let titleString = "複習總覽"

    private var isAnimationStop = false
    private var isFavorite = false
    private var isNeededUpdate = true
    
    private var reviewResultType: Constant.ReviewResultType = .alphabet
    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initMenu()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier,
              identifier == reviewDetailSegue
        else {
            return
        }
        
        vocabularyListPageSetting(for: segue, sender: sender)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?._tabBarHidden(true, animated: true)
        animatedBackground(with: .review)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }

    @objc func refreshReviewResultList(_ sender: UIRefreshControl) { relaodReviewResultList(with: reviewResultType, isFavorite: isFavorite) }
    @objc func reviewCount(_ sender: UITapGestureRecognizer) { reviewCountAction(isFavorite: isFavorite) }
    
    @IBAction func filterFavorite(_ sender: UIBarButtonItem) { filterFavoriteAction(with: sender) }
    
    deinit {
        ReviewResultTableViewCell.reviewResultListArray = []
        NotificationCenter.default._remove(observer: self, name: .viewDidTransition)
        wwPrint("\(Self.self) deinit", isShow: Constant.isPrint)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ReviewResultViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return ReviewResultTableViewCell.reviewResultListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return reviewResultTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { performSegue(withIdentifier: reviewDetailSegue, sender: indexPath) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { updateHeightPercentAction(with: scrollView, isNeededUpdate: isNeededUpdate) }
}

// MARK: - ReviewResultViewController
private extension ReviewResultViewController {

    /// UITableView的初始化設定
    func initSetting() {
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        refreshControl = UIRefreshControl._build(title: Constant.reload, target: self, action: #selector(Self.refreshReviewResultList(_:)))
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        
        viewDidTransitionAction()
        
        relaodReviewResultList(with: reviewResultType, isFavorite: isFavorite)
    }
    
    /// 重新讀取複習過的單字列表
    /// - Parameters:
    ///   - type: 搜尋排列的類型
    ///   - isFavorite: Bool
    func relaodReviewResultList(with type: Constant.ReviewResultType, isFavorite: Bool) {
        
        defer { refreshControl.endRefreshing() }
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        ReviewResultTableViewCell.reviewResultListArray = []
        ReviewResultTableViewCell.reviewResultListArray = API.shared.searchReviewList(for: info, type: type, isFavorite: isFavorite, offset: ReviewResultTableViewCell.reviewResultListArray.count)
        
        let listCount = ReviewResultTableViewCell.reviewResultListArray.count
        titleSetting(titleString, count: listCount)
        
        isNeededUpdate = (listCount < Constant.searchCount) ? false : true
        
        myTableView._reloadData() { [weak self] in
            
            guard let this = self,
                  !ReviewResultTableViewCell.reviewResultListArray.isEmpty
            else {
                return
            }
            
            this.myTableView._scrollToRow(with: IndexPath(row: 0, section: 0), at: .top) { Utility.shared.flashHUD(with: .success) }
        }
    }

    /// 顯示複習總覽總數量
    func reviewCountAction(isFavorite: Bool) {
        
        let version = Bundle.main._appVersion()
        let message = "v\(version.app) - \(version.build)"
        let title = "單字數量 - \(reviewCount(isFavorite: isFavorite))"
        
        informationHint(with: title, message: message)
    }
    
    /// 動畫背景設定
    /// - Parameter type: Utility.HudGifType
    func animatedBackground(with type: Constant.HudGifType) {
        
        guard let gifUrl = type.fileURL() else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
                        
            switch result {
            case .failure(let error): wwPrint(error, isShow: Constant.isPrint)
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
    
    /// 產生ReviewResultTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: ReviewResultTableViewCell
    func reviewResultTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> ReviewResultTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as ReviewResultTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 下滑到底更新資料
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - height: CGFloat
    func updateReviewResultList(for scrollView: UIScrollView, height: CGFloat, type: Constant.ReviewResultType) {
        
        let contentOffsetY = scrollView.contentOffset.y
        let offset = scrollView.frame.height + contentOffsetY - height
        let contentHeight = scrollView.contentSize.height
        
        if (contentOffsetY < 0) { return }
        if (offset > contentHeight) { appendReviewResultList(with: type) }
    }
    
    /// 畫面旋轉的動作
    func viewDidTransitionAction() {
        NotificationCenter.default._register(name: .viewDidTransition) { _ in Utility.shared.updateScrolledHeightSetting() }
    }
    
    /// 新複習過的單字列表
    func appendReviewResultList(with type: Constant.ReviewResultType) {
        
        defer { refreshControl.endRefreshing() }
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        let oldListCount = ReviewResultTableViewCell.reviewResultListArray.count
        ReviewResultTableViewCell.reviewResultListArray += API.shared.searchReviewList(for: info, type: type, isFavorite: isFavorite, offset: oldListCount)

        let newListCount = ReviewResultTableViewCell.reviewResultListArray.count
        titleSetting(titleString, count: newListCount)
        
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
              let reviewResultList = ReviewResultTableViewCell.reviewResultList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let vocabularyList = API.shared.searchVocabularyList(in: [reviewResultList.word], info: info, offset: 0).first?._jsonClass(for: VocabularyList.self)
        else {
            return
        }
        
        viewController.canDelete = false
        viewController.vocabularyList = vocabularyList
        viewController.vocabularyListIndexPath = indexPath
        viewController.mainViewDelegate = nil
    }
    
    /// 取得複習總覽總數量
    /// - Parameter isFavorite: Bool
    /// - Returns: Int
    func reviewCount(isFavorite: Bool) -> Int {
        
        let key = "word"
        let field = "\(key)Count"
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let result = API.shared.searchReviewCount(for: info, key: key, isFavorite: isFavorite).first,
              let value = result["\(field)"],
              let count = Int("\(value)", radix: 10)
        else {
            return 0
        }
                
        return count
    }
    
    /// 設定標題
    /// - Parameter count: Int
    func titleSetting(_ title: String, count: Int) {

        guard let titleView = navigationItem.titleView as? UILabel else { titleViewSetting(with: title, count: count); return }
        Utility.shared.titleViewSetting(with: titleView, title: title, count: count)
    }
    
    /// 標題文字相關設定
    /// - Parameter word: String
    func titleViewSetting(with title: String, count: Int) {

        let titleView = Utility.shared.titleLabelMaker(with: title)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(Self.reviewCount(_:)))
        
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(gesture)
        Utility.shared.titleViewSetting(with: titleView, title: title, count: count)
        
        navigationItem.titleView = titleView
    }
    
    /// 顯示版本 / 複習總覽數量訊息
    func informationHint(with title: String?, message: String?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "確認", style: .default) { _ in }
        
        alertController.addAction(actionOK)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 過濾是否為Favorite的單字
    /// - Parameter sender: UIBarButtonItem
    func filterFavoriteAction(with sender: UIBarButtonItem) {
        
        isFavorite.toggle()
        
        sender.image = Utility.shared.favoriteIcon(isFavorite)
        relaodReviewResultList(with: reviewResultType, isFavorite: isFavorite)
    }
}

// MARK: - UIMenu
private extension ReviewResultViewController {
    
    /// [初始化功能選單](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/ios-的選單-menu-按鈕-pull-down-button-pop-up-button-2ddab2181ee5)
    /// => [UIMenu - iOS 14](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/在-iphone-ipad-上顯示-popover-彈出視窗-ac196732e557)
    func initMenu() {
        initSearchItemMenu()
    }
    
    /// 初始化搜尋排序選單 (UIMenu)
    /// - Parameter sender: UIBarButtonItem
    func initSearchItemMenu() {
        
        let actions = Constant.ReviewResultType.allCases.map({ searchItemMenuActionMaker(type: $0) })
        let menu = UIMenu(title: "請選擇排列方法", children: actions)
        
        searchBarButtonItem.menu = menu
    }
    
    /// 產生搜尋排序選單
    /// - Parameter filename: String
    /// - Returns: UIAction
    func searchItemMenuActionMaker(type: Constant.ReviewResultType) -> UIAction {
        
        let action = UIAction(title: "\(type.value())") { [weak self] _ in
            
            guard let this = self else { return }
            
            this.reviewResultType = type
            this.relaodReviewResultList(with: type, isFavorite: this.isFavorite)
        }
        
        return action
    }
}

// MARK: - 下滑更新
private extension ReviewResultViewController {
    
    /// 下滑到底更新的動作設定
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - criticalValue: 要更新的臨界值 => 120%才更新
    func updateHeightPercentAction(with scrollView: UIScrollView, criticalValue: CGFloat = 1.2, isNeededUpdate: Bool) {
        
        var percent = Utility.shared.updateHeightPercent(with: scrollView, navigationController: navigationController)
        
        if isNeededUpdate && (percent > criticalValue) {
            percent = 0.0
            Utility.shared.impactEffect()
            appendReviewResultList(with: reviewResultType)
        }
        
        updateActivityViewIndicatorSetting(with: percent, isNeededUpdate: isNeededUpdate)
    }
    
    ///  下滑到底更新的轉圈圈設定 => 根據百分比
    /// - Parameter percent: CGFloat
    func updateActivityViewIndicatorSetting(with percent: CGFloat, isNeededUpdate: Bool) {
        
        let alpha = (percent < 0) ? 0.0 : percent
        
        activityViewIndicator.alpha = alpha
        indicatorLabel.alpha = alpha
        indicatorLabel.text = Utility.shared.updateActivityViewIndicatorTitle(with: percent, isNeededUpdate: isNeededUpdate)
    }
}
