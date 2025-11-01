//
//  SentenceViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/6.
//

import UIKit
import SafariServices

// MARK: - SentenceViewDelegate
protocol SentenceViewDelegate: NSObject {
    func wordDictionary(with indexPath: IndexPath)
    func tabBarHidden(_ isHidden: Bool)
}

// MARK: - 精選例句
final class SentenceViewController: UIViewController {

    enum ViewSegueType: String {
        case recording = "RecordingSegue"
        case chatting = "ChattingSegue"
    }
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var appendWordButton: UIButton!
    @IBOutlet weak var speechButtonItem: UIBarButtonItem!
    @IBOutlet weak var fakeTabBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    private let titleString = "精選例句"

    private var isAnimationStop = false
    private var isFixed = false
    private var isFavorite = false
    private var isNeededUpdate = true
    
    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    private var currentScrollDirection: Constant.ScrollDirection = .down
    private var currentSpeechInformation: Settings.SentenceSpeechInformation? = nil
    
    private var translateDisplayArray: Set<Int> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initMenu()
        viewDidTransitionAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatedBackground(with: .sentence)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!isFixed) { fixTableViewInsetForSafeArea(for: IndexPath(row: 0, section: 0)); isFixed = true }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier,
              let viewSegueType = ViewSegueType(rawValue: identifier)
        else {
            return
        }
        
        switch viewSegueType {
        case .chatting: chattingSetting(for: segue, sender: sender)
        case .recording: break
        }
    }
    
    @objc func refreshSentenceList(_ sender: UIRefreshControl) { translateDisplayArray = []; reloadSentenceList(with: currentSpeechInformation, isFavorite: isFavorite) }
    @objc func sentenceCount(_ sender: UITapGestureRecognizer) { sentenceCountAction(with: currentSpeechInformation, isFavorite: isFavorite) }
    
    @IBAction func chattingAction(_ sender: UIBarButtonItem) { performSegue(withIdentifier: ViewSegueType.chatting.rawValue, sender: nil) }
    @IBAction func filterFavorite(_ sender: UIBarButtonItem) { translateDisplayArray = []; filterFavoriteAction(sender) }
    @IBAction func appendSentenceAction(_ sender: UIButton) {
        
        appendSentenceHint(title: "請輸入例句") { [weak self] (example, translate) in
            
            guard let this = self,
                  let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
            else {
                return false
            }
            
            return this.appendSentence(example, translate: translate, info: info)
        }
    }
    
    deinit {
        SentenceTableViewCell.sentenceListArray = []
        SentenceTableViewCell.sentenceViewDelegate = nil
        NotificationCenter.default._remove(observer: self, name: .viewDidTransition)
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SentenceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return SentenceTableViewCell.sentenceListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return sentenceTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { translateDisplayAction(tableView, didSelectRowAt: indexPath) }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { tabrBarHidden(with: scrollView); updateHeightPercentAction(with: scrollView, isNeededUpdate: isNeededUpdate) }
}

// MARK: - SFSafariViewControllerDelegate
extension SentenceViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
        let isHidden = false
        tabBarHiddenAction(isHidden)
        navigationBarHiddenAction(isHidden)
    }
}

// MARK: - SentenceViewDelegate
extension SentenceViewController: SentenceViewDelegate {
    
    func wordDictionary(with indexPath: IndexPath) { netDictionary(with: indexPath) }
    func tabBarHidden(_ isHidden: Bool) { tabBarHiddenAction(isHidden) }
}

// MARK: - MyNavigationControllerDelegate
extension SentenceViewController: MyNavigationControllerDelegate {
    
    func refreshRootViewController() {
        currentSpeechInformation = nil
        reloadSentenceList(with: currentSpeechInformation, isFavorite: isFavorite)
    }
}

