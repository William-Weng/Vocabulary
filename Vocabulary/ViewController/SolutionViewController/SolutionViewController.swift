//
//  SolutionViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/4.
//

import UIKit
import WWPrint

// MARK: - 複習單字解答頁面
final class SolutionViewController: UIViewController {
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var myImageView: UIImageView!
    
    var words: [String] = []
    
    enum ViewSegueType: String {
        case solutionDetail = "SolutionDetailSegue"
        case reviewResult = "ReviewResultViewSegue"
    }
        
    private var isAnimationStop = false
    private var disappearImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        initReviewListArray()
        initSetting()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier,
              let viewSegueType = ViewSegueType(rawValue: identifier)
        else {
            return
        }
        
        switch viewSegueType {
        case .solutionDetail: vocabularyListPageSetting(for: segue, sender: sender)
        case .reviewResult: wwPrint(viewSegueType)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?._tabBarHidden(true, animated: true)
        animatedBackground(with: .solution)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?._tabBarHidden(false, animated: true)
        pauseBackgroundAnimation()
    }
    
    @IBAction func reviewAction(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: ViewSegueType.reviewResult.rawValue, sender: nil)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SolutionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return words.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return solutionTableViewCell(tableView, cellForRowAt: indexPath) }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { performSegue(withIdentifier: ViewSegueType.solutionDetail.rawValue, sender: indexPath) }
}

// MARK: - 小工具
private extension SolutionViewController {
    
    /// UITableView的初始化設定
    func initSetting() {
        
        myTableView._delegateAndDataSource(with: self)
        myTableView.tableFooterView = UIView()
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
    }
    
    /// 初始化複習的單字列表
    func initReviewListArray() {
        if (words.isEmpty) { return }
        SolutionTableViewCell.vocabularyReviewListArray = API.shared.searchVocabularyList(in: words, for: Constant.currentTableName, count: words.count, offset: 0)
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
    
    /// 產生SolutionTableViewCell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: SolutionTableViewCell
    func solutionTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> SolutionTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as SolutionTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 設定單字列表頁的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func vocabularyListPageSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? ListViewController,
              let indexPath = sender as? IndexPath,
              let vocabularyList = SolutionTableViewCell.vocabularyReviewList(with: indexPath)
        else {
            return
        }
        
        viewController.canEdit = false
        viewController.vocabularyList = vocabularyList
        viewController.vocabularyListIndexPath = indexPath
        viewController.mainViewDelegate = nil
    }
}
