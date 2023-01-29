//
//  MainViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import WWPrint
import WWSQLite3Manager
import WWHUD

// MARK: - MainViewDelegate
protocol MainViewDelegate {
    func deleteRow(with indexPath: IndexPath)
    func levelMenu(with indexPath: IndexPath)
    func updateCountLabel(with indexPath: IndexPath, count: Int)
}

// MARK: - 單字頁面
final class MainViewController: UIViewController {
    
    enum ViewSegueType: String {
        case listTableView = "ListTableViewSegue"
        case volumeView = "VolumeViewSegue"
    }
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var dictionaryButtonItem: UIBarButtonItem!
    @IBOutlet weak var volumeButtonItem: UIBarButtonItem!

    private var refreshControl: UIRefreshControl!
    private var isAnimationStop = false
    private var disappearImage: UIImage?
    private var currentScrollDirection: Constant.ScrollDirection = .down
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initDatabase()
        initSetting()
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
        case .volumeView:
                        
            guard let viewController = segue.destination as? VolumeViewController else { return }
            viewController._transparent(.black.withAlphaComponent(0.3))
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    deinit { wwPrint("\(Self.self) deinit") }
    
    @objc func refreshVocabularyList(_ sender: UIRefreshControl) { reloadVocabulary() }
    
    @IBAction func appendWrodAction(_ sender: UIBarButtonItem) {
        
        appendTextHint(title: "請輸入單字") { [weak self] inputWord in
            guard let this = self else { return false }
            return this.appendWord(inputWord, for: Constant.currentTableName)
        }
    }
    
    @IBAction func selectDictionaryAction(_ sender: UIBarButtonItem) {
        // dictionaryMenu()
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarController?._tabrBarHidden(true, animated: true)
    }
    
    @IBAction func selectBackgroundMusic(_ sender: UIBarButtonItem) {
        // backgroundMusicMenu()
        navigationController?.setNavigationBarHidden(false, animated: true)
        tabBarController?._tabrBarHidden(false, animated: false)
    }
    
    @IBAction func selectVolume(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: ViewSegueType.volumeView.rawValue, sender: nil)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MainTableViewCell.vocabularyListArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as MainTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: ViewSegueType.listTableView.rawValue, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let direction = scrollView._direction()
        if (direction == currentScrollDirection) { return }
        
        switch direction {
        case .up: tabBarController?._tabrBarHidden(true, animated: true)
        case .down: tabBarController?._tabrBarHidden(false, animated: true)
        case .left , .right ,.none: break
        }
        
        currentScrollDirection = direction
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        updateVocabularyList(for: scrollView)
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension MainViewController: UIPopoverPresentationControllerDelegate {}

// MARK: - MainViewDelegate
extension MainViewController: MainViewDelegate {
    
    /// 刪除該列資料
    /// - Parameter indexPath: IndexPath
    func deleteRow(with indexPath: IndexPath) {
        MainTableViewCell.vocabularyListArray.remove(at: indexPath.row)
        myTableView.deleteRows(at: [indexPath], with: .fade)
        titleSetting(with: MainTableViewCell.vocabularyListArray.count)
    }
    
