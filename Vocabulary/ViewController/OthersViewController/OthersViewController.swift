//
//  OthersViewController.swift
//  Vocabulary
//
//  Created by William.Weng 2023/2/10.
//

import UIKit
import SafariServices
import WWNetworking
import UniformTypeIdentifiers

// MARK: - OthersViewDelegate
protocol OthersViewDelegate {
    func loadImage(with indexPath: IndexPath, filename: String)
    func tabBarHidden(_ isHidden: Bool)
}

// MARK: - 其它設定
final class OthersViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var fakeTabBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var appendBookmarkButton: UIButton!
    @IBOutlet weak var activityViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!

    private let licenseWebViewSegue = "LicenseWebViewSegue"
    private let titleString = "常用書籤"

    private var isAnimationStop = false
    private var isFixed = false
    private var isFavorite = false
    private var isNeededUpdate = true
    
    private var currentScrollDirection: Constant.ScrollDirection = .down
    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        viewDidTransitionAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatedBackground(with: .others)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!isFixed) { fixTableViewInsetForSafeArea(for: IndexPath(row: 0, section: 0)); isFixed = true }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }
    
    @objc func refreshBookmarks(_ sender: UIRefreshControl) { reloadBookmarks(isFavorite: isFavorite) }
    @objc func bookmarkCount(_ sender: UITapGestureRecognizer) { bookmarkCountAction() }

    @IBAction func shareDatabase(_ sender: UIBarButtonItem) { shareDatabaseAction(sender) }
    @IBAction func downloadDatabase(_ sender: UIBarButtonItem) { downloadDatabaseAction(sender) }
    @IBAction func filterFavorite(_ sender: UIBarButtonItem) { filterFavoriteAction(with: sender) }
    @IBAction func appendBookmarkAction(_ sender: UIButton) {
        
        appendBookmarkHint(title: "請輸入網址") { [weak self] (title, webUrl) in
            
            guard let this = self,
                  let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
            else {
                return false
            }
            
            return this.appendBookmark(title, webUrl: webUrl, info: info)
        }
    }
    
    deinit {
        OthersTableViewCell.bookmarksArray = []
        OthersTableViewCell.othersViewDelegate = nil
        NotificationCenter.default._remove(observer: self, name: .viewDidTransition)
        myPrint("\(Self.self) init")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension OthersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return OthersTableViewCell.bookmarksArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return othersTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { openBookmark(with: indexPath) }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { tabrBarHidden(with: scrollView); updateHeightPercentAction(with: scrollView, isNeededUpdate: isNeededUpdate) }
}

// MARK: - SFSafariViewControllerDelegate
extension OthersViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
        let isHidden = false
        
        tabBarHiddenAction(isHidden)
        navigationBarHiddenAction(isHidden)
    }
}

// MARK: - UIDocumentPickerDelegate
extension OthersViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        downloadDocumentAction(controller, didPickDocumentsAt: urls)
    }
}

// MARK: - MyNavigationControllerDelegate
extension OthersViewController: MyNavigationControllerDelegate {
    func refreshRootViewController() { reloadBookmarks(isFavorite: isFavorite) }
}

// MARK: - OthersViewDelegate
extension OthersViewController: OthersViewDelegate {
    
    func loadImage(with indexPath: IndexPath, filename: String) { loadImageAction(with: indexPath, filename: filename) }
    func tabBarHidden(_ isHidden: Bool) { tabBarHiddenAction(isHidden) }
}

