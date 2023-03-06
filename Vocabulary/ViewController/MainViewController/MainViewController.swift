//
//  MainViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import WWPrint
import WWSQLite3Manager

// MARK: - MainViewDelegate
protocol MainViewDelegate {
    func deleteRow(with indexPath: IndexPath)
    func levelMenu(with indexPath: IndexPath)
    func updateCountLabel(with indexPath: IndexPath, count: Int)
    func tabBarHidden(_ isHidden: Bool)
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
    @IBOutlet weak var dictionaryButtonItem: UIBarButtonItem!
    @IBOutlet weak var volumeButtonItem: UIBarButtonItem!
    @IBOutlet weak var appendWordButton: UIButton!
    @IBOutlet weak var fakeTabBarHeightConstraint: NSLayoutConstraint!
        
    private var isAnimationStop = false
    private var currentScrollDirection: Constant.ScrollDirection = .down

    private var disappearImage: UIImage?
    private var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        updateButtonPositionConstraintNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MainTableViewCell.mainViewDelegate = self
        animatedBackground(with: .studing)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MainTableViewCell.mainViewDelegate = nil
        pauseBackgroundAnimation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
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
    
    @objc func refreshVocabularyList(_ sender: UIRefreshControl) { reloadVocabulary() }
    
    @IBAction func appendWordAction(_ sender: UIButton) {
        
        appendTextHint(title: "請輸入單字") { [weak self] inputWord in
            guard let this = self else { return false }
            return this.appendWord(inputWord, for: Constant.currentTableName)
        }
    }
    
    @IBAction func selectDictionary(_ sender: UIBarButtonItem) { dictionaryMenu(sender) }
    @IBAction func selectBackgroundMusic(_ sender: UIBarButtonItem) { backgroundMusicMenu(sender) }
    @IBAction func selectVolume(_ sender: UIBarButtonItem) { performSegue(for: .volumeView, sender: nil) }
    @IBAction func searchWordAction(_ sender: UIBarButtonItem) { performSegue(for: .searchView, sender: nil) }
    
