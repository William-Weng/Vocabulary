//
//  SentenceViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/6.
//

import UIKit
import SafariServices
import WWPrint

// MARK: - SentenceViewDelegate
protocol SentenceViewDelegate {
    func wordDictionary(with indexPath: IndexPath)
    func tabBarHidden(_ isHidden: Bool)
}

// MARK: - 精選例句
final class SentenceViewController: UIViewController {

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var appendWordButton: UIButton!
    @IBOutlet weak var speechButtonItem: UIBarButtonItem!
    @IBOutlet weak var fakeTabBarHeightConstraint: NSLayoutConstraint!
    
    private let recordingSegue = "RecordingSegue"
    private let licenseWebViewSegue = "LicenseWebViewSegue"

    private var isAnimationStop = false
    private var isFixed = false
    private var isFavorite = false

    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    private var currentScrollDirection: Constant.ScrollDirection = .down
    private var currentSpeech: VocabularySentenceList.Speech? = nil
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
        
        guard let identifier = segue.identifier else { return }
        
        if (identifier == recordingSegue) { talkingViewSetting(for: segue, sender: sender); return }
        if (identifier == licenseWebViewSegue) { licenseViewSetting(for: segue, sender: sender); return }
    }
    
    @objc func refreshSentenceList(_ sender: UIRefreshControl) { translateDisplayArray = []; reloadSentenceList(with: currentSpeech, isFavorite: isFavorite) }
    @objc func sentenceCount(_ sender: UITapGestureRecognizer) { sentenceCountAction() }

    @IBAction func recordingAction(_ sender: UIBarButtonItem) { performSegue(withIdentifier: recordingSegue, sender: nil) }
    @IBAction func licensePage(_ sender: UIBarButtonItem) { performSegue(withIdentifier: licenseWebViewSegue, sender: nil) }
    @IBAction func filterFavorite(_ sender: UIBarButtonItem) { filterFavoriteAction(sender) }
    @IBAction func appendSentenceAction(_ sender: UIButton) {
        
        appendSentenceHint(title: "請輸入例句") { [weak self] (example, translate) in
            guard let this = self else { return false }
            return this.appendSentence(example, translate: translate, for: Constant.currentTableName)
        }
    }
    
    deinit {
        SentenceTableViewCell.sentenceListArray = []
        SentenceTableViewCell.sentenceViewDelegate = nil
        NotificationCenter.default._remove(observer: self, name: .viewDidTransition)
        wwPrint("\(Self.self) deinit")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SentenceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return SentenceTableViewCell.sentenceListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return sentenceTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { translateDisplayAction(tableView, didSelectRowAt: indexPath) }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { tabrBarHidden(with: scrollView) }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { updateSentenceList(for: scrollView, height: Constant.updateScrolledHeight) }
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
        currentSpeech = nil
        reloadSentenceList(with: currentSpeech, isFavorite: isFavorite)
    }
}

