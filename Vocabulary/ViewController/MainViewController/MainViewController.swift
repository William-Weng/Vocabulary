//
//  MainViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import WWPrint
import WWSQLite3Manager
import WWToast

// MARK: - MainViewDelegate
protocol MainViewDelegate {
    func deleteRow(with indexPath: IndexPath)
    func updateCountLabel(with indexPath: IndexPath, count: Int)
    func tabBarHidden(_ isHidden: Bool)
    func navigationBarHidden(_ isHidden: Bool)
}

// MARK: - 單字頁面
final class MainViewController: UIViewController {
    
    enum ViewSegueType: String {
        case listTableView = "ListTableViewSegue"
        case volumeView = "VolumeViewSegue"
        case searchView = "SearchViewSegue"
    }
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var volumeButtonItem: UIBarButtonItem!
    @IBOutlet weak var musicButtonItem: UIBarButtonItem!
    @IBOutlet weak var appendWordButton: UIButton!
    @IBOutlet weak var fakeTabBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    private let titleString = "我愛背單字"
    
    private var isFixed = false
    private var isAnimationStop = false
    private var isFavorite = false
    private var isNeededUpdate = true
    
    private var currentScrollDirection: Constant.ScrollDirection = .down
    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatedBackground(with: .studing)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!isFixed) { fixTableViewInsetForSafeArea(for: IndexPath(row: 0, section: 0)); isFixed = true }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { prepareAction(for: segue, sender: sender) }
    
    @objc func refreshVocabularyList(_ sender: UIRefreshControl) { reloadVocabulary(isFavorite: isFavorite) }
    @objc func vocabularyCount(_ sender: UITapGestureRecognizer) { vocabularyCountAction() }
    
    @IBAction func appendWordAction(_ sender: UIButton) { appendTextHintAction(sender) }
    @IBAction func filterFavorite(_ sender: UIBarButtonItem) { filterFavoriteAction(with: sender) }
    @IBAction func selectVolume(_ sender: UIBarButtonItem) { performSegue(for: .volumeView, sender: nil) }
    @IBAction func searchWordAction(_ sender: UIBarButtonItem) { performSegue(for: .searchView, sender: nil) }
    
    deinit {
        MainTableViewCell.vocabularyListArray = []
        NotificationCenter.default._remove(observer: self, name: .viewDidTransition)
        wwPrint("\(Self.self) deinit")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return MainTableViewCell.vocabularyListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return mainTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { performSegue(for: .listTableView, sender: indexPath) }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { tabrBarHidden(with: scrollView); updateHeightPercentAction(with: scrollView, isNeededUpdate: isNeededUpdate) }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension MainViewController: UIPopoverPresentationControllerDelegate {}

// MARK: - MainViewDelegate
extension MainViewController: MainViewDelegate {
    
    func deleteRow(with indexPath: IndexPath) { deleteRowAction(with: indexPath) }
    func updateCountLabel(with indexPath: IndexPath, count: Int) { updateCountLabelAction(with: indexPath, count: count) }
    func tabBarHidden(_ isHidden: Bool) { tabBarHiddenAction(isHidden) }
    func navigationBarHidden(_ isHidden: Bool) { navigationBarHiddenAction(isHidden) }
}

// MARK: - MyNavigationControllerDelegate
extension MainViewController: MyNavigationControllerDelegate {
    func refreshRootViewController() { reloadVocabulary(isFavorite: isFavorite) }
}

// MARK: - 小工具
private extension MainViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        
        refreshControl = UIRefreshControl._build(title: "重新讀取", target: self, action: #selector(Self.refreshVocabularyList(_:)))
        fakeTabBarHeightConstraint.constant = tabBarController?.tabBar.frame.height ?? 0
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
        
        reloadVocabulary(isFavorite: isFavorite)
        
        viewDidTransitionAction()
        backupDatabaseAction(delay: Constant.autoBackupDelaySecond)
    }
    
    /// 產生MainTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: MainTableViewCell
    func mainTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> MainTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as MainTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 顯示單字總數量
    func vocabularyCountAction() {

        let version = Bundle.main._appVersion()
        let message = "v\(version.app ?? "1.0.0") - \(version.build ?? "0")"
        let title = "單字數量 - \(vocabularyCount(isFavorite: isFavorite))"
        
        informationHint(with: title, message: message)
    }
    
    /// 處理UIStoryboardSegue跳轉到下一頁的功能
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func prepareAction(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier,
              let segueType = ViewSegueType(rawValue: identifier)
        else {
            return
        }
        
        switch segueType {
        case .listTableView: vocabularyListPageSetting(for: segue, sender: sender)
        case .volumeView: volumePageSetting(for: segue, sender: sender)
        case .searchView: break
        }
    }
    
    /// 使用Segue進入下一頁
    /// - Parameter indexPath: IndexPath
    func performSegue(for type: ViewSegueType, sender: Any?) {
        currentScrollDirection = .up
        performSegue(withIdentifier: type.rawValue, sender: sender)
    }
    
    /// 重新讀取單字
    /// - Parameter isFavorite: Bool
    func reloadVocabulary(isFavorite: Bool = false) {
        
        defer { refreshControl.endRefreshing() }
        
        MainTableViewCell.vocabularyListArray = []
        MainTableViewCell.vocabularyListArray = API.shared.searchVocabularyList(isFavorite: isFavorite, for: Constant.currentTableName, offset: MainTableViewCell.vocabularyListArray.count)
        
        let listCount = MainTableViewCell.vocabularyListArray.count
        titleSetting(titleString, count: listCount)
        isNeededUpdate = (listCount < Constant.searchCount) ? false : true
        
        myTableView._reloadData() { [weak self] in
            
            guard let this = self,
                  !MainTableViewCell.vocabularyListArray.isEmpty
            else {
                return
            }
            
            let topIndexPath = IndexPath(row: 0, section: 0)
            this.myTableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
            
            Utility.shared.flashHUD(with: .success)
        }
    }
    
    /// 刪除該列資料功能
    /// - Parameter indexPath: IndexPath
    func deleteRowAction(with indexPath: IndexPath) {
        MainTableViewCell.vocabularyListArray.remove(at: indexPath.row)
        myTableView.deleteRows(at: [indexPath], with: .fade)
        titleSetting(titleString, count: MainTableViewCell.vocabularyListArray.count)
    }
    
    /// 更新例句數量文字功能
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - count: 數量
    func updateCountLabelAction(with indexPath: IndexPath, count: Int) {
        
        guard var dictionary = MainTableViewCell.vocabularyListArray[safe: indexPath.row] else { return }
        
        dictionary["count"] = count
        MainTableViewCell.vocabularyListArray[indexPath.row] = dictionary
        
        myTableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    /// 設定TabBar顯示與否功能
    /// - Parameters:
    ///   - isHidden: Bool
    func tabBarHiddenAction(_ isHidden: Bool) {
        
        guard let tabBarController = tabBarController else { return }
        
        let duration = Constant.duration
        
        NotificationCenter.default._post(name: .viewDidTransition, object: isHidden)
        tabBarController._tabBarHidden(isHidden, duration: duration)
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
        
        if (MainTableViewCell.vocabularyListArray.count != 0) { myTableView._fixContentInsetForSafeArea(height: navigationBarHeight, scrollTo: indexPath); return }
        myTableView._fixContentInsetForSafeArea(height: navigationBarHeight, scrollTo: nil)
    }
    
    /// [新增單字列表](https://medium.com/@daoseng33/我說那個-uitableview-insertrows-uicollectionview-insertitems-呀-56b8758b2efb)
    /// - Parameter isFavorite: Bool
    func appendVocabularyList(isFavorite: Bool) {
        
        defer { refreshControl.endRefreshing() }
        
        let oldListCount = MainTableViewCell.vocabularyListArray.count
        MainTableViewCell.vocabularyListArray += API.shared.searchVocabularyList(isFavorite: isFavorite, for: Constant.currentTableName, offset: oldListCount)
        
        let newListCount = MainTableViewCell.vocabularyListArray.count
        titleSetting(titleString, count: newListCount)

        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success); return }
        isNeededUpdate = false
    }
    
    /// 新增/更新單字
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表
    /// - Returns: Bool
    func appendWord(_ word: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard API.shared.insertNewWord(word, for: tableName) else { return false }
        
        let count = vocabularyDetailListCount(with: word)
        if (count > 1) { return API.shared.updateWordToList(word, for: tableName, count: count) }
        
        return API.shared.insertWordToList(word, for: tableName)
    }
    
    /// 更新單字音標
    /// - Parameters:
    ///   - word: 單字
    ///   - alphabet: 音標
    ///   - tableName: 資料表名稱
    /// - Returns: Bool
    func updateAlphabetLabel(with indexPath: IndexPath, id: Int, alphabet: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard var dictionary = MainTableViewCell.vocabularyListArray[safe: indexPath.row] else { return false }
        
        dictionary["alphabet"] = alphabet
        MainTableViewCell.vocabularyListArray[indexPath.row] = dictionary
        
        return API.shared.updateAlphabetToList(id, alphabet: alphabet, for: tableName)
    }
    
    /// 更新等級Level文字
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - level: 等級
    func updateLevelLabel(with indexPath: IndexPath, level: Vocabulary.Level) {
        
        guard var dictionary = MainTableViewCell.vocabularyListArray[safe: indexPath.row] else { return }
        
        dictionary["level"] = level.rawValue
        MainTableViewCell.vocabularyListArray[indexPath.row] = dictionary
        
        myTableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    /// 新增單字的動作
    /// - Parameter sender: UIButton
    func appendTextHintAction(_ sender: UIButton) {
        
        appendTextHint(title: "請輸入單字") { [weak self] inputWord in
            guard let this = self else { return false }
            return this.appendWord(inputWord, for: Constant.currentTableName)
        }
    }
    
    /// 新增文字的提示框
    /// - Parameters:
    ///   - indexPath: 要更新音標時，才會有IndexPath
    ///   - title: 標題
    ///   - message: 訊息文字
    ///   - defaultText: 預設文字
    ///   - action: (String) -> Bool
    func appendTextHint(with indexPath: IndexPath? = nil, title: String, message: String? = nil, defaultText: String? = nil, action: @escaping (String) -> Bool) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addTextField {
            $0.text = defaultText
            $0.placeholder = title
        }
        
        let actionOK = appendTextAlertAction(with: indexPath, textFields: alertController.textFields, action: action)
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 新增文字的提示框動作
    /// - Parameters:
    ///   - indexPath: IndexPath?
    ///   - textFields: [UITextField]?
    ///   - action: (String) -> Bool
    /// - Returns: UIAlertAction
    func appendTextAlertAction(with indexPath: IndexPath? = nil, textFields: [UITextField]?, action: @escaping (String) -> Bool) -> UIAlertAction {
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            
            guard let this = self,
                  let inputWord = textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            else {
                return
            }
            
            if (!action(inputWord)) { Utility.shared.flashHUD(with: .fail); return }
            
            if let indexPath = indexPath {
                this.myTableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                this.reloadVocabulary()
            }
        }
        
        return actionOK
    }
    
    /// 右側滑動按鈕
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIContextualAction]
    func trailingSwipeActionsMaker(with indexPath: IndexPath) -> [UIContextualAction] {
        
        let updateAction = UIContextualAction._build(with: "音標", color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)) { [weak self] in
            
            guard let this = self,
                  let vocabularyList = MainTableViewCell.vocabularyList(with: indexPath)
            else {
                return
            }
            
            this.appendTextHint(with: indexPath, title: "請輸入音標", defaultText: vocabularyList.alphabet) { alphabet in
                return this.updateAlphabetLabel(with: indexPath, id: vocabularyList.id, alphabet: alphabet, for: Constant.currentTableName)
            }
        }
                
        return [updateAction]
    }
    
    /// 設定單字列表頁的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func vocabularyListPageSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? ListViewController,
              let indexPath = sender as? IndexPath,
              let vocabularyList = MainTableViewCell.vocabularyList(with: indexPath)
        else {
            return
        }
        
        viewController.canDelete = true
        viewController.vocabularyList = vocabularyList
        viewController.vocabularyListIndexPath = indexPath
        viewController.mainViewDelegate = self
    }
    
    /// 設定音量頁的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func volumePageSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? VolumeViewController else { return }
        
        viewController._transparent(.black.withAlphaComponent(0.3))
        viewController.soundType = .volume
        viewController.mainViewDelegate = self
        
        tabBarHidden(true)
    }
    
    /// 動畫背景設定
    /// - Parameter type: Utility.HudGifType
    func animatedBackground(with type: Constant.HudGifType) {
        
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
    
    /// [滑動時TabBar是否隱藏的規則設定 => NavigationBar也一起處理](https://www.jianshu.com/p/539b265bcb5d)
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
        
        tabBarHidden(isHidden)
        navigationBarHidden(isHidden)
        currentScrollDirection = direction
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
            this.updateScrolledHeightSetting()
        }
    }
    
    /// 更新新增單字Button的位置 for Tabbar
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
    
    /// 建立存放背景音樂的資料夾
    /// - Returns: 資料夾的URL
    func musicFolderMaker() -> URL? {
        
        guard let musicFolderUrl = Constant.FileFolder.music.url() else { return nil }
        
        let result = FileManager.default._createDirectory(with: musicFolderUrl, path: "")
        
        switch result {
        case .failure(let error): wwPrint(error); return nil
        case .success(let isSuccess): return (!isSuccess) ? nil : musicFolderUrl
        }
    }
    
    /// 背景音樂的資料夾的檔案列表
    /// - Returns: [String]?
    func musicFileList() -> [String]? {
        
        guard let musicFolder = musicFolderMaker() else { return nil }
        
        let result = FileManager.default._fileList(with: musicFolder)
        
        switch result {
        case .failure(let error): wwPrint(error); return nil
        case .success(let list): return list
        }
    }
    
    /// 備份資料庫
    /// - Parameter second: 3秒後備份
    func backupDatabaseAction(delay second: TimeInterval) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + second) { [weak self] in
            
            guard let this = self else { return }
            
            let date = this.lastBackupDatabaseDate()
            let backUpIfNeeded = this.autoBackupDatabaseRule(lastDate: date, days: Constant.autoBackupDays)
                        
            if (backUpIfNeeded) {

                let result = this.backupDatabase()
                var message: Any
                
                switch result {
                case .failure(let error): message = error
                case .success(let filename):
                    message = "自動備份失敗"
                    if let filename = filename { message = filename }
                }
                
                let backgroundColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1).withAlphaComponent(0.7)
                WWToast.shared.makeText(target: this, text: message, backgroundColor: backgroundColor)
            }
        }
    }
    
    /// 備份資料庫
    /// - Returns: Result<Bool, Error>
    func backupDatabase() -> Result<String?, Error> {
        
        guard let databaseUrl = Constant.database?.fileURL,
              let filename = Optional.some("\(Date()._localTime(dateFormat: "yyyy-MM-dd HH:mm:ss ZZZ", timeZone: .current)).\(Constant.databaseFileExtension)"),
              let backupUrl = Constant.backupDirectory?._appendPath(filename)
        else {
            return .failure(Constant.MyError.notOpenURL)
        }
        
        let result = FileManager.default._copyFile(at: databaseUrl, to: backupUrl)
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let isSuccess): return (isSuccess ? .success(filename) : .success(nil))
        }
    }
    
    /// 自動備份的規則 => 完全沒備份過 / 超過7天
    /// - Parameters:
    ///   - lastDate: Date?
    ///   - days: Int
    /// - Returns: Bool
    func autoBackupDatabaseRule(lastDate: Date?, days: Int) -> Bool {
        
        guard let lastDate = lastDate,
              let ruleDate = lastDate._adding(value: days)
        else {
            return true
        }
        
        if Date() > ruleDate { return true }
        return false
    }
    
    /// 取得最後備份資料庫的檔案日期
    /// - Returns: Date?
    func lastBackupDatabaseDate() -> Date? {
        
        guard let backupDirectory = Constant.backupDirectory else { return nil }
        
        let fileManager = FileManager.default
        let result = fileManager._fileList(with: backupDirectory)
        
        var lastBackupDate: Date?
        
        switch result {
        case .failure(let error): wwPrint(error); break
        case .success(let fileList):
            
            guard let fileList = fileList else { break }
            
            lastBackupDate = fileList.compactMap { filename -> Date? in
                
                guard let url = backupDirectory._appendPath(filename),
                      url.pathExtension.lowercased() == Constant.databaseFileExtension.lowercased(),
                      let date = filename.replacingOccurrences(of: ".\(Constant.databaseFileExtension)", with: "")._date()
                else {
                    return nil
                }
                
                return date
                
            }.sorted(by: >).first
        }
        
        return lastBackupDate
    }
    
    /// 取得單字總數量
    /// - Parameter isFavorite: Bool
    /// - Returns: Int
    func vocabularyCount(isFavorite: Bool) -> Int {
        
        let key = "word"
        let field = "\(key)Count"
        
        guard let result = API.shared.searchVocabularyCount(for: Constant.currentTableName, key: key, isFavorite: isFavorite).first,
              let value = result["\(field)"],
              let count = Int("\(value)", radix: 10)
        else {
            return 0
        }
                
        return count
    }
    
    /// 取得該單字內容總數量
    /// - Parameters:
    ///   - word: String
    /// - Returns: Int
    func vocabularyDetailListCount(with word: String) -> Int {
        
        let key = "word"
        let field = "\(key)Count"
        
        guard let result = API.shared.searchWordDetailListCount(word, for: Constant.currentTableName, key: key).first,
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
        let gesture = UITapGestureRecognizer(target: self, action: #selector(Self.vocabularyCount(_:)))
        
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(gesture)
        Utility.shared.titleViewSetting(with: titleView, title: title, count: count)
        
        navigationItem.titleView = titleView
    }
    
    /// 顯示版本 / 單字數量訊息
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
        
        appendWordButton.isHidden = isFavorite
        reloadVocabulary(isFavorite: isFavorite)
    }
}