// MARK: - 小工具
private extension SentenceViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        SentenceTableViewCell.sentenceViewDelegate = self

        refreshControl = UIRefreshControl._build(title: Constant.reload, target: self, action: #selector(Self.refreshSentenceList(_:)))
        fakeTabBarHeightConstraint.constant = self.tabBarController?.tabBar.frame.height ?? 0
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        
        reloadSentenceList(with: currentSpeechInformation, isFavorite: isFavorite)
    }
    
    /// 顯示精選例句總數量
    /// - Parameters:
    ///   - speech: VocabularySentenceList.Speech?
    ///   - isFavorite: Bool
    func sentenceCountAction(with info: Settings.SentenceSpeechInformation?, isFavorite: Bool) {
        
        let version = Bundle.main._appVersion()
        let message = "v\(version.app) - \(version.build)"
        let title = "\(titleString) - \(sentenceCount(with: info, isFavorite: isFavorite))"

        informationHint(with: title, message: message)
    }
    
    /// 重新讀取單字
    /// - Parameters:
    ///   - info: Settings.SentenceSpeechInformation?
    ///   - isFavorite: Bool
    func reloadSentenceList(with speechInfo: Settings.SentenceSpeechInformation?, isFavorite: Bool) {
        
        defer {
            appendWordButtonHidden(with: speechInfo, isFavorite: isFavorite)
            refreshControl.endRefreshing()
        }
        
        guard let generalInfo = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        SentenceTableViewCell.sentenceListArray = []
        SentenceTableViewCell.sentenceListArray = API.shared.searchSentenceList(with: speechInfo, isFavorite: isFavorite, generalInfo: generalInfo, offset: 0)
        
        let listCount = SentenceTableViewCell.sentenceListArray.count
        titleSetting(titleString, count: listCount)
        isNeededUpdate = (listCount < Constant.searchCount) ? false : true
        
        myTableView._reloadData() { [weak self] in
            
            guard let this = self,
                  !SentenceTableViewCell.sentenceListArray.isEmpty
            else {
                return
            }
            
            this.myTableView._scrollToRow(with: IndexPath(row: 0, section: 0), at: .top) { Utility.shared.flashHUD(with: .success) }
        }
    }
    
    /// [新增例句列表](https://medium.com/@daoseng33/我說那個-uitableview-insertrows-uicollectionview-insertitems-呀-56b8758b2efb)
    /// - Parameters:
    ///   - info: Settings.SentenceSpeechInformation?
    ///   - isFavorite: Bool
    func appendSentenceList(with speechInfo: Settings.SentenceSpeechInformation?, isFavorite: Bool) {
        
        defer { refreshControl.endRefreshing() }
        
        guard let generalInfo = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        let oldListCount = SentenceTableViewCell.sentenceListArray.count
        SentenceTableViewCell.sentenceListArray += API.shared.searchSentenceList(with: speechInfo, isFavorite: isFavorite, generalInfo: generalInfo, offset: oldListCount)
        
        let newListCount = SentenceTableViewCell.sentenceListArray.count
        titleSetting(titleString, count: newListCount)
        
        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success); return }
        isNeededUpdate = false
    }
    
    /// 產生SentenceTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: MainTableViewCell
    func sentenceTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> SentenceTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as SentenceTableViewCell
        cell.configure(with: indexPath)
        cell.translateLabel.textColor = (!translateDisplayArray.contains(indexPath.row)) ? .clear : .darkGray

        return cell
    }
    
    /// 右側滑動按鈕
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIContextualAction]
    func trailingSwipeActionsMaker(with indexPath: IndexPath) -> [UIContextualAction] {
        
        let updateAction = UIContextualAction._build(with: "更新", color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)) { [weak self] in
            guard let this = self else { return }
            this.updateSentence(with: indexPath)
        }
        
        let deleteAction = UIContextualAction._build(with: "刪除", color: #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)) { [weak self] in
            guard let this = self else { return }
            this.deleteSentence(with: indexPath)
        }
        
        return [updateAction, deleteAction]
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
    
    /// 滑動時TabBar是否隱藏的規則設定
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
    
    /// 設定TabBar顯示與否
    /// - Parameters:
    ///   - isHidden: Bool
    func tabBarHiddenAction(_ isHidden: Bool) {
        Utility.shared.tabBarHidden(with: tabBarController, isHidden: isHidden)
    }
    
    /// 設定NavigationBar顯示與否功能
    /// - Parameters:
    ///   - isHidden: Bool
    func navigationBarHiddenAction(_ isHidden: Bool) {
        guard let navigationController = navigationController else { return }
        navigationController._barHidden(isHidden)
    }
    
    /// 修正TableView不使用SafeArea的位置問題
    func fixTableViewInsetForSafeArea(for indexPath: IndexPath? = nil) {
        
        let navigationBarHeight = navigationController?._navigationBarHeight(for: UIWindow._keyWindow(hasScene: false)) ?? .zero
        
        if (SentenceTableViewCell.sentenceListArray.count != 0) { myTableView._fixContentInsetForSafeArea(height: navigationBarHeight, scrollTo: indexPath); return }
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
    
    /// 更新新增例句Button的位置 for Tabbar
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
    
    /// 新增例句的提示框
    /// - Parameters:
    ///   - indexPath: 要更新音標時，才會有IndexPath
    ///   - title: 標題
    ///   - message: 訊息文字
    ///   - defaultText: 預設文字
    ///   - action: (String) -> Bool
    func appendSentenceHint(with indexPath: IndexPath? = nil, title: String, message: String? = nil, exampleText: String? = nil, translateText: String? = nil, action: @escaping (String, String) -> Bool) {
        
        let alertController = UIAlertController._build(title: title, message: message)

        alertController.addTextField {
            $0.text = exampleText
            $0.placeholder = "請輸入例句…"
        }
        
        alertController.addTextField {
            $0.text = translateText
            $0.placeholder = "請輸入翻譯…"
        }
        
        let actionOK = appendSentenceAlertAction(with: indexPath, textFields: alertController.textFields, action: action)
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 新增例句的提示框動作
    /// - Parameters:
    ///   - indexPath: IndexPath?
    ///   - textFields: [UITextField]?
    ///   - action: (String, String) -> Bool
    /// - Returns: UIAlertAction
    func appendSentenceAlertAction(with indexPath: IndexPath? = nil, textFields: [UITextField]?, action: @escaping (String, String) -> Bool) -> UIAlertAction {
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            
            guard let this = self,
                  let inputExampleText = textFields?.first?.text?._removeWhiteSpacesAndNewlines(),
                  let inputTranslateText = textFields?.last?.text?._removeWhiteSpacesAndNewlines()
            else {
                return
            }
            
            if (!action(inputExampleText, inputTranslateText)) { Utility.shared.flashHUD(with: .fail); return }
            
            Utility.shared.flashHUD(with: .success)
            
            if let indexPath = indexPath {
                this.fixTranslateDisplayArray(with: indexPath, type: .update)
                this.myTableView.reloadRows(at: [indexPath], with: .automatic); return
            }
            
            this.fixTranslateDisplayArray(with: IndexPath(row: 0, section: 0), type: .append)
            this.reloadSentenceList(with: this.currentSpeechInformation, isFavorite: this.isFavorite)
        }
        
        return actionOK
    }
    
    /// 新增例句
    /// - Parameters:
    ///   - example: 例句
    ///   - tableName: 翻譯
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func appendSentence(_ example: String, translate: String, info: Settings.GeneralInformation) -> Bool {
        return API.shared.insertSentenceToList(example, translate: translate, info: info)
    }
    
    /// 下滑到底更新資料
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - height: CGFloat
    func updateSentenceList(for scrollView: UIScrollView, height: CGFloat) {
        
        let contentOffsetY = scrollView.contentOffset.y
        let offset = scrollView.frame.height + contentOffsetY - height
        let contentHeight = scrollView.contentSize.height
        
        if (contentOffsetY < 0) { return }
        if (offset > contentHeight) { appendSentenceList(with: currentSpeechInformation, isFavorite: isFavorite) }
    }
    
    /// 更新例句 (句子 / 翻譯)
    /// - Parameter indexPath: IndexPath
    func updateSentence(with indexPath: IndexPath) {
        
        guard let sentenceList = SentenceTableViewCell.sentenceList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        appendSentenceHint(with: indexPath, title: "請更新例句", exampleText: sentenceList.example, translateText: sentenceList.translate) { (exampleInput, translateInput) in
            
            guard var dictionary = SentenceTableViewCell.sentenceListArray[safe: indexPath.row] else { return false }
            
            dictionary["example"] = exampleInput
            dictionary["translate"] = translateInput
            SentenceTableViewCell.sentenceListArray[indexPath.row] = dictionary
            
            return API.shared.updateSentenceToList(sentenceList.id, example: exampleInput, translate: translateInput, info: info)
        }
    }
    
    /// 刪除例句
    /// - Parameter indexPath: IndexPath
    func deleteSentence(with indexPath: IndexPath) {
        
        guard let sentenceList = SentenceTableViewCell.sentenceList(with: indexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let isSuccess = API.shared.deleteSentenceList(with: sentenceList.id, info: info)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        SentenceTableViewCell.sentenceListArray.remove(at: indexPath.row)
        titleSetting(titleString, count: SentenceTableViewCell.sentenceListArray.count)
        
        myTableView.deleteRows(at: [indexPath], with: .fade)
        fixTranslateDisplayArray(with: indexPath, type: .delete)
    }
    
    /// 例句網路字典
    /// - Parameter indexPath: IndexPath
    func netDictionary(with indexPath: IndexPath) {
        
        guard let dictionary = SentenceTableViewCell.sentenceListArray[safe: indexPath.row],
              let sentenceList = dictionary._jsonClass(for: VocabularySentenceList.self)
        else {
            return
        }
        
        netDictionary(with: sentenceList.example)
    }
    
    /// 例句網路字典
    /// - Parameter example: 例句
    func netDictionary(with example: String?) {
        
        guard let example = example,
              let url = URL._standardization(string: googleSearchUrlString(with: example))
        else {
            return
        }
        
        currentScrollDirection = .up
        
        let safariController = url._openUrlWithInside(delegate: self)
        safariController.delegate = self
    }
    
    /// Google搜尋
    /// - Parameter example: 例句
    func googleSearchUrlString(with example: String) -> String {
        let googleSearchUrl = "https://www.google.com/search?q=\(example)"
        return googleSearchUrl
    }
    
    /// 設定對話頁面
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func chattingSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? ChatViewController else { return }
        viewController.sentenceViewDelegate = self
    }
    
    /// 取得精選例句總數量
    /// - Parameters:
    ///   - speechInfo: VocabularySentenceList.Speech?
    ///   - isFavorite: Bool
    /// - Returns: Int
    func sentenceCount(with speechInfo: Settings.SentenceSpeechInformation?, isFavorite: Bool) -> Int {
        
        let key = "speech"
        let field = "\(key)Count"
        
        guard let generalInfo = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let result = API.shared.searchSentenceCount(generalInfo: generalInfo, key: key, speechInfo: speechInfo, isFavorite: isFavorite).first,
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
        let gesture = UITapGestureRecognizer(target: self, action: #selector(Self.sentenceCount(_:)))
        
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(gesture)
        Utility.shared.titleViewSetting(with: titleView, title: title, count: count)

        navigationItem.titleView = titleView
    }
    
    /// 顯示版本 / 精選例句數量訊息
    func informationHint(with title: String?, message: String?) {
        
        let alertController = UIAlertController._build(title: title, message: message)
        let actionOK = UIAlertAction(title: "確認", style: .default) { _ in }
        
        alertController.addAction(actionOK)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 翻譯顯示與否
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    func translateDisplayAction(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        translateDisplayArray._toggle(member: indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    /// 修正記錄翻譯顯示與否，CRUD造成IndexPath移動的問題
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - type: Constant.WordActionType
    func fixTranslateDisplayArray(with indexPath: IndexPath, type: Constant.WordActionType) {
        
        var _translateDisplayArray: [Int] = []
        
        switch type {
        case .append:
            _translateDisplayArray = self.translateDisplayArray.map { $0 + 1 }
            _translateDisplayArray.append(indexPath.row)
        case .update:
            _translateDisplayArray = Array(self.translateDisplayArray)
            _translateDisplayArray.append(indexPath.row)
        case .delete:
            _translateDisplayArray = self.translateDisplayArray.compactMap { ($0 > indexPath.row) ? ($0 - 1) : nil }
        case .search:
            break
        }
        
        self.translateDisplayArray = Set(_translateDisplayArray)
    }
    
    /// 過濾是否為Favorite的單字
    /// - Parameter sender: UIBarButtonItem
    func filterFavoriteAction(_ sender: UIBarButtonItem) {
        isFavorite.toggle()
        sender.image = Utility.shared.favoriteIcon(isFavorite)
        reloadSentenceList(with: currentSpeechInformation, isFavorite: isFavorite)
    }
    
    /// 設定新增例句按鍵是否顯示
    func appendWordButtonHidden(with info: Settings.SentenceSpeechInformation?, isFavorite: Bool) {
        
        var isHidden = false
        
        if (isFavorite) { isHidden = true }
        if (info != nil) { isHidden = true }

        appendWordButton.isHidden = isHidden
    }
}

// MARK: - UIMenu
private extension SentenceViewController {
    
    /// [初始化功能選單](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/ios-的選單-menu-按鈕-pull-down-button-pop-up-button-2ddab2181ee5)
    /// => [UIMenu - iOS 14](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/在-iphone-ipad-上顯示-popover-彈出視窗-ac196732e557)
    func initMenu() {
        initSpeechItemMenu()
    }
    
    /// 初始化例句屬性選單 (UIMenu)
    /// - Parameter sender: UIBarButtonItem
    func initSpeechItemMenu() {
                
        let action = speechItemMenuActionMaker(info: nil)
        var actions = Constant.SettingsJSON.sentenceSpeechInformations.map { speechItemMenuActionMaker(info: $0) }
        
        actions.insert(action, at: 0)
        
        let menu = UIMenu(title: "請選擇例句屬性", options: .singleSelection, children: actions)
        speechButtonItem.menu = menu
    }
    
    /// 產生字典資料庫選單
    /// - Parameter info: Settings.SentenceSpeechInformation?
    /// - Returns: UIAction
    func speechItemMenuActionMaker(info: Settings.SentenceSpeechInformation?) -> UIAction {
        
        let title = info?.name ?? "全部"
        
        let action = UIAction(title: title) { [weak self] _ in
            
            guard let this = self else { return }
            
            this.currentSpeechInformation = info
            this.fixTranslateDisplayArray(with: IndexPath(row: 0, section: 0), type: .search)
            this.reloadSentenceList(with: info, isFavorite: this.isFavorite)
        }
        
        return action
    }
}

// MARK: - 下滑更新
private extension SentenceViewController {
    
    /// 下滑到底更新的動作設定
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - criticalValue: 要更新的臨界值 => 120%才更新
    func updateHeightPercentAction(with scrollView: UIScrollView, criticalValue: CGFloat = 1.2, isNeededUpdate: Bool) {
        
        var percent = Utility.shared.updateHeightPercent(with: scrollView, navigationController: navigationController)
        
        if isNeededUpdate && (percent > criticalValue) {
            percent = 0.0
            Utility.shared.impactEffect()
            appendSentenceList(with: currentSpeechInformation, isFavorite: isFavorite)
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