    deinit {
        MainTableViewCell.vocabularyListArray = []
        MainTableViewCell.mainViewDelegate = nil
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
    func scrollViewDidScroll(_ scrollView: UIScrollView) { tabrBarHidden(with: scrollView) }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { updateVocabularyList(for: scrollView, height: Constant.updateScrolledHeight) }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension MainViewController: UIPopoverPresentationControllerDelegate {}

// MARK: - MainViewDelegate
extension MainViewController: MainViewDelegate {
    
    func deleteRow(with indexPath: IndexPath) { deleteRowAction(with: indexPath) }
    func updateCountLabel(with indexPath: IndexPath, count: Int) { updateCountLabelAction(with: indexPath, count: count) }
    func levelMenu(with indexPath: IndexPath) { levelMenuAction(with: indexPath) }
    func tabBarHidden(_ isHidden: Bool) { tabBarHiddenAction(isHidden) }
}

// MARK: - 小工具
private extension MainViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        
        refreshControl = UIRefreshControl._build(target: self, action: #selector(Self.refreshVocabularyList(_:)))
        fakeTabBarHeightConstraint.constant = self.tabBarController?.tabBar.frame.height ?? 0
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
        
        reloadVocabulary()
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
    
    /// 設定標題
    /// - Parameter count: Int
    func titleSetting(with count: Int) {
        
        let label = UILabel()
        label.text = "我愛背單字 - \(count)"
        
        navigationItem.titleView = label
    }
    
    /// 使用Segue進入下一頁
    /// - Parameter indexPath: IndexPath
    func performSegue(for type: ViewSegueType, sender: Any?) {
        currentScrollDirection = .up
        performSegue(withIdentifier: type.rawValue, sender: sender)
    }
    
    /// 重新讀取單字
    func reloadVocabulary() {
        
        defer { refreshControl.endRefreshing() }
                
        MainTableViewCell.vocabularyListArray = []
        MainTableViewCell.vocabularyListArray = API.shared.searchVocabularyList(for: Constant.currentTableName, offset: MainTableViewCell.vocabularyListArray.count)
        
        titleSetting(with: MainTableViewCell.vocabularyListArray.count)
        
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
        titleSetting(with: MainTableViewCell.vocabularyListArray.count)
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

    /// 單字等級選單功能
    /// - Parameter indexPath: IndexPath
    func levelMenuAction(with indexPath: IndexPath) {
        
        guard let vocabularyList = MainTableViewCell.vocabularyList(with: indexPath) else { return }
        
        let alertController = UIAlertController(title: "請選擇等級", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        let cell = Utility.shared.didSelectedCell(myTableView, with: indexPath) as MainTableViewCell?
        
        Vocabulary.Level.allCases.forEach { level in
            
            let action = UIAlertAction(title: level.value(), style: .default) { [weak self] _ in

                guard let this = self else { return }

                let isSuccess = API.shared.updateLevelToList(vocabularyList.id, level: level, for: Constant.currentTableName)

                if (!isSuccess) { Utility.shared.flashHUD(with: .fail) }
                this.updateLevelLabel(with: indexPath, level: level)
            }
            
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.sourceView = cell?.levelLabel
        
        present(alertController, animated: true, completion: nil)
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
    
    /// [新增單字列表](https://medium.com/@daoseng33/我說那個-uitableview-insertrows-uicollectionview-insertitems-呀-56b8758b2efb)
    func appendVocabularyList() {
        
        defer { refreshControl.endRefreshing() }
        
        let oldListCount = MainTableViewCell.vocabularyListArray.count
        MainTableViewCell.vocabularyListArray += API.shared.searchVocabularyList(for: Constant.currentTableName, offset: oldListCount)
        
        let newListCount = MainTableViewCell.vocabularyListArray.count
        titleSetting(with: newListCount)
        
        let indexPaths = (oldListCount..<newListCount).map { IndexPath(row: $0, section: 0) }
        myTableView._insertRows(at: indexPaths, animation: .automatic, animated: false)
        
        if (newListCount > oldListCount) { Utility.shared.flashHUD(with: .success) }
    }
    
    /// 新增單字
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表
    /// - Returns: Bool
    func appendWord(_ word: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let count = API.shared.insertNewWord(word, for: tableName)?.count else { return false }
        guard API.shared.searchWordDetailList(word, for: tableName).count > 1 else { return API.shared.insertWordToList(word, for: tableName) }
        
        return API.shared.updateWordToList(word, for: tableName, count: count)
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
    
    /// 下滑到底更新資料
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - height: CGFloat
    func updateVocabularyList(for scrollView: UIScrollView, height: CGFloat) {
        
        let contentOffsetY = scrollView.contentOffset.y
        let offset = scrollView.frame.height + contentOffsetY - height
        let contentHeight = scrollView.contentSize.height
        
        if (contentOffsetY < 0) { return }
        if (offset > contentHeight) { appendVocabularyList() }
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
    
    /// 字典選單
    /// - Parameter sender: UIBarButtonItem
    func dictionaryMenu(_ sender: UIBarButtonItem) {

        let alertController = UIAlertController(title: "請選擇字典", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }

        Constant.VoiceCode.allCases.forEach { tableName in
            let action = dictionaryAlertAction(with: tableName)
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = sender
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 字典選單功能 => 切換資料庫
    /// - Parameter tableName: Constant.VoiceCode
    /// - Returns: UIAlertAction
    func dictionaryAlertAction(with tableName: Constant.VoiceCode) -> UIAlertAction {
        
        let title = tableName.flagEmoji()
        let alertTitle = tableName.name()
        
        let action = UIAlertAction(title: alertTitle, style: .default) { [weak self] _ in
            
            guard let this = self else { return }
            
            Constant.currentTableName = tableName
            
            this.dictionaryButtonItem.title = title
            this.reloadVocabulary()
        }
        
        return action
    }
    
    /// 背景音樂選單
    /// - Parameter sender: UIBarButtonItem
    func backgroundMusicMenu(_ sender: UIBarButtonItem) {

        let alertController = UIAlertController(title: "請選擇背景音樂 (.mp3 / .m4a)", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        if var musicList = musicFileList()?.sorted() {
            
            musicList.append("靜音")
            musicList.forEach({ filename in
                
                let music = Music(filename: filename)
                let action = backgroundMusicAlertAction(with: music)
                
                alertController.addAction(action)
            })
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = sender

        present(alertController, animated: true, completion: nil)
    }
    
    /// 背景音樂選單功能 => 播放音樂
    /// - Parameter music: Music
    /// - Returns: UIAlertAction
    func backgroundMusicAlertAction(with music: Music) -> UIAlertAction {
        
        let action = UIAlertAction(title: "\(music.filename)", style: .default) { [weak self] _ in
            
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
    func animatedBackground(with type: Utility.HudGifType) {
        
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
        
        tabBarHidden(isHidden)
        currentScrollDirection = direction
    }
    
    /// 更新appendButton的位置
    func updateButtonPositionConstraintNotification() {
        
        NotificationCenter.default._register(name: .viewDidTransition) { [weak self] notification in
            
            guard let this = self,
                  let isHidden = notification.object as? Bool
            else {
                return
            }
            
            this.currentScrollDirection = .none
            this.appendButtonPositionConstraint(isHidden, duration: Constant.duration)
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
}
