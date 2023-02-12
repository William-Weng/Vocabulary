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
    
    private let reviewDetailSegue = "ReviewDetailSegue"
    
    private var isAnimationStop = false
    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
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
    
    @objc func refreshReviewResultList(_ sender: UIRefreshControl) { relaodReviewResultList() }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ReviewResultViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return ReviewResultTableViewCell.reviewResultListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return reviewResultTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { performSegue(withIdentifier: reviewDetailSegue, sender: indexPath) }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { updateReviewResultList(for: scrollView, height: Constant.updateScrolledHeight) }
}

// MARK: - ReviewResultViewController
private extension ReviewResultViewController {

    /// UITableView的初始化設定
    func initSetting() {
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        refreshControl = UIRefreshControl._build(target: self, action: #selector(Self.refreshReviewResultList(_:)))
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
        
        relaodReviewResultList()
    }
    
    /// 重新讀取複習過的單字列表
    func relaodReviewResultList() {
        
        defer { refreshControl.endRefreshing() }
        
        ReviewResultTableViewCell.reviewResultListArray = []
        ReviewResultTableViewCell.reviewResultListArray = API.shared.searchReviewList(for: Constant.currentTableName, offset: ReviewResultTableViewCell.reviewResultListArray.count)
        
        titleSetting(with: ReviewResultTableViewCell.reviewResultListArray.count)
        
        myTableView._reloadData() { [weak self] in
            
            guard let this = self,
                  !ReviewResultTableViewCell.reviewResultListArray.isEmpty
            else {
                return
            }
            
            let topIndexPath = IndexPath(row: 0, section: 0)
            this.myTableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
            
            Utility.shared.flashHUD(with: .success)
        }
    }
    
    /// 設定標題
    /// - Parameter count: Int
    func titleSetting(with count: Int) {
        
        let label = UILabel()
        label.text = "複習總覽 - \(count)"
        
        navigationItem.titleView = label
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
    func updateReviewResultList(for scrollView: UIScrollView, height: CGFloat) {
        
        let contentOffsetY = scrollView.contentOffset.y
        let offset = scrollView.frame.height + contentOffsetY - height
        let contentHeight = scrollView.contentSize.height
        
        if (contentOffsetY < 0) { return }
        if (offset > contentHeight) { appendReviewResultList() }
    }
    
    /// 新複習過的單字列表
    func appendReviewResultList() {
        
        defer { refreshControl.endRefreshing() }
        
        let oldListCount = ReviewResultTableViewCell.reviewResultListArray.count
        ReviewResultTableViewCell.reviewResultListArray += API.shared.searchReviewList(for: Constant.currentTableName, offset: oldListCount)

        let newListCount = ReviewResultTableViewCell.reviewResultListArray.count
        titleSetting(with: newListCount)
        
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
              let reviewResultList = ReviewResultTableViewCell.reviewResultList(with: indexPath),
              let vocabularyList = API.shared.searchVocabularyList(in: [reviewResultList.word], for: Constant.currentTableName, offset: 0).first?._jsonClass(for: VocabularyList.self)
        else {
            return
        }
        
        viewController.canDelete = false
        viewController.vocabularyList = vocabularyList
        viewController.vocabularyListIndexPath = indexPath
        viewController.mainViewDelegate = nil
    }
}

