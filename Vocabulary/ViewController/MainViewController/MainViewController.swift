//
//  MainViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import WWSQLite3Manager
import WWToast
import WWTipView

// MARK: - MainViewDelegate
protocol MainViewDelegate: NSObject {
    
    func reloadRow(with indexPath: IndexPath)
    func deleteRow(with indexPath: IndexPath)
    func updateCountLabel(with indexPath: IndexPath, count: Int)
    func tabBarHidden(_ isHidden: Bool)
    func navigationBarHidden(_ isHidden: Bool)
}

// MARK: - 單字頁面
final class MainViewController: UIViewController {
    
    enum ViewSegueType: String {
        case listTableView = "ListTableViewSegue"
        case searchView = "SearchViewSegue"
        case wordCardView = "WordCardViewSegue"
        case wordMemoryView = "WordMemoryViewSegue"
        case similarWordView = "SimilarWordSegue"
    }
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var volumeButtonItem: UIBarButtonItem!
    @IBOutlet weak var musicButtonItem: UIBarButtonItem!
    @IBOutlet weak var appendWordButton: UIButton!
    @IBOutlet weak var fakeTabBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    private let appendTextHintTitle = "請輸入單字"
    
    private var titleString: String { Utility.shared.mainViewContrillerTitle(with: Constant.tableNameIndex, default: "字典") }
    private var isAnimationStop = false
    private var isFavorite = false
    private var isNeededUpdate = true
    
    private var currentScrollDirection: Constant.ScrollDirection = .down
    
    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    private var gifImageView: UIImageView?
    private var inputTextField: UITextField?
    private var inputTipView: WWTipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initMenu()
        initTipViewSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatedBackground(with: .studing)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { prepareAction(for: segue, sender: sender) }
    
    @objc func refreshVocabularyList(_ sender: UIRefreshControl) { reloadVocabulary(isFavorite: isFavorite) }
    @objc func vocabularyCount(_ sender: UITapGestureRecognizer) { vocabularyCountAction(for: navigationItem.titleView) }
    
    @IBAction func appendWordAction(_ sender: UIButton) { appendTextHintAction(sender) }
    @IBAction func filterFavorite(_ sender: UIBarButtonItem) { filterFavoriteAction(with: sender) }
    @IBAction func selectVolume(_ sender: UIBarButtonItem) { Utility.shared.adjustmentSoundType(.volume) }
    @IBAction func searchWordAction(_ sender: UIBarButtonItem) { performSegue(for: .searchView, sender: nil) }
    