// MARK: - 小工具
private extension SentenceViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        SentenceTableViewCell.sentenceViewDelegate = self

        refreshControl = UIRefreshControl._build(title: "重新讀取", target: self, action: #selector(Self.refreshSentenceList(_:)))
        fakeTabBarHeightConstraint.constant = self.tabBarController?.tabBar.frame.height ?? 0
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
        
        reloadSentenceList(with: currentSpeech, isFavorite: isFavorite)
    }
    
    /// 顯示精選例句總數量
    func sentenceCountAction() {
        
        let version = Bundle.main._appVersion()
        let message = "v\(version.app ?? "1.0.0") - \(version.build ?? "0")"
        let title = "精選例句 - \(sentenceCount())"

        informationHint(with: title, message: message)
    }
    
    /// 重新讀取單字
    func reloadSentenceList(with speech: VocabularySentenceList.Speech?, isFavorite: Bool) {
        
        defer {
            appendWordButtonHidden(with: speech, isFavorite: isFavorite)
            refreshControl.endRefreshing()
        }
        
        SentenceTableViewCell.sentenceListArray = []
        SentenceTableViewCell.sentenceListArray = API.shared.searchSentenceList(with: speech, isFavorite: isFavorite, for: Constant.currentTableName, offset: 0)
        
        titleSetting(with: SentenceTableViewCell.sentenceListArray.count)
        
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
    
    /// [新增例句列表](https://medium.com/@daoseng33/我說那個-uitableview-insertrows-uicollectionview-insertitems-呀-56b8758b2efb)
    func appendSentenceList(with speech: VocabularySentenceList.Speech?, isFavorite: Bool) {
        
        defer { refreshControl.endRefreshing() }
        
        let oldListCount = SentenceTableViewCell.sentenceListArray.count
        SentenceTableViewCell.sentenceListArray += API.shared.searchSentenceList(with: speech, isFavorite: isFavorite, for: Constant.currentTableName, offset: oldListCount)
        
        let newListCount = SentenceTableViewCell.sentenceListArray.count
        titleSetting(with: newListCount)
        
        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success) }
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
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let navigationBarHeight = navigationController?._navigationBarHeight(for: appDelegate?.window) ?? .zero
        
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
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

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
                  let inputExampleText = textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let inputTranslateText = textFields?.last?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
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
            this.reloadSentenceList(with: this.currentSpeech, isFavorite: this.isFavorite)
        }
        
        return actionOK
    }
    
    /// 新增例句
    /// - Parameters:
    ///   - example: 例句
    ///   - tableName: 翻譯
    /// - Returns: Bool
    func appendSentence(_ example: String, translate: String, for tableName: Constant.VoiceCode) -> Bool {
        return API.shared.insertSentenceToList(example, translate: translate, for: Constant.currentTableName)
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
        if (offset > contentHeight) { appendSentenceList(with: currentSpeech, isFavorite: isFavorite) }
    }
        
    /// 更新例句 (句子 / 翻譯)
    /// - Parameter indexPath: IndexPath
    func updateSentence(with indexPath: IndexPath) {
        
        guard let sentenceList = SentenceTableViewCell.sentenceList(with: indexPath) else { return }
        
        appendSentenceHint(with: indexPath, title: "請更新例句", exampleText: sentenceList.example, translateText: sentenceList.translate) { (exampleInput, translateInput) in
            
            guard var dictionary = SentenceTableViewCell.sentenceListArray[safe: indexPath.row] else { return false }
            
            dictionary["example"] = exampleInput
            dictionary["translate"] = translateInput
            SentenceTableViewCell.sentenceListArray[indexPath.row] = dictionary
            
            return API.shared.updateSentenceToList(sentenceList.id, example: exampleInput, translate: translateInput, for: Constant.currentTableName)
        }
    }
    
    /// 刪除例句
    /// - Parameter indexPath: IndexPath
    func deleteSentence(with indexPath: IndexPath) {
        
        guard let sentenceList = SentenceTableViewCell.sentenceList(with: indexPath) else { return }
        
        let isSuccess = API.shared.deleteSentenceList(with: sentenceList.id, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        SentenceTableViewCell.sentenceListArray.remove(at: indexPath.row)
        titleSetting(with: SentenceTableViewCell.sentenceListArray.count)
        
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
    
    /// 設定錄音頁面
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func talkingViewSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? TalkingViewController else { return }
        
        viewController._transparent(.black.withAlphaComponent(0.3))
        tabBarHiddenAction(true)
    }
    
    /// 版權頁設定
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func licenseViewSetting(for segue: UIStoryboardSegue, sender: Any?) {
        guard let webViewController = segue.destination as? LicenseWebViewController else { return }
        webViewController.sentenceViewDelegate = self
    }
    
    /// 取得精選例句總數量
    /// - Returns: Int
    func sentenceCount() -> Int {
        
        let key = "speech"
        let field = "\(key)Count"
        
        guard let result = API.shared.searchSentenceCount(for: Constant.currentTableName, key: key).first,
              let value = result["\(field)"],
              let count = Int("\(value)", radix: 10)
        else {
            return 0
        }
                
        return count
    }
    
    /// 設定標題
    /// - Parameter count: Int
    func titleSetting(with count: Int) {
        
        let title = "精選例句 - \(count)"
        
        guard let titleView = navigationItem.titleView as? UILabel else { titleViewSetting(with: title); return }
        titleView.text = title
    }
    
    /// 標題文字相關設定
    /// - Parameter word: String
    func titleViewSetting(with title: String) {
        
        let titleView = Utility.shared.titleLabelMaker(with: title)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(Self.sentenceCount(_:)))
        
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(gesture)
        
        navigationItem.titleView = titleView
    }
    
    /// 顯示版本 / 精選例句數量訊息
    func informationHint(with title: String?, message: String?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
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
        sender.image = (!isFavorite) ? UIImage(imageLiteralResourceName: "Notice_Off") : UIImage(imageLiteralResourceName: "Notice_On")
        reloadSentenceList(with: currentSpeech, isFavorite: isFavorite)
    }
    
    /// 設定新增例句按鍵是否顯示
    func appendWordButtonHidden(with speech: VocabularySentenceList.Speech?, isFavorite: Bool) {
        
        var isHidden = false
        
        if (isFavorite) { isHidden = true }
        if (speech != nil) { isHidden = true }

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
                
        let action = speechItemMenuActionMaker(speech: nil)
        var actions = VocabularySentenceList.Speech.allCases.map { speechItemMenuActionMaker(speech: $0) }
        
        actions.insert(action, at: 0)
        
        let menu = UIMenu(title: "請選擇例句屬性", children: actions)
        
        speechButtonItem.menu = menu
    }
    
    /// 產生字典資料庫選單
    /// - Parameter tableName: Constant.VoiceCode
    /// - Returns: UIAction
    func speechItemMenuActionMaker(speech: VocabularySentenceList.Speech?) -> UIAction {
        
        let title = speech?.value() ?? "全部"
        
        let action = UIAction(title: title) { [weak self] _ in
            
            guard let this = self else { return }
            
            this.currentSpeech = speech
            this.fixTranslateDisplayArray(with: IndexPath(row: 0, section: 0), type: .search)
            this.reloadSentenceList(with: speech, isFavorite: this.isFavorite)
        }
        
        return action
    }
}