    /// 更新例句數量文字
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - count: 數量
    func updateCountLabel(with indexPath: IndexPath, count: Int) {
        
        guard var dictionary = MainTableViewCell.vocabularyListArray[safe: indexPath.row] else { return }
        
        dictionary["count"] = count
        MainTableViewCell.vocabularyListArray[indexPath.row] = dictionary
        
        myTableView.reloadRows(at: [indexPath], with: .automatic)
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
    
    /// 單字等級選單
    /// - Parameter indexPath: IndexPath
    func levelMenu(with indexPath: IndexPath) {
        
        guard let vocabularyList = MainTableViewCell.vocabularyList(with: indexPath) else { return }
        
        let alertController = UIAlertController(title: "請選擇等級", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }

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
        alertController.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - 小工具
private extension MainViewController {
    
    /// 初始化資料表 / 資料庫
    func initDatabase() {
        
        let result = WWSQLite3Manager.shared.connent(with: Constant.DatabaseName)
        
        switch result {
        case .failure(_): Utility.shared.flashHUD(with: .fail)
        case .success(let database): Constant.database = database
            
            wwPrint(database.fileURL)
            
            Constant.VoiceCode.allCases.forEach { tableName in
                _ = database.create(tableName: tableName.rawValue, type: Vocabulary.self, isOverwrite: false)
                _ = database.create(tableName: tableName.vocabularyList(), type: VocabularyList.self, isOverwrite: false)
            }
        }
    }
    
    /// UITableView的初始化設定
    func initSetting() {
        
        refreshControl = UIRefreshControl._build(target: self, action: #selector(Self.refreshVocabularyList(_:)))
        
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
        myTableView._delegateAndDataSource(with: self)
        
        reloadVocabularyList()
    }
    
    /// 設定標題
    /// - Parameter count: Int
    func titleSetting(with count: Int) {
        title = "\(Constant.Title) - \(count)"
    }
    
    /// 重新讀取單字
    func reloadVocabulary() {
        MainTableViewCell.vocabularyListArray = []
        reloadVocabularyList()
    }
    
    /// [重新讀取單字表](https://medium.com/@daoseng33/我說那個-uitableview-insertrows-uicollectionview-insertitems-呀-56b8758b2efb)
    func reloadVocabularyList() {
        
        defer { refreshControl.endRefreshing() }
        
        MainTableViewCell.vocabularyListArray += API.shared.searchVocabularyList(for: Constant.currentTableName, offset: MainTableViewCell.vocabularyListArray.count)
        
        titleSetting(with: MainTableViewCell.vocabularyListArray.count)
        
        myTableView._reloadData { [weak self] in
            
            guard let this = self,
                  !MainTableViewCell.vocabularyListArray.isEmpty
            else {
                return
            }
            
            this.myTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            Utility.shared.flashHUD(with: .success)
        }
    }
    
    /// 新增單字
    /// - Parameters:
    ///   - word: 單字
    ///   - tableName: 資料表
    /// - Returns: Bool
    func appendWord(_ word: String, for tableName: Constant.VoiceCode) -> Bool {
        
        guard let count = API.shared.insertNewWord(word, for: tableName) else { return false }
        
        guard let listCount = Optional.some(API.shared.searchWordList(word, for: tableName).count),
              listCount > 1
        else {
            return API.shared.insertWordToList(word, for: tableName)
        }
        
        return API.shared.updateWordToList(word, for: tableName, count: count)
    }
    
    /// 更新單字音標
    /// - Parameters:
    ///   - word: 單字
    ///   - alphabet: 音標
    ///   - tableName: 資料庫名稱
    /// - Returns: Bool
    func updateAlphabet(_ id: Int, alphabet: String, for tableName: Constant.VoiceCode) -> Bool {
        return API.shared.updateAlphabetToList(id, alphabet: alphabet, for: tableName)
    }
    
    /// 下滑到底更新資料
    /// - Parameters:
    ///   - scrollView: UIScrollView
    ///   - height: CGFloat
    func updateVocabularyList(for scrollView: UIScrollView, height: CGFloat = 128.0) {
        
        let offset = scrollView.frame.height + scrollView.contentOffset.y - height
        let height = scrollView.contentSize.height
        
        if (offset > height) { reloadVocabularyList() }
    }
    
    /// 新增文字的提示框
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息文字
    ///   - defaultText: 預設文字
    ///   - action: (String) -> Bool
    func appendTextHint(title: String, message: String? = nil, defaultText: String? = nil, action: @escaping (String) -> Bool) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addTextField {
            $0.text = defaultText
            $0.placeholder = title
        }
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            
            guard let this = self,
                  let inputWord = alertController.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            else {
                return
            }
            
            if (!action(inputWord)) { Utility.shared.flashHUD(with: .fail); return }
            this.reloadVocabulary()
        }
        
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 字典選單
    func dictionaryMenu() {

        let alertController = UIAlertController(title: "請選擇字典", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }

        Constant.VoiceCode.allCases.forEach { tableName in
            let action = dictionaryAlertAction(with: tableName)
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        
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
    func backgroundMusicMenu() {

        let alertController = UIAlertController(title: "請選擇背景音樂", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }

        Utility.Music.allCases.forEach { music in
            let action = backgroundMusicAlertAction(with: music)
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 背景音樂選單功能 => 播放音樂
    /// - Parameter music: Utility.Music
    /// - Returns: UIAlertAction
    func backgroundMusicAlertAction(with music: Utility.Music) -> UIAlertAction {
        
        let action = UIAlertAction(title: "\(music)", style: .default) { [weak self] _ in
            
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
            
            this.appendTextHint(title: "請輸入音標", defaultText: vocabularyList.alphabet) { alphabet in
                return this.updateAlphabet(vocabularyList.id, alphabet: alphabet, for: Constant.currentTableName)
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
              let vocabularyList = MainTableViewCell.vocabularyListArray[safe: indexPath.row]?._jsonClass(for: VocabularyList.self)
        else {
            return
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
        
        viewController.vocabularyList = vocabularyList
        viewController.vocabularyListIndexPath = indexPath
        viewController.mainViewDelegate = self
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
}
