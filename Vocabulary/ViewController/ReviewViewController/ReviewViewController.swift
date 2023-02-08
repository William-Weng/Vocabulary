//
//  ReviewViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/25.
//

import UIKit
import WWPrint

// MARK: - 複習單字頁面
final class ReviewViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var speakImageView: UIImageView!
    @IBOutlet weak var answearButton: UIButton!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var interpretLabel: UILabel!
    @IBOutlet weak var refreshQuestionButtonItem: UIBarButtonItem!
    
    private let repeatAnimateLoopCount = 3
    private let solutionViewSegue = "SolutionViewSegue"
    
    private var isNextVocabulary = false
    private var isAnimationStop = false
    private var searchWordCount = 10
    private var speakAnimateLoopCount = 0
    private var disappearImage: UIImage?
    private var reviewWordList: [[String : Any]] = []
    private var reviewWordDetailList: [[String : Any]] = []
    private var vocabularyList: VocabularyList?
    private var vocabularyArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initReviewWordList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatedBackground(with: .working)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? SolutionViewController,
              let words = sender as? [String]
        else {
            return
        }
        
        viewController.words = words
    }
    
    deinit { wwPrint("\(Self.self) deinit") }
    
    @objc func guessVocabulary(_ tapGesture: UITapGestureRecognizer) { speakVocabularyAction() }
    
    @IBAction func guessAnswear(_ sender: UIButton) { answearAction() }
    @IBAction func reviewSolution(_ sender: UIBarButtonItem) { performSegue(withIdentifier: solutionViewSegue, sender: vocabularyArray) }
    @IBAction func refreshQuestion(_ sender: UIBarButtonItem) { initReviewWordList(); Utility.shared.flashHUD(with: .nice) }
}

// MARK: - MyNavigationControllerDelegate
extension ReviewViewController: MyNavigationControllerDelegate {
    func refreshRootViewController() { initReviewWordList() }
}

// MARK: - 小工具
private extension ReviewViewController {
    