// MARK: - 小工具
private extension OthersViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        OthersTableViewCell.othersViewDelegate = self
        
        refreshControl = UIRefreshControl._build(title: Constant.reload, target: self, action: #selector(Self.refreshBookmarks(_:)))
        fakeTabBarHeightConstraint.constant = self.tabBarController?.tabBar.frame.height ?? 0
        
        reloadBookmarks(isFavorite: isFavorite)
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
    }
    
    /// 重新讀取書籤
    /// - Parameter isFavorite: 我的最愛
    func reloadBookmarks(isFavorite: Bool) {
        
        defer { refreshControl.endRefreshing() }
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        OthersTableViewCell.bookmarksArray = []
        OthersTableViewCell.bookmarksArray = API.shared.searchBookmarkList(isFavorite: isFavorite, info: info, offset: 0)
        
        let listCount = OthersTableViewCell.bookmarksArray.count
        titleSetting(titleString, count: listCount)
        isNeededUpdate = (listCount < Constant.searchCount) ? false : true
        
        myTableView._reloadData() { [weak self] in
            
            guard let this = self,
                  !OthersTableViewCell.bookmarksArray.isEmpty
            else {
                return
            }
            
            this.myTableView._scrollToRow(with: IndexPath(row: 0, section: 0), at: .top) { Utility.shared.flashHUD(with: .success) }
        }
    }
    
    /// 新增書籤
    /// - Parameters:
    ///   - example: 例句
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func appendBookmark(_ title: String, webUrl: String, info: Settings.GeneralInformation) -> Bool {
        return API.shared.insertBookmarkToList(title, webUrl: webUrl, info: info)
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
    
    /// 顯示書籤總數量
    func bookmarkCountAction() {
        
        let version = Bundle.main._appVersion()
        let message = "v\(version.app) - \(version.build)"
        let title = "書籤數量 - \(bookmarkCount())"
        
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
        navigationBarHiddenAction(isHidden)
        currentScrollDirection = direction
    }
    
    /// 設定TabBar顯示與否功能
    /// - Parameters:
    ///   - isHidden: Bool
    func tabBarHiddenAction(_ isHidden: Bool) {
        
        guard let tabBarController = tabBarController else { return }
        
        let duration = Constant.duration
        
        tabBarController._tabBarHidden(isHidden, duration: duration)
        NotificationCenter.default._post(name: .viewDidTransition, object: isHidden)
    }
    
    /// 設定NavigationBar顯示與否功能
    /// - Parameters:
    ///   - isHidden: Bool
    func navigationBarHiddenAction(_ isHidden: Bool) {
        guard let navigationController = navigationController else { return }
        navigationController.setNavigationBarHidden(isHidden, animated: true)
    }
    
    /// 修正TableView不使用SafeArea的位置問題
    func fixTableViewInsetForSafeArea(for indexPath: IndexPath? = nil) {
        
        let navigationBarHeight = navigationController?._navigationBarHeight(for: UIWindow._keyWindow(hasScene: false)) ?? .zero
        
        if (OthersTableViewCell.bookmarksArray.count != 0) { myTableView._fixContentInsetForSafeArea(height: navigationBarHeight, scrollTo: indexPath); return }
        myTableView._fixContentInsetForSafeArea(height: navigationBarHeight, scrollTo: nil)
    }
    
    /// 畫面旋轉的動作 (更新appendButton的位置 / TableView的Inset位置)
    func viewDidTransitionAction() {
        
        NotificationCenter.default._register(name: .viewDidTransition) { [weak self] notification in
            
            guard let this = self,
                  let isHidden = notification.object as? Bool
            else {
                return
            }
            
            this.currentScrollDirection = .none
            this.appendButtonPositionConstraint(isHidden, duration: Constant.duration)
            this.fixTableViewInsetForSafeArea()
            Utility.shared.updateScrolledHeightSetting()
        }
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
    ///   - action: (String, String) -> Bool
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
                  let inputTitle = alertController.textFields?.first?.text?._removeWhiteSpacesAndNewlines(),
                  let inputWebUrl = alertController.textFields?.last?.text?._removeWhiteSpacesAndNewlines()
            else {
                return
            }
            
            this.appendBookmarkAction(with: indexPath, title: inputTitle, webUrl: inputWebUrl, action: action)
        }
        
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 新增書籤的動作
    /// - Parameters:
    ///   - indexPath: IndexPath?
    ///   - title: String
    ///   - webUrl: String
    ///   - action: (String, String) -> Bool
    func appendBookmarkAction(with indexPath: IndexPath?, title: String, webUrl: String, action: @escaping (String, String) -> Bool) {
        
        if (!action(title, webUrl)) { Utility.shared.flashHUD(with: .fail); return }
        
        Utility.shared.flashHUD(with: .success)
        
        if let indexPath = indexPath { updateCellLabel(with: indexPath, title: title, webUrl: webUrl); return }
        reloadBookmarks(isFavorite: isFavorite)
    }
    
    /// 下滑到底更新資料
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - height: CGFloat
    func updateBookmarkList(for scrollView: UIScrollView, height: CGFloat) {
        
        let contentOffsetY = scrollView.contentOffset.y
        let offset = scrollView.frame.height + contentOffsetY - height
        let contentHeight = scrollView.contentSize.height
        
        if (contentOffsetY < 0) { return }
        if (offset > contentHeight) { appendBookmarkList(isFavorite: isFavorite) }
    }
    
    /// 增加書籤列表
    func appendBookmarkList(isFavorite: Bool) {
        
        defer { refreshControl.endRefreshing() }
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        let oldListCount = OthersTableViewCell.bookmarksArray.count
        OthersTableViewCell.bookmarksArray += API.shared.searchBookmarkList(isFavorite: isFavorite, info: info, offset: oldListCount)
        
        let newListCount = OthersTableViewCell.bookmarksArray.count
        titleSetting(titleString, count: newListCount)
        
        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success); return }
        isNeededUpdate = false
    }
    
    /// 右側滑動按鈕
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIContextualAction]
    func trailingSwipeActionsMaker(with indexPath: IndexPath) -> [UIContextualAction] {
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return [] }
        
        let updateAction = UIContextualAction._build(with: "更新", color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)) { [weak self] in
            
            guard let this = self,
                  let bookmarkSite = OthersTableViewCell.bookmarkSite(with: indexPath)
            else {
                return
            }
            
            this.appendBookmarkHint(with: indexPath, title: "請輸入相關文字", titleText: bookmarkSite.title, webUrlText: bookmarkSite.url) { (title, webUrl) in
                return API.shared.updateBookmarkToList(bookmarkSite.id, title: title, webUrl: webUrl, info: info)
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
        
        guard let bookmarkSite = OthersTableViewCell.bookmarkSite(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.deleteBookmark(with: bookmarkSite.id, info: info)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        OthersTableViewCell.bookmarksArray.remove(at: indexPath.row)
        
        myTableView.deleteRows(at: [indexPath], with: .fade)
        titleSetting(titleString, count: OthersTableViewCell.bookmarksArray.count)
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
    
    /// 增加Cell圖示的提示框
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - title: String
    ///   - message: String?
    ///   - iconUrl: String?
    ///   - action: (String) -> Void
    func appendIconUrlHint(with indexPath: IndexPath, title: String, message: String? = nil, iconUrl: String? = nil, action: @escaping (String) -> Void) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField {
            $0.text = iconUrl
            $0.placeholder = "請輸入圖示網址…"
        }
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { _ in
            guard let url = alertController.textFields?.first?.text?._removeWhiteSpacesAndNewlines() else { return }
            action(url)
        }
        
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 更新Cell資料的圖示網址
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - iconUrl: String
    /// - Returns: Bool
    func updateIconUrl(with indexPath: IndexPath, iconUrl: String) -> Bool {
        
        guard var bookmark = OthersTableViewCell.bookmarksArray[safe: indexPath.row],
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let id = bookmark["id"],
              let bookmarkId = Int("\(id)")
        else {
            return false
        }
        
        bookmark["icon"] = iconUrl
        OthersTableViewCell.bookmarksArray[indexPath.row] = bookmark
        
        return API.shared.updateBookmarkIconToList(bookmarkId, iconUrl: iconUrl, info: info)
    }
    
    /// 打開書籤網址
    /// - Parameter indexPath: IndexPath
    func openBookmark(with indexPath: IndexPath) {
        
        guard let urlString = OthersTableViewCell.bookmarkSite(with: indexPath)?.url,
              Utility.shared.isWebUrlString(urlString),
              let url = URL._standardization(string: urlString)
        else {
            Utility.shared.flashHUD(with: .fail); return
        }
        
        currentScrollDirection = .up
        
        let safariController = url._openUrlWithInside(delegate: self)
        safariController.delegate = self
    }
    
    /// 載入Cell的圖示 (變更 / 下載 / 儲存)
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - filename: String
    func loadImageAction(with indexPath: IndexPath, filename: String) {
        
        let bookmarkSite = OthersTableViewCell.bookmarkSite(with: indexPath)
        
        appendIconUrlHint(with: indexPath, title: "請輸入圖示網址", iconUrl: bookmarkSite?.icon) { [weak self] iconUrl in
            
            guard let this = self,
                  this.updateIconUrl(with: indexPath, iconUrl: iconUrl)
            else {
                Utility.shared.flashHUD(with: .fail); return
            }
            
            this.myTableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    /// 下載備份的Database
    /// - Parameter sender: UIBarButtonItem
    func downloadDatabaseAction(_ sender: UIBarButtonItem) {
        
        let documentPickerViewController = UIDocumentPickerViewController._build(delegate: self, allowedUTIs: [.item])
        present(documentPickerViewController, animated: true)
    }
    
    /// 分享(備份)Database
    /// - Parameter sender: UIBarButtonItem
    func shareDatabaseAction(_ sender: UIBarButtonItem) {
        
        guard let fileURL = Constant.database?.fileURL else { return }
        
        let activityViewController = UIActivityViewController._build(activityItems: [fileURL], barButtonItem: sender)
        present(activityViewController, animated: true)
    }
    
    /// 下載資料庫的相關處理
    /// - Parameters:
    ///   - controller: UIDocumentPickerViewController
    ///   - urls: [URL]
    func downloadDocumentAction(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let databaseUrl = Constant.database?.fileURL,
              let fileUrl = urls.first,
              let backupUrl = Utility.shared.databaseBackupUrl()
        else {
            downloadDocumentHint(target: self, title: "備份路徑錯誤", message: nil); return
        }
        
        var result = FileManager.default._moveFile(at: databaseUrl, to: backupUrl)
        
        switch result {
        case .failure(let error): downloadDocumentHint(target: self, title: "錯誤", message: "\(error)")
        case .success(let isSuccess):
            
            if (!isSuccess) { downloadDocumentHint(target: self, title: "備份失敗", message: nil); return }
            
            result = FileManager.default._moveFile(at: fileUrl, to: databaseUrl)
            
            switch result {
            case .failure(let error): downloadDocumentHint(target: self, title: "錯誤", message: "\(error)")
            case .success(let isSuccess):
                
                if (!isSuccess) { downloadDocumentHint(target: self, title: nil, message: "更新失敗"); return }
                
                downloadDocumentHint(target: self, title: "備份 / 更新成功", message: "\(backupUrl.lastPathComponent)") {
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    appDelegate?.initDatabase()
                    NotificationCenter.default._post(name: .refreshViewController)
                }
            }
        }
    }
    
    /// 下載資料庫檔案提示框
    /// - Parameters:
    ///   - target: UIViewController
    ///   - title: String?
    ///   - message: String?
    ///   - barButtonItem: UIBarButtonItem?
    ///   - action: (() -> Void)?
    func downloadDocumentHint(target: UIViewController, title: String?, message: String?, barButtonItem: UIBarButtonItem? = nil, action: (() -> Void)? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "確認", style: .cancel) {  _ in action?() }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = barButtonItem
        
        target.present(alertController, animated: true)
    }
    
    /// 取得書籤總數量
    /// - Returns: Int
    func bookmarkCount() -> Int {
        
        let key = "url"
        let field = "\(key)Count"
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let result = API.shared.searchBookmarkCount(for: info, key: key).first,
              let value = result["\(field)"],
              let count = Int("\(value)", radix: 10)
        else {
            return 0
        }
                
        return count
    }
    
    /// 設定標題
    /// - Parameters:
    ///   - title: String
    ///   - count: Int
    func titleSetting(_ title: String, count: Int) {
        
        guard let titleView = navigationItem.titleView as? UILabel else { titleViewSetting(with: title, count: count); return }
        Utility.shared.titleViewSetting(with: titleView, title: title, count: count)
    }
    
    /// 標題文字相關設定
    /// - Parameters:
    ///   - title: String
    ///   - count: Int
    func titleViewSetting(with title: String, count: Int) {

        let titleView = Utility.shared.titleLabelMaker(with: title)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(Self.bookmarkCount(_:)))
        
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(gesture)
        Utility.shared.titleViewSetting(with: titleView, title: title, count: count)

        navigationItem.titleView = titleView
    }
    
    /// 顯示版本 / 常用書籤數量訊息
    func informationHint(with title: String?, message: String?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "確認", style: .default) { _ in }
        
        alertController.addAction(actionOK)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 過濾是否為Favorite的書籤
    /// - Parameter sender: UIBarButtonItem
    func filterFavoriteAction(with sender: UIBarButtonItem) {
        
        isFavorite.toggle()
        sender.image = Utility.shared.favoriteIcon(isFavorite)
        
        appendBookmarkButton.isHidden = isFavorite
        reloadBookmarks(isFavorite: isFavorite)
    }
}

// MARK: - 下滑更新
private extension OthersViewController {
    
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
            appendBookmarkList(isFavorite: isFavorite)
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