// MARK: - UIMenu
private extension MainViewController {
    
    /// [初始化功能選單](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/ios-的選單-menu-按鈕-pull-down-button-pop-up-button-2ddab2181ee5)
    /// => [UIMenu - iOS 14](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/在-iphone-ipad-上顯示-popover-彈出視窗-ac196732e557)
    func initMenu() {
        initMusicItemMenu()
    }
    
    /// 初始化音樂選單 (UIMenu)
    /// - Parameter sender: UIBarButtonItem
    func initMusicItemMenu() {
        
        guard var musicList = musicFileList()?.sorted() else { return }
        
        musicList.append("靜音")
        
        let actions = musicList.map({ musicItemMenuActionMaker(filename: $0) })
        let menu = UIMenu(title: "請選擇背景音樂 (.mp3 / .m4a)", children: actions)
        
        musicButtonItem.menu = menu
    }
    
    /// 產生音樂選單
    /// - Parameter filename: String
    /// - Returns: UIAction
    func musicItemMenuActionMaker(filename: String) -> UIAction {
        
        let music = Music(filename: filename)
        
        let action = UIAction(title: "\(music.filename)") { [weak self] _ in
            
            guard let this = self,
                  let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else {
                return
            }
            
            let isSuccess = appDelegate.playBackgroundMusic(with: music, volume: Constant.volume)
            
            this.volumeButtonItem.image = !isSuccess ? UIImage(named: "NoVolume") : UIImage(named: "Volume")
            this.volumeButtonItem.isEnabled = isSuccess
        }
        
        return action
    }
}

// MARK: - 下滑更新
private extension MainViewController {
    
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
            appendVocabularyList(isFavorite: isFavorite)
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
        indicatorLabel.text = updateActivityViewIndicatorTitle(with: percent, isNeededUpdate: isNeededUpdate)
    }
    
    /// 下滑到底更新的顯示Title
    /// - Parameters:
    ///   - percent: CGFloat
    ///   - isNeededUpdate: Bool
    /// - Returns: String
    func updateActivityViewIndicatorTitle(with percent: CGFloat, isNeededUpdate: Bool) -> String {
        
        if (!isNeededUpdate) { return "無更新資料" }
        
        var _percent = percent
        if (percent > 1.0) { _percent = 1.0 }
        
        let title = String(format: "%.2f", _percent * 100)
        return "\(title) %"
    }
    
    /// 更新下滑更新的高度基準值
    /// - Parameter percent: KeyWindow高度的25%
    func updateScrolledHeightSetting(percent: CGFloat = 0.25) {
        guard let keyWindow = UIWindow._keyWindow(hasScene: false) else { return }
        Constant.updateScrolledHeight = keyWindow.frame.height * percent
    }
}