    /// 初始化設定
    func initSetting() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Self.guessVocabulary(_:)))
        speakImageView.addGestureRecognizer(tapGesture)
        
        navigationItem.backBarButtonItem = UIBarButtonItem()
    }
    
    /// 產生猜單字的字組
    /// - Parameter count: 一次要搜尋的單字數量
    func initReviewWordList(count: Int = 10) {
        
        initTitle(with: "單字複習")
        
        isNextVocabulary = true
        isNextVocabulary = true
        vocabularyArray = []
        answerLabel.text = ""
        interpretLabel.text = ""
        answearButtonStatus(isEnabled: false)
        
        searchWordCount = count
        reviewWordList = API.shared.searchGuessWordList(for: Constant.currentTableName, count: searchWordCount, offset: 0)
        searchWordCount = reviewWordList.count
    }
    
    /// 設定Title
    func initTitle(with text: String?) {
        let label = UILabel()
        label.text = text
        navigationItem.titleView = label
    }
    
    /// 按下語音播放猜單字的動作
    /// - Parameters:
    ///   - type: Utility.HudGifType
    ///   - loopCount: 動畫次數
    func speakVocabularyAction(with type: Utility.HudGifType = .speak, loopCount: Int = 5) {
        
        guard let gifUrl = Bundle.main.url(forResource: type.rawValue, withExtension: nil) else { return }
        
        speakAnimateLoopCount = 0
        isNextVocabulary = false
        speakImageView.isUserInteractionEnabled = false
        answerLabel.text = ""
        answearButtonStatus(isEnabled: false)
        
        _ = speakImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): wwPrint(error)
            case .success(let info):
                
                if (info.index == 0) { this.speakAnimateLoopCount += 1 }
                
                if (this.speakAnimateLoopCount > loopCount) {
                    info.pointer.pointee = true
                    this.speakImageView.image = UIImage(named: "Speak.gif")
                    this.speakImageView.isUserInteractionEnabled = true
                    this.answearButtonStatus(isEnabled: true)
                }
            }
        }
    }
    
    /// 讀出單字
    func playWordSound(with list: VocabularyList?) {
        guard let list = list else { return }
        Utility.shared.speak(string: list.word, voice: Constant.currentTableName)
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
    
    /// 讀出單字
    /// - Parameter vocabularyList: VocabularyList?
    func speakVocabulary(_ vocabularyList: VocabularyList?) {
        
        guard let vocabularyList = vocabularyList else { return }
                
        self.vocabularyList = vocabularyList
        
        playWordSound(with: vocabularyList)
        speakVocabularyAction(with: .speak, loopCount: repeatAnimateLoopCount)
        interpretLabelAction(vocabularyList)
    }
    
    /// 讀出單字時所顯示單字的提示
    /// - Parameter vocabularyList: VocabularyList
    func interpretLabelAction(_ vocabularyList: VocabularyList) {
        
        if (reviewWordDetailList.isEmpty) { reviewWordDetailList = API.shared.searchWordDetailList(vocabularyList.word, for: Constant.currentTableName) }
        
        guard let detailList = reviewWordDetailList.popLast() else { interpretLabel.text = ""; return }
        
        let vocabulary = detailList._jsonClass(for: Vocabulary.self)
        reviewWordDetailList.insert(detailList, at: 0)
        interpretLabel.text = vocabulary?.interpret
    }
    
    /// 新增文字的提示框
    /// - Parameters:
    ///   - indexPath: 要更新音標時，才會有IndexPath
    ///   - title: 標題
    ///   - message: 訊息文字
    ///   - placeholder: 提示字串
    ///   - defaultText: 預設文字
    ///   - action: (String) -> Void
    func answerAlert(_ title: String, message: String? = nil, placeholder: String?, action: @escaping (String) -> Void) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField {
            $0.text = ""
            $0.placeholder = placeholder
        }
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { _ in
            guard let inputWord = alertController.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            action(inputWord)
        }
        
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 設定解答按鍵 / 重新產生題目按鈕的狀態
    /// - Parameter isEnabled: Bool
    func answearButtonStatus(isEnabled: Bool) {
        
        let backgroundColor: UIColor = (!isEnabled) ? .systemGray : .systemRed
        
        answearButton._isEnabled(isEnabled, backgroundColor: backgroundColor)
        refreshQuestionButtonItem.isEnabled = isEnabled
        
        if (reviewWordList.isEmpty) { refreshQuestionButtonItem.isEnabled = true }
    }
    
    /// 讀出要複習的單字語音
    func speakVocabularyAction() {
        
        if (!isNextVocabulary) { speakVocabulary(vocabularyList); return }
                
        guard let examinationList = reviewWordList.popLast(),
              let vocabularyList = examinationList._jsonClass(for: VocabularyList.self)
        else {
            return
        }
        
        let count = searchWordCount - reviewWordList.count
        initTitle(with: "單字複習 - \(count) / \(searchWordCount)")
        speakVocabulary(vocabularyList)
    }
    
    /// 填寫解答之後的動作
    /// - Parameters:
    ///   - word: String
    ///   - vocabularyList: VocabularyList
    func solutionAction(with vocabularyList: VocabularyList, isCorrect: Bool) -> Bool {
                
        isNextVocabulary = true
        answearButtonStatus(isEnabled: false)
        reviewWordDetailList = []
        
        answerLabel.text = vocabularyList.word
        vocabularyArray.append(vocabularyList.word)
        
        _ = API.shared.updateReviewCountToList(vocabularyList.id, count: vocabularyList.review + 1, for: Constant.currentTableName)
        
        let reviewWordList = API.shared.searchReviewWordList(vocabularyList.word, for: Constant.currentTableName)
        
        guard !reviewWordList.isEmpty,
              let list = reviewWordList.first?._jsonClass(for: VocabularyReviewList.self)
        else {
            return API.shared.insertReviewWordToList(vocabularyList.word, for: Constant.currentTableName, isCorrect: isCorrect)
        }
        
        return API.shared.updateReviewResultToList(list, isCorrect: isCorrect, for: Constant.currentTableName)
    }
    
    /// 送出所填寫的解答
    func answearAction() {
        
        guard let vocabularyList = vocabularyList else { return }
        
        answerAlert("解答", placeholder: "請輸入您所聽到的單字") { [weak self] inputWord in
            
            guard let this = self else { return }
            
            var isCorrect = false
            
            defer {
                
                let hudType: Utility.HudGifType = (!isCorrect) ? .shudder : .nice
                
                _ = this.solutionAction(with: vocabularyList, isCorrect: isCorrect)
                
                Utility.shared.flashHUD(with: hudType)
                Utility.shared.levelMenu(target: this, vocabularyList: vocabularyList)
            }
            
            if (vocabularyList.word.lowercased() != inputWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) { isCorrect = false; return }
            isCorrect = true
        }
    }
}