    deinit {
        MainTableViewCell.vocabularyListArray = []
        NotificationCenter.default._remove(observer: self, name: .viewDidTransition)
        removeGifBlock()
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return MainTableViewCell.vocabularyListArray.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return mainTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { performSegue(for: .listTableView, sender: indexPath) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { tabrBarHidden(with: scrollView); updateHeightPercentAction(with: scrollView, isNeededUpdate: isNeededUpdate) }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { UISwipeActionsConfiguration(actions: leadingSwipeActionsMaker(with: indexPath)) }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension MainViewController: UIPopoverPresentationControllerDelegate {}

// MARK: - UITextFieldDelegate
extension MainViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return autoTipWordsAction(with: textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}

// MARK: - MainViewDelegate
extension MainViewController: MainViewDelegate {
    
    func reloadRow(with indexPath: IndexPath) { myTableView.reloadRows(at: [indexPath], with: .automatic) }
    func deleteRow(with indexPath: IndexPath) { deleteRowAction(with: indexPath) }
    func updateCountLabel(with indexPath: IndexPath, count: Int) { updateCountLabelAction(with: indexPath, count: count) }
    func tabBarHidden(_ isHidden: Bool) { tabBarHiddenAction(isHidden) }
    func navigationBarHidden(_ isHidden: Bool) { navigationBarHiddenAction(isHidden) }
}

// MARK: - MyNavigationControllerDelegate
extension MainViewController: MyNavigationControllerDelegate {
    
    func refreshRootViewController() { reloadVocabulary(isFavorite: isFavorite) }
}

// MARK: - WWTipView.Delegate
extension MainViewController: WWTipView.Delegate {
    
    func tipView(_ tipView: WWTipView, didTouchedIndex index: Int) {
        inputTextField?.text = tipView.texts[safe: index]
        tipView.isHidden = true
        tipView.texts = []
    }
    
    func tipView(_ tipView: WWTipView, status: WWTipView.AnimationStatusType) {}
}

// MARK: - for DeepLink
extension MainViewController {
    
    /// 新增單字的動作
    /// - Parameter defaultText: String?
    func appendWord(with defaultText: String? = nil) {
        
        appendTextHint(title: appendTextHintTitle, defaultText: defaultText) { [weak self] inputWord in
            
            guard let this = self,
                  let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
            else {
                return false
            }
            
            return this.appendWord(inputWord, info: info)
        }
    }
    
    /// 搜尋單字的動作
    /// - Parameter word: String?
    func searchWord(with word: String?) {
        performSegue(for: .searchView, sender: word)
    }
    
    /// 更新APP圖示
    /// - Parameter index: String?
    func alternateIcons(with number: String?) {
        
        guard let number = number,
              let index = Int(number)
        else {
            return
        }
        
        let icons = ["圖示1", "圖示2", "圖示3", "圖示4"]
        let icon = icons[safe: index]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { UIApplication.shared._alternateIcons(for: icon) { result in myPrint(result) }}
    }
}

// MARK: - 小工具
private extension MainViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        
        refreshControl = UIRefreshControl._build(title: Constant.reload, target: self, action: #selector(Self.refreshVocabularyList(_:)))
        fakeTabBarHeightConstraint.constant = tabBarController?.tabBar.frame.height ?? 0
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        reloadVocabulary(isFavorite: isFavorite)
        viewDidTransitionAction()
        backupDatabaseAction(delay: Constant.autoBackupDelaySecond)
    }
    
    /// 初始化輸入提示框設定
    func initTipViewSetting() {
        
        let inputTipView = WWTipView()
        
        inputTipView.edgeInsets = .init(top: 12, left: 32, bottom: 12, right: 32)
        inputTipView.texts = []
        
        self.inputTipView = inputTipView
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
    /// - Parameter sourceView: UIView?
    func vocabularyCountAction(for sourceView: UIView?) {

        let version = Bundle.main._appVersion()
        let message = "v\(version.app) - \(version.build)"
        let title = "單字數量 - \(vocabularyCount(isFavorite: isFavorite))"
        
        informationHint(with: title, message: message, sourceView: sourceView)
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
        case .searchView: searchWordViewControllerSetting(for: segue, sender: sender)
        case .wordCardView: wordCardControllerSetting(for: segue, sender: sender)
        case .wordMemoryView: wordMemoryViewControllerSetting(for: segue, sender: sender)
        case .similarWordView: similarWordViewControllerSetting(for: segue, sender: sender)
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
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        MainTableViewCell.vocabularyListArray = []
        MainTableViewCell.vocabularyListArray = API.shared.searchVocabularyList(isFavorite: isFavorite, info: info, offset: MainTableViewCell.vocabularyListArray.count)
        
        let listCount = MainTableViewCell.vocabularyListArray.count
        titleSetting(titleString, count: listCount)
        isNeededUpdate = (listCount < Constant.searchCount) ? false : true
        
        myTableView._reloadData() { [weak self] in
            
            guard let this = self,
                  !MainTableViewCell.vocabularyListArray.isEmpty
            else {
                return
            }
            
            this.myTableView._scrollToRow(with: IndexPath(row: 0, section: 0), at: .top) { Utility.shared.flashHUD(with: .success) }
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
    
    /// [設定TabBar顯示與否功能](https://www.jianshu.com/p/4c94fc74f1e6)
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
    
    /// [新增單字列表](https://medium.com/@daoseng33/我說那個-uitableview-insertrows-uicollectionview-insertitems-呀-56b8758b2efb)
    /// - Parameter isFavorite: Bool
    func appendVocabularyList(isFavorite: Bool) {
        
        defer { refreshControl.endRefreshing() }
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        let oldListCount = MainTableViewCell.vocabularyListArray.count
        MainTableViewCell.vocabularyListArray += API.shared.searchVocabularyList(isFavorite: isFavorite, info: info, offset: oldListCount)
        
        let newListCount = MainTableViewCell.vocabularyListArray.count
        titleSetting(titleString, count: newListCount)

        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success); return }
        isNeededUpdate = false
    }
    
    /// 新增 / 更新單字
    /// - Parameters:
    ///   - word: 單字
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func appendWord(_ word: String, info: Settings.GeneralInformation) -> Bool {
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              API.shared.insertNewWord(word, info: info)
        else {
            return false
        }
        
        let count = vocabularyDetailListCount(with: word)
        if (count > 1) { return API.shared.updateWordToList(word, info: info, count: count) }
        
        return API.shared.insertWordToList(word, info: info)
    }
    
    /// 更新單字音標
    /// - Parameters:
    ///   - word: 單字
    ///   - alphabet: 音標
    ///   - info: Settings.GeneralInformation
    /// - Returns: Bool
    func updateAlphabetLabel(with indexPath: IndexPath, id: Int, alphabet: String, info: Settings.GeneralInformation) -> Bool {
        
        guard var dictionary = MainTableViewCell.vocabularyListArray[safe: indexPath.row] else { return false }
        
        dictionary["alphabet"] = alphabet
        MainTableViewCell.vocabularyListArray[indexPath.row] = dictionary
        
        return API.shared.updateAlphabetToList(id, alphabet: alphabet, info: info)
    }
    
    /// 新增單字的動作
    /// - Parameter sender: UIButton
    func appendTextHintAction(_ sender: UIButton) {        
        appendWord()
    }
    
    /// 新增文字的提示框 (輸入單字會有單字提示框)
    /// - Parameters:
    ///   - indexPath: 要更新音標時，才會有IndexPath
    ///   - title: 標題
    ///   - message: 訊息文字
    ///   - defaultText: 預設文字
    ///   - action: (String) -> Bool
    func appendTextHint(with indexPath: IndexPath? = nil, title: String, message: String? = nil, defaultText: String? = nil, action: @escaping (String) -> Bool) {
        
        let alertController = UIAlertController._build(title: title, message: message)
        
        alertController.addTextField {
            self.inputTextField = $0
            $0.text = defaultText
            $0.placeholder = title
        }
        
        let actionOK = appendTextAlertAction(with: indexPath, textFields: alertController.textFields, action: action)
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in self.clearInputTipViewSetting() }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
                
        present(alertController, animated: true) {
            
            guard indexPath == nil,
                  let superview = alertController.view.superview,
                  let inputTextField = self.inputTextField,
                  let inputTipView = self.inputTipView
            else {
                return
            }
            
            inputTipView.isHidden = true
            inputTextField.delegate = self
            inputTipView.delegate = self
            inputTipView.display(targetView: superview, at: inputTextField, position: .left(8), textSetting: (textColor: .black, underLineColor: .lightGray, tintColor: .lightText, font: .systemFont(ofSize: 14.0), lines: 1))
        }
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
                  let textField = textFields?.first,
                  let inputWord = textField.text?._removeWhiteSpacesAndNewlines()
            else {
                return
            }
            
            this.clearInputTipViewSetting()
            
            if (!action(inputWord)) { Utility.shared.flashHUD(with: .fail); return }
            if let indexPath = indexPath { this.myTableView.reloadRows(at: [indexPath], with: .automatic); return }
            
            this.reloadVocabulary()
        }
        
        return actionOK
    }
    
    /// 左側滑動按鈕 => 設定同義字
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIContextualAction]
    func leadingSwipeActionsMaker(with indexPath: IndexPath) -> [UIContextualAction] {
        
        let simpleWordEditAction = UIContextualAction._build(with: "同義字", color: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)) { [weak self] in
            self?.performSegue(for: .similarWordView, sender: indexPath)
        }
        
