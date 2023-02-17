//
//  ViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import SafariServices
import WWPrint
import WWSQLite3Manager
import WWHUD

// MARK: - ListViewDelegate
protocol ListViewDelegate {
    func speechMenu(with indexPath: IndexPath)
}

// MARK: - 單字列表
final class ListViewController: UIViewController {

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    
    var canDelete = false
    var vocabularyListIndexPath: IndexPath!
    var vocabularyList: VocabularyList!
    var mainViewDelegate: MainViewDelegate?
    
    private var isAnimationStop = false
    private var isSafariViewControllerDismiss = true
    private var refreshControl: UIRefreshControl!
    private var disappearImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ListTableViewCell.listViewDelegate = self
        animatedBackground(with: .reading)
        mainViewDelegate?.tabBarHidden(true)
        
        if (!canDelete) { tabBarController?._tabBarHidden(true, animated: true) }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        ListTableViewCell.listViewDelegate = nil
        pauseBackgroundAnimation()
        updateExampleCount(ListTableViewCell.exmapleList.count)
        
        if (!isSafariViewControllerDismiss) { return }
        tabBarController?.tabBar.isHidden = false
        mainViewDelegate?.tabBarHidden(false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        talkingViewSetting(for: segue, sender: sender)
    }
    
    deinit {
        ListTableViewCell.exmapleList = []
        ListTableViewCell.listViewDelegate = nil
        wwPrint("\(Self.self) deinit")
    }
    
    @IBAction func dictionaryNet(_ sender: UIBarButtonItem) { netDictionary(with: vocabularyList.word) }
    @IBAction func refreshVocabularyList(_ sender: UIRefreshControl) { reloadExampleList() }
    @IBAction func recordingAction(_ sender: UIBarButtonItem) { performSegue(withIdentifier: "RecordingWaveSegue", sender: nil) }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return ListTableViewCell.exmapleList.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return listTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
}

// MARK: - SFSafariViewControllerDelegate
extension ListViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        isSafariViewControllerDismiss = true
    }
}

// MARK: - ListViewDelegate
extension ListViewController: ListViewDelegate {
    
    func speechMenu(with indexPath: IndexPath) { speechMenuAction(with: indexPath) }
}

// MARK: - 小工具
private extension ListViewController {
    
