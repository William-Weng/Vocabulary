//
//  OthersViewController.swift
//  Vocabulary
//
//  Created by William.Weng 2023/2/10.
//

import UIKit
import WWPrint

final class OthersViewController: UIViewController {

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var fakeTabBarHeightConstraint: NSLayoutConstraint!
    
    private var isLoaded = false
    private var isAnimationStop = false
    private var currentScrollDirection: Constant.ScrollDirection = .down
    
    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatedBackground(with: .others)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }
    
    @objc func refreshBookmarks(_ sender: UIRefreshControl) { reloadBookmarks() }
    
    @IBAction func appendBookmarkAction(_ sender: UIButton) {
        
        appendBookmarkHint(title: "請輸入例句") { [weak self] (title, webUrl) in
            guard let this = self else { return false }
            return this.appendBookmark(title, webUrl: webUrl, for: Constant.currentTableName)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension OthersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return OthersTableViewCell.bookmarksArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return othersTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { tabrBarHidden(with: scrollView) }
}

// MARK: - 小工具
private extension OthersViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        isLoaded = true
        navigationItem.backBarButtonItem = UIBarButtonItem()
        
        refreshControl = UIRefreshControl._build(target: self, action: #selector(Self.refreshBookmarks(_:)))
        fakeTabBarHeightConstraint.constant = self.tabBarController?.tabBar.frame.height ?? 0
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
        
        reloadBookmarks()
    }
    
    /// 設定標題
    /// - Parameter count: Int
    func titleSetting(with count: Int) {
        
        let label = UILabel()
        label.text = "常用書籤 - \(count)"
        
        navigationItem.titleView = label
    }
    
    /// 重新讀取書籤
    func reloadBookmarks() {
        
        defer { refreshControl.endRefreshing() }
        
        OthersTableViewCell.bookmarksArray = []
        OthersTableViewCell.bookmarksArray = API.shared.searchBookmarkList(for: Constant.currentTableName, offset: 0)
        
        titleSetting(with: OthersTableViewCell.bookmarksArray.count)
        
        myTableView._reloadData() { [weak self] in
            
            guard let this = self,
                  !SentenceTableViewCell.sentenceListArray.isEmpty
            else {
                return
            }
            
            let topIndexPath = IndexPath(row: 0, section: 0)
            this.myTableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
            
            Utility.shared.flashHUD(with: .success)
        }
    }
    
    /// 新增書籤
    /// - Parameters:
    ///   - example: 例句
    ///   - tableName: 翻譯
    /// - Returns: Bool
    func appendBookmark(_ title: String, webUrl: String, for tableName: Constant.VoiceCode) -> Bool {
        return API.shared.insertBookmarkToList(title, webUrl: webUrl, for: tableName)
    }
    
    /// 產生OthersTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: OthersTableViewCell
    func othersTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> OthersTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as OthersTableViewCell
        cell.configure(with: indexPath)
        
        return cell
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
    
    /// [滑動時TabBar是否隱藏的規則設定](https://www.jianshu.com/p/539b265bcb5d)
    /// - Parameter scrollView: UIScrollView
    func tabrBarHidden(with scrollView: UIScrollView) {
        
        let direction = scrollView._direction()
        
        var isHidden = false
        
        if (direction == currentScrollDirection) { return }
        
        switch direction {
        case .up: isHidden = false
        case .down: isHidden = true
        case .left , .right ,.none: break
        }
        
        tabBarHiddenAction(isHidden)
        currentScrollDirection = direction
    }
    
    /// 設定TabBar顯示與否功能
    /// - Parameters:
    ///   - isHidden: Bool
    func tabBarHiddenAction(_ isHidden: Bool) {
        
        guard let tabBarController = tabBarController else { return }
        
        let duration = Constant.duration
        
        tabBarController._tabBarHidden(isHidden, duration: duration)
        appendButtonPositionConstraint(isHidden, duration: duration)
    }
    
    /// 更新新增書籤Button的位置 for Tabbar
    /// - Parameters:
    ///   - isHidden: Bool
    ///   - animated: Bool
    ///   - duration: TimeInterval
    ///   - curve: UIView.AnimationCurve
    func appendButtonPositionConstraint(_ isHidden: Bool, animated: Bool = true, duration: TimeInterval, curve: UIView.AnimationCurve = .linear) {
        
        guard let tabBar = self.tabBarController?.tabBar else { return }
        
        fakeTabBarHeightConstraint.constant = !isHidden ? tabBar.frame.height : .zero
        UIViewPropertyAnimator(duration: duration, curve: curve) { [weak self] in
            
            guard let this = self else { return }
            this.view.layoutIfNeeded()
            
        }.startAnimation()
    }
    
    /// 新增書籤的提示框
    /// - Parameters:
    ///   - indexPath: 要更新書籤時，才會有IndexPath
    ///   - title: 標題
    ///   - message: 訊息文字
    ///   - defaultText: 預設文字
    ///   - action: (String) -> Bool
    func appendBookmarkHint(with indexPath: IndexPath? = nil, title: String, message: String? = nil, titleText: String? = nil, webUrlText: String? = nil, action: @escaping (String, String) -> Bool) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addTextField {
            $0.text = titleText
            $0.placeholder = "請輸入網頁標題…"
        }
        
        alertController.addTextField {
            $0.text = webUrlText
            $0.placeholder = "請輸入網頁網址…"
        }
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            
            guard let this = self,
                  let inputTitle = alertController.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let inputWebUrl = alertController.textFields?.last?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            else {
                return
            }
            
            if (!action(inputTitle, inputWebUrl)) { Utility.shared.flashHUD(with: .fail); return }
            
            Utility.shared.flashHUD(with: .success)
            
            if let indexPath = indexPath {
                this.updateCellLabel(with: indexPath, title: inputTitle, webUrl: inputWebUrl)
            } else {
                this.reloadBookmarks()
            }
        }
        
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 右側滑動按鈕
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIContextualAction]
    func trailingSwipeActionsMaker(with indexPath: IndexPath) -> [UIContextualAction] {
                
        let updateAction = UIContextualAction._build(with: "更新", color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)) { [weak self] in
            
            guard let this = self,
                  let bookmarkSite = OthersTableViewCell.bookmarkSite(with: indexPath)
            else {
                return
            }
            
            this.appendBookmarkHint(with: indexPath, title: "請輸入相關文字", titleText: bookmarkSite.title, webUrlText: bookmarkSite.url) { (title, webUrl) in
                return API.shared.updateBookmarkToList(bookmarkSite.id, title: title, webUrl: webUrl, for: Constant.currentTableName)
            }
        }
        
        let deleteAction = UIContextualAction._build(with: "刪除", color: #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)) { [weak self] in
            guard let this = self else { return }
            this.deleteBookmarkAction(with: indexPath)
        }
        
        return [updateAction, deleteAction]
    }
    
    /// 刪除書籤功能
    /// - Parameter indexPath: IndexPath
    func deleteBookmarkAction(with indexPath: IndexPath) {
        
        guard let bookmarkSite = OthersTableViewCell.bookmarkSite(with: indexPath) else { return }
        
        let isSuccess = API.shared.deleteBookmark(with: bookmarkSite.id, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        OthersTableViewCell.bookmarksArray.remove(at: indexPath.row)
        
        myTableView.deleteRows(at: [indexPath], with: .fade)
        titleSetting(with: OthersTableViewCell.bookmarksArray.count)
    }
    
    /// 更新Cell的Label文字
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - speech: 詞性
    ///   - info: 相關文字
    func updateCellLabel(with indexPath: IndexPath, title: String, webUrl: String) {
        
        guard var dictionary = OthersTableViewCell.bookmarksArray[safe: indexPath.row] else { return }
        
        dictionary["title"] = title
        dictionary["url"] = webUrl
        
        OthersTableViewCell.bookmarksArray[indexPath.row] = dictionary
        myTableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