        return [simpleWordEditAction]
    }
    
    /// 右側滑動按鈕 => 設定音標 / 複製單字
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIContextualAction]
    func trailingSwipeActionsMaker(with indexPath: IndexPath) -> [UIContextualAction] {
        
        let updateAction = UIContextualAction._build(with: "音標", color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)) { [weak self] in
            
            guard let this = self,
                  let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
                  let vocabularyList = MainTableViewCell.vocabularyList(with: indexPath)
            else {
                return
            }
            
            this.appendTextHint(with: indexPath, title: "請輸入音標", defaultText: vocabularyList.alphabet) { alphabet in
                return this.updateAlphabetLabel(with: indexPath, id: vocabularyList.id, alphabet: alphabet, info: info)
            }
        }
        
        let copyAction = UIContextualAction._build(with: "複製", color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)) { [weak self] in
            
            guard let this = self,
                  let vocabularyList = MainTableViewCell.vocabularyList(with: indexPath)
            else {
                return
            }
            
            DispatchQueue._GCD {
                UIPasteboard._paste(string: vocabularyList.word)
            } mainAction: {
                let setting = Utility.shared.toastSetting(for: this)
                WWToast.shared.setting(backgroundViewColor: setting.backgroundColor, bottomHeight: setting.height)
                WWToast.shared.makeText(target: this, text: vocabularyList.word)
            }
        }
        
        return [updateAction, copyAction]
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
    
    /// 單字搜尋頁的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func searchWordViewControllerSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? SearchWordViewController,
              let searchText = sender as? String
        else {
            return
        }
        
        viewController.searchText = searchText
    }
    
    /// 單字卡頁面相關設定
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func wordCardControllerSetting(for segue: UIStoryboardSegue, sender: Any?) {
        guard let viewController = segue.destination as? WordCardViewController else { return }
        viewController.mainViewDelegate = self
    }
    
    /// 單字記憶頁面相關設定
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func wordMemoryViewControllerSetting(for segue: UIStoryboardSegue, sender: Any?) {
        guard let viewController = segue.destination as? WordMemoryViewController else { return }
        viewController.mainViewDelegate = self
    }
    
    /// 同義字頁面相關設定
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func similarWordViewControllerSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let indexPath = sender as? IndexPath,
              let viewController = segue.destination as? SimilarWordViewController
        else {
            return
        }
        
        viewController.mainIndexPath = indexPath
        viewController.mainViewDelegate = self
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
        
        navigationBarHidden(isHidden)
        tabBarHiddenAction(isHidden)
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
            Utility.shared.updateScrolledHeightSetting()
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
        case .failure(let error): myPrint(error); return nil
        case .success(let isSuccess): return (!isSuccess) ? nil : musicFolderUrl
        }
    }
    
    /// 背景音樂的資料夾的檔案列表 (單一層 / 不含資料夾 / 不含.DS_Store)
    /// - Returns: [String]?
    func musicFileList() -> [String]? {
        
        guard let musicFolder = musicFolderMaker() else { return nil }
        
        let result = FileManager.default._fileList(with: musicFolder)
        
        switch result {
        case .failure(let error): myPrint(error); return nil
        case .success(let list): 
            
            guard let list = list else { return nil }
            
            let fileList = list.compactMap({ filename -> String? in
                
                let fileUrl = musicFolder.appendingPathComponent(filename)
                let info = FileManager.default._fileExists(with: fileUrl)
                
                if (info.isDirectory) { return nil }
                if (!info.isExist) { return nil }
                if (filename == ".DS_Store") { return nil }
                
                return filename
            })
            
            return fileList
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
                
                let setting = Utility.shared.toastSetting(for: this)
                WWToast.shared.setting(backgroundViewColor: setting.backgroundColor, bottomHeight: setting.height)
                WWToast.shared.makeText(target: this, text: message)
            }
        }
    }
    
    /// 備份資料庫 (以時間命名)
    /// - Returns: Result<Bool, Error>
    func backupDatabase() -> Result<String?, Error> {
        
        guard let databaseUrl = Constant.database?.fileURL,
              let backupUrl = Utility.shared.databaseBackupUrl()
        else {
            return .failure(Constant.CustomError.notOpenURL)
        }
        
        let result = FileManager.default._copyFile(at: databaseUrl, to: backupUrl)
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let isSuccess): return (isSuccess ? .success(backupUrl.lastPathComponent) : .success(nil))
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
        case .failure(let error): myPrint(error); break
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
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let result = API.shared.searchVocabularyCount(info: info, key: key, isFavorite: isFavorite).first,
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
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let result = API.shared.searchWordDetailListCount(word, info: info, key: key).first,
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
    /// - Parameters:
    ///   - title: String?
    ///   - message: String?
    ///   - sourceView: UIView?
    func informationHint(with title: String?, message: String?, sourceView: UIView? = nil) {
        
        let alertController = UIAlertController._build(title: title, message: message)
        let actionOK = UIAlertAction(title: "確認", style: .destructive) { _ in }
        let actionSelectDatabase = UIAlertAction(title: "選擇字典", style: .default) { [unowned self] _ in dictionaryAlertAction(target: self, sourceView: sourceView) }
        let actionWordCard = UIAlertAction(title: "單字卡模式", style: .default) { [unowned self] _ in performSegue(for: .wordCardView, sender: nil) }
        let actionWordMemory = UIAlertAction(title: "記憶模式", style: .default) { [unowned self] _ in performSegue(for: .wordMemoryView, sender: nil) }
        
        alertController.addAction(actionWordCard)
        alertController.addAction(actionWordMemory)
        alertController.addAction(actionSelectDatabase)
        alertController.addAction(actionOK)

        present(alertController, animated: true, completion: nil)
    }
    
    /// 字典選單
    /// - Parameters:
    ///   - target: UIViewController
    ///   - sourceView: UIView?
    func dictionaryAlertAction(target: UIViewController, sourceView: UIView? = nil) {
        
        let alertController = UIAlertController._build(title: "請選擇字典", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        Constant.SettingsJSON.generalInformations.forEach { info in
            let action = dictionaryAlertActionMaker(with: info)
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.sourceView = sourceView
        
        target.present(alertController, animated: true, completion: nil)
    }
    
    /// 產生字典資料庫選單
    /// - Parameter info: Settings.GeneralInformation
    /// - Returns: UIAction
    func dictionaryAlertActionMaker(with info: Settings.GeneralInformation) -> UIAlertAction {
        
        let title = "\(info.code._flagEmoji()) \(info.name)"
        let action = UIAlertAction(title: title, style: .default) { _ in
            Utility.shared.changeDictionary(with: info)
            self.isAnimationStop = true
            self.animatedBackground(with: .studing)
        }
        
        return action
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
    
    /// [初始化音樂選單 (UIMenu)](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/ios-的選單-menu-按鈕-pull-down-button-pop-up-button-2ddab2181ee5)
    /// - Parameter sender: [UIBarButtonItem](https://medium.com/@le821227/uicontextmenu-uimenu-uiaction-de88aeb2bc1e)
    func initMusicItemMenu() {
        
        guard let musicList = musicFileList()?.sorted() else { Constant.musicFileList = nil; return }
        
        var actions = musicList.map({ musicItemMenuActionMaker(filename: $0) })
        
        actions.append(musicItemMenuActionMaker(filename: Constant.MusicLoopType.loop.toString(), musicLoopType: .loop))
        actions.append(musicItemMenuActionMaker(filename: Constant.MusicLoopType.shuffle.toString(), musicLoopType: .shuffle))
        actions.append(musicItemMenuActionMaker(filename: Constant.MusicLoopType.stop.toString(), musicLoopType: .stop))
        
        Constant.musicFileList = musicList
        
        let menu = UIMenu(title: "請選擇背景音樂 (.mp3 / .m4a)", options: .singleSelection, children: actions)
        musicButtonItem.menu = menu
    }
    
    /// 產生音樂選單功能 (隨機 / 靜音)
    /// - Parameters:
    ///   - filename: String
    ///   - type: Constant.MusicLoopType
    /// - Returns: UIAction
    func musicItemMenuActionMaker(filename: String, musicLoopType: Constant.MusicLoopType = .infinity) -> UIAction {
        
        let music = Music(filename: filename)
        let title: String
        
        switch musicLoopType {
        case .infinity: title = "🎶 - \(music.filename)"
        case .loop: title = "🎼 - \(musicLoopType.toString())"
        case .shuffle: title = "🎵 - \(musicLoopType.toString())"
        case .stop: title = "🚫 - \(musicLoopType.toString())"
        }
        
        let action = UIAction(title: title) { [unowned self] _ in
            
            Constant.playingMusicList = []
            _ = MusicHelper.shared.stop()
            
            Task {
                try await Task.sleep(for: .microseconds(250))
                musicItemMenuAction(music: music, musicLoopType: musicLoopType)
            }
        }
        
        return action
    }
    
    /// 各音樂播放選項的功能
    /// - Parameters:
    ///   - music: Music
    ///   - musicLoopType: Constant.MusicLoopType
    func musicItemMenuAction(music: Music, musicLoopType: Constant.MusicLoopType) {
        
        let result = MusicHelper.shared.itemMenuAction(music: music, musicLoopType: musicLoopType)
        
        musicButtonItem.image = result.icon
        volumeButtonItem.image = Utility.shared.volumeIcon(result.isSuccess)
        volumeButtonItem.isEnabled = result.isSuccess
    }
}

// MARK: - GIF動畫設定
private extension MainViewController {
    
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
    
    /// 移除GIF動畫Block
    func removeGifBlock() {
        isAnimationStop = true
        gifImageView?.removeFromSuperview()
        gifImageView = nil
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
        indicatorLabel.text = Utility.shared.updateActivityViewIndicatorTitle(with: percent, isNeededUpdate: isNeededUpdate)
    }
}

// MARK: - 選字提示框設定
private extension MainViewController {
    
    /// 清除輸入提示框的相關設定
    func clearInputTipViewSetting() {
        inputTextField = nil
        inputTipView?.texts = []
    }
    
    /// 自動完成已輸入過的單字
    /// - Parameters:
    ///   - textField: UITextField
    ///   - range: NSRange
    ///   - string: String
    /// - Returns: Bool
    func autoTipWordsAction(with textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex),
              let word = textField._keyInText(shouldChangeCharactersIn: range, replacementString: string)?._removeWhiteSpacesAndNewlines(),
              let vocabularyListArray = Optional.some(Utility.shared.vocabularyListArrayMaker(like: word, searchType: .word, info: info, offset: 0)),
              let vocabularyList = vocabularyListArray._jsonClass(for: [VocabularyList].self)
        else {
            return true
        }
        
        inputTipView?.isHidden = (word.count < 1) || (vocabularyList.isEmpty)
        inputTipView?.texts = vocabularyList.map { $0.word }
        
        return true
    }
}
