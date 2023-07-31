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
import WWFloatingViewController

// MARK: - 單字列表
final class ListViewController: UIViewController {

    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    
    var canDelete = false
    var vocabularyListIndexPath: IndexPath!
    var vocabularyList: VocabularyList!
    var mainViewDelegate: MainViewDelegate?
    
    private let recordingWaveSegue = "RecordingWaveSegue"
    
    private var isAnimationStop = false
    private var isSafariViewControllerDismiss = true
    private var refreshControl: UIRefreshControl!
    private var disappearImage: UIImage?
    private var translateDisplayArray: Set<Int> = []
    private var searchVocabularyViewController: SearchVocabularyViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearAction(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearAction(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        talkingViewSetting(for: segue, sender: sender)
    }
    
    @objc func defineVocabulary(_ sender: UITapGestureRecognizer) {
        defineVocabularyAction(with: vocabularyList.word)
    }
    
    @IBAction func dictionaryNet(_ sender: UIBarButtonItem) { netDictionary(with: vocabularyList.word) }
    @IBAction func refreshVocabularyList(_ sender: UIRefreshControl) { reloadExampleList() }
    @IBAction func recordingAction(_ sender: UIBarButtonItem) { performSegue(withIdentifier: recordingWaveSegue, sender: nil) }
    
    @IBAction func searchVocabulary(_ sender: UIButton) {
        searchVocabularyViewController = UIStoryboard._instantiateViewController() as SearchVocabularyViewController
        presentSearchVocabularyViewController(with: searchVocabularyViewController?.view)
    }
    
    deinit {
        ListTableViewCell.exmapleList = []
        wwPrint("\(Self.self) deinit", isShow: Constant.isPrint)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return ListTableViewCell.exmapleList.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return listTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { translateDisplayAction(tableView, didSelectRowAt: indexPath) }
}

// MARK: - SFSafariViewControllerDelegate
extension ListViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) { isSafariViewControllerDismiss = true }
}

// MARK: - 小工具
private extension ListViewController {
    
    /// 初始化單字列表
    func initSetting() {
                
        titleViewSetting(with: vocabularyList.word)
        
        refreshControl = UIRefreshControl._build(title: Constant.reload, target: self, action: #selector(Self.refreshVocabularyList(_:)))
        
        myTableView.addSubview(refreshControl)
        myTableView._delegateAndDataSource(with: self)
        
        reloadExampleList()
    }
    
    /// 標題文字相關設定
    /// - Parameter word: String
    func titleViewSetting(with word: String) {
        
        let titleView = Utility.shared.titleLabelMaker(with: word)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(Self.defineVocabulary(_:)))
        
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(gesture)
        navigationItem.titleView = titleView
    }
    
    /// 重新讀取單字列表
    func reloadExampleList() {
        
        ListTableViewCell.exmapleList = API.shared.searchWordDetailList(vocabularyList.word, for: Constant.currentTableName)
        
        translateDisplayArray = []
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
        cell.translateLabel.textColor = (!translateDisplayArray.contains(indexPath.row)) ? .clear : .darkGray
        cell.interpretLabel.textColor = (!translateDisplayArray.contains(indexPath.row)) ? .clear : .label
        
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
        
        let url = URL._standardization(string: Constant.currentTableName.dictionaryURL(with: word))
        openUrlWithInside(with: url)
    }
    
    /// 尋找單字定義
    /// - Parameter word: 單字
    func defineVocabularyAction(with word: String) {
        
        let url = URL._standardization(string: Constant.currentTableName.defineVocabularyURL(with: word))
        openUrlWithInside(with: url)
    }
    
    /// 開啟SafariController
    /// - Parameter url: URL?
    func openUrlWithInside(with url: URL?) {
        
        guard let url = url else { return }
        
        isSafariViewControllerDismiss = false
        
        let safariController = url._openUrlWithInside(delegate: self)
        safariController.delegate = self
    }
    
    /// View將要顯示時的動作
    /// - Parameter animated: Bool
    func viewWillAppearAction(_ animated: Bool) {
                
        animatedBackground(with: .reading)
        mainViewDelegate?.navigationBarHidden(false)
        mainViewDelegate?.tabBarHidden(true)

        if (!canDelete) { tabBarController?._tabBarHidden(true, animated: true) }
    }
    
    /// View將要消失時的動作
    /// - Parameter animated: Bool
    func viewWillDisappearAction(_ animated: Bool) {
                
        pauseBackgroundAnimation()
        updateExampleCount(ListTableViewCell.exmapleList.count)
        
        if (!isSafariViewControllerDismiss) { return }
        mainViewDelegate?.navigationBarHidden(false)
        mainViewDelegate?.tabBarHidden(false)
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
                  let interpret = textFields.first?.text?._removeWhiteSpacesAndNewlines(),
                  let example = textFields[safe: 1]?.text?._removeWhiteSpacesAndNewlines(),
                  let translate = textFields.last?.text?._removeWhiteSpacesAndNewlines()
            else {
                return
            }
            
            let info = Constant.ExampleInfomation(vocabulary.id, interpret, example, translate)
            
            if (!action(info)) { Utility.shared.flashHUD(with: .fail); return }
            
            this.fixTranslateDisplayArray(with: indexPath, type: .update)
            this.updateCellLabel(with: indexPath, speech: nil, info: info)
        }
        
        return actionOK
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
            this.fixTranslateDisplayArray(with: indexPath, type: .delete)
            this.emptyExampleListAction()
        }
        
        if (!canDelete) { return [updateAction] }
        return [updateAction, deleteAction]
    }
    
    /// 動畫背景設定
    /// - Parameter type: Utility.HudGifType
    func animatedBackground(with type: Constant.HudGifType) {
        
        guard let gifUrl = type.fileURL() else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl, options: nil) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): wwPrint(error, isShow: Constant.isPrint)
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
            let hudGifType: Constant.HudGifType = !isSuccess ? .fail : .success
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
    
    /// 更新主頁單字數量
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
        case .update:
            _translateDisplayArray = Array(self.translateDisplayArray)
            _translateDisplayArray.append(indexPath.row)
        case .delete:
            _translateDisplayArray = self.translateDisplayArray.compactMap { ($0 > indexPath.row) ? ($0 - 1) : nil }
        case .append, .search:
            break
        }
        
        self.translateDisplayArray = Set(_translateDisplayArray)
    }
    
    /// 產生WWFloatingViewController
    /// - Parameter currentView: UIView?
    func presentSearchVocabularyViewController(with currentView: UIView?) {
        
        let floatingViewController = WWFloatingView.shared.maker()
        floatingViewController.configure(animationDuration: 0.25, backgroundColor: .clear, multiplier: 0.55, completePercent: 0.5, currentView: currentView)
        
        present(floatingViewController, animated: false)
    }
}