    /// 初始化單字列表
    func initSetting() {
        
        title = vocabularyList.word
        
        refreshControl = UIRefreshControl._build(target: self, action: #selector(Self.refreshVocabularyList(_:)))
        
        myTableView.addSubview(refreshControl)
        myTableView.tableFooterView = UIView()
        myTableView._delegateAndDataSource(with: self)
        
        reloadExampleList()
    }
    
    /// 重新讀取單字列表
    func reloadExampleList() {
        
        ListTableViewCell.exmapleList = API.shared.searchWordDetailList(vocabularyList.word, for: Constant.currentTableName)
                
        myTableView.reloadData()
        emptyExampleListAction()
    }
    
    /// 產生ListTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: ListTableViewCell
    func listTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> ListTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as ListTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 更新Cell的Label文字
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - speech: 詞性
    ///   - info: 相關文字
    func updateCellLabel(with indexPath: IndexPath, speech: Vocabulary.Speech?, info: Constant.ExampleInfomation?) {
        
        guard var dictionary = ListTableViewCell.exmapleList[safe: indexPath.row] else { return }
        
        if let speech = speech { dictionary["speech"] = speech.rawValue }
        
        if let info = info {
            dictionary["example"] = info.example
            dictionary["interpret"] = info.interpret
            dictionary["translate"] = info.translate
        }
        
        ListTableViewCell.exmapleList[indexPath.row] = dictionary
        
        myTableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    /// 單字網路字典
    /// - Parameter word: 單字
    func netDictionary(with word: String) {
        
        guard let url = URL._standardization(string: Constant.currentTableName.dictionaryURL(with: word)) else { return }
        
        isSafariViewControllerDismiss = false
        
        let safariController = url._openUrlWithInside(delegate: self)
        safariController.delegate = self
    }
    
    /// 單字詞性選單功能
    /// - Parameter indexPath: IndexPath
    func speechMenuAction(with indexPath: IndexPath) {
        
        guard let vocabulary = ListTableViewCell.vocabulary(with: indexPath) else { return }
                
        let alertController = UIAlertController(title: "請選擇詞性", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }

        Vocabulary.Speech.allCases.forEach { speech in
            let action = speechAlertAction(with: indexPath, speech: speech, vocabulary: vocabulary)
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 新增文字的提示框
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息文字
    ///   - indexPath: IndexPath
    ///   - action: (Constant.ExampleInfomation) -> Bool
    func appendTextHint(with indexPath: IndexPath, title: String, message: String? = nil, action: @escaping (Constant.ExampleInfomation) -> Bool) {
        
        guard let vocabulary = ListTableViewCell.vocabulary(with: indexPath) else { return }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { $0.text = vocabulary.interpret; $0.placeholder = "請輸入單字翻譯" }
        alertController.addTextField { $0.text = vocabulary.example; $0.placeholder = "請輸入相關例句" }
        alertController.addTextField { $0.text = vocabulary.translate; $0.placeholder = "請輸入例句翻譯" }
        
        let actionOK = appendTextAlertAction(with: indexPath, textFields: alertController.textFields, vocabulary: vocabulary, action: action)
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 新增文字功能 => 解釋 / 例句 / 翻譯
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - textFields: [UITextField]?
    ///   - vocabulary: Vocabulary
    ///   - action: (Constant.ExampleInfomation) -> Bool
    /// - Returns: UIAlertAction
    func appendTextAlertAction(with indexPath: IndexPath, textFields: [UITextField]?, vocabulary: Vocabulary, action: @escaping (Constant.ExampleInfomation) -> Bool) -> UIAlertAction {
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            
            guard let this = self,
                  let textFields = textFields,
                  let interpret = textFields.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let example = textFields[safe: 1]?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let translate = textFields.last?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            else {
                return
            }
            
            let info = Constant.ExampleInfomation(vocabulary.id, interpret, example, translate)
            
            if (!action(info)) { Utility.shared.flashHUD(with: .fail); return }
            this.updateCellLabel(with: indexPath, speech: nil, info: info)
        }
        
        return actionOK
    }
    
    /// 單字詞性選單功能
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - speech: Vocabulary.Speech
    ///   - vocabulary: Vocabulary
    func speechAlertAction(with indexPath: IndexPath, speech: Vocabulary.Speech, vocabulary: Vocabulary) -> UIAlertAction {
        
        let action = UIAlertAction(title: speech.value(), style: .default) { [weak self] _ in
            
            guard let this = self else { return }
            
            let isSuccess = API.shared.updateSpeechToList(vocabulary.id, speech: speech, for: Constant.currentTableName)
            
            if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
            this.updateCellLabel(with: indexPath, speech: speech, info: nil)
        }
        
        return action
    }
    
    /// 右側滑動按鈕
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIContextualAction]
    func trailingSwipeActionsMaker(with indexPath: IndexPath) -> [UIContextualAction] {
        
        let updateAction = UIContextualAction._build(with: "更新", color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)) { [weak self] in
            
            guard let this = self else { return }
            
            this.appendTextHint(with: indexPath, title: "請輸入相關文字") { info in
                return API.shared.updateExmapleToList(info.id, info: info, for: Constant.currentTableName)
            }
        }
        
        let deleteAction = UIContextualAction._build(with: "刪除", color: #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)) { [weak self] in
            
            guard let this = self,
                  let vocabulary = ListTableViewCell.vocabulary(with: indexPath)
            else {
                return
            }
            
            let isSuccess = API.shared.deleteWord(with: vocabulary.id, for: Constant.currentTableName)
            if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
            
            ListTableViewCell.exmapleList.remove(at: indexPath.row)
            
            this.myTableView.deleteRows(at: [indexPath], with: .fade)
            this.emptyExampleListAction()
        }
        
        if (!canDelete) { return [updateAction] }
        return [updateAction, deleteAction]
    }
    
    /// 動畫背景設定
    /// - Parameter type: Utility.HudGifType
    func animatedBackground(with type: Utility.HudGifType) {
        
        guard let gifUrl = type.fileURL() else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl, options: nil) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): wwPrint(error)
            case .success(let info):
                info.pointer.pointee = this.isAnimationStop
                if (this.isAnimationStop) { this.myImageView.image = this.disappearImage }
            }
        }
    }
    
    /// 沒資料時的反應 => 回到上一頁
    func emptyExampleListAction() {
        
        var isSuccess = false
        
        defer {
            let hudGifType: Utility.HudGifType = !isSuccess ? .fail : .success
            Utility.shared.flashHUD(with: hudGifType)
        }
        
        if (!ListTableViewCell.exmapleList.isEmpty) {
            isSuccess = true
            refreshControl.endRefreshing(); return
        }
        
        isSuccess = API.shared.deleteWordList(with: vocabularyList.id, for: Constant.currentTableName)
        mainViewDelegate?.deleteRow(with: vocabularyListIndexPath)
        navigationController?.popViewController(animated: true)
    }
    
    /// 暫停背景動畫
    func pauseBackgroundAnimation() {
        disappearImage = myImageView.image
        isAnimationStop = true
    }
    
    /// 更新主頁單字範圍數量
    /// - Parameter count: Int
    func updateExampleCount(_ count: Int) {
        
        if (ListTableViewCell.exmapleList.isEmpty) { return }
        
        let count = ListTableViewCell.exmapleList.count
        let isSuccess = API.shared.updateWordToList(vocabularyList.word, for: Constant.currentTableName, count: count, hasUpdateTime: false)
        
        if (isSuccess) { mainViewDelegate?.updateCountLabel(with: vocabularyListIndexPath, count: count) }
    }
    
    /// 設定錄音頁面
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func talkingViewSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? TalkingViewController else { return }
        
        viewController._transparent(.black.withAlphaComponent(0.3))
        tabBarController?._tabBarHidden(true, animated: true)
    }
}
