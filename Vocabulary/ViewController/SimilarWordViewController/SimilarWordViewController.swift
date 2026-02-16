//
//  SimilarWordViewController.swift
//  Vocabulary
//
//  Created by William Weng on 2026/2/15.
//

import UIKit

// MARK: - 相似字處理
final class SimilarWordViewController: UIViewController {

    @IBOutlet weak var myTableView: UITableView!
    
    weak var mainViewDelegate: MainViewDelegate?
    
    var mainIndexPath: IndexPath = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainViewDelegate?.navigationBarHidden(false)
        mainViewDelegate?.tabBarHidden(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainViewDelegate?.tabBarHidden(false)
    }
    
    @IBAction func appendWord(_ sender: UIBarButtonItem) {
        appendTextHint(with: nil)
    }
    
    deinit {
        mainViewDelegate = nil
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SimilarWordViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return SimilarWordCell.words.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return similarWordCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { return UISwipeActionsConfiguration(actions: trailingSwipeActionsMaker(with: indexPath)) }
}

// MARK: - 小工具
private extension SimilarWordViewController {
    
    /// 初始化設定
    func initSetting() {
        SimilarWordCell.words = MainTableViewCell.similarWords(with: mainIndexPath)
        myTableView._delegateAndDataSource(with: self)
    }
    
    /// 產生SimilarWordCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: SimilarWordCell
    func similarWordCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> SimilarWordCell {
        
        let cell = tableView._reusableCell(at: indexPath) as SimilarWordCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 右側滑動按鈕 => 設定音標 / 複製單字
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIContextualAction]
    func trailingSwipeActionsMaker(with indexPath: IndexPath) -> [UIContextualAction] {
        
        let updateAction = UIContextualAction._build(with: "更新", color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)) { [weak self] in
            guard let this = self else { return }
            this.appendTextHint(with: indexPath)
        }
        
        let copyAction = UIContextualAction._build(with: "刪除", color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)) { [weak self] in
            
            guard let this = self else { return }
            
            SimilarWordCell.words.remove(at: indexPath.row)
            this.myTableView.deleteRows(at: [indexPath], with: .automatic)
            this.updateDatabase(with: this.mainIndexPath) ? Utility.shared.flashHUD(with: .success) : Utility.shared.flashHUD(with: .fail)
        }
        
        return [updateAction, copyAction]
    }
    
    /// 新增 / 更新文字的提示框
    /// - Parameters:
    ///   - indexPath: IndexPath?
    func appendTextHint(with indexPath: IndexPath?) {
        
        var similarWord: SimilarWord?
        
        if let indexPath = indexPath, let _similarWord = SimilarWordCell.words[safe: indexPath.row] { similarWord = _similarWord }
        
        let alertController = UIAlertController._build(title: "請輸入相似字", message: nil)
        
        alertController.addTextField {
            
            $0.placeholder = "相似字"
            
            if let similarWord = similarWord {
                $0.text = similarWord.word
                $0.textColor = .red
                $0.isEnabled = false
            }
        }
        
        alertController.addTextField {
            $0.text = "\(similarWord?.level ?? 5)"
            $0.keyboardType = .numberPad
            $0.placeholder = "等級"
        }
        
        let actionCancel = UIAlertAction(title: "取消", style: .cancel)
        let actionOK = UIAlertAction(title: "確認", style: .destructive) { [unowned self] _ in appendTextAction(alertController: alertController, for: indexPath) }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true)
    }
    
    /// 新增 / 更新文字
    /// - Parameters:
    ///   - alertController: UIAlertController
    ///   - indexPath: IndexPath?
    func appendTextAction(alertController: UIAlertController, for indexPath: IndexPath?) {
        
        guard let wordTextField = alertController.textFields?.first,
              let levelTextField = alertController.textFields?.last,
              let word = wordTextField.text?._removeWhiteSpacesAndNewlines(),
              let level = levelTextField.text?._removeWhiteSpacesAndNewlines()
        else {
            return Utility.shared.flashHUD(with: .fail)
        }
        
        let levelNumber = Int(level) ?? 5
        
        if let indexPath = indexPath {
            SimilarWordCell.words[indexPath.row] = .init(word: word, level: levelNumber)
        } else {
            SimilarWordCell.words.append(.init(word: word, level: levelNumber))
        }
        
        updateDatabase(with: mainIndexPath) ? Utility.shared.flashHUD(with: .success) : Utility.shared.flashHUD(with: .fail)
        myTableView.reloadData()
    }
    
    /// 更新資料庫 + 暫存
    /// - Parameter mainIndexPath: IndexPath
    /// - Returns: Bool
    func updateDatabase(with mainIndexPath: IndexPath) -> Bool {
        
        guard let vocabularyList = MainTableViewCell.vocabularyList(with: mainIndexPath),
              let info = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return false
        }
        
        defer { mainViewDelegate?.reloadRow(with: mainIndexPath) }
        
        var dict: [String: Int] = [:]
        SimilarWordCell.words.forEach { dict[$0.word] = $0.level }
        
        if let similar = dict._jsonString() {
            Utility.shared.updateSimilarWordDictionary(similar, with: mainIndexPath)
            return API.shared.updateSimilarWordToList(vocabularyList.id, similar: similar, info: info)
        }
                
        return false
    }
}
