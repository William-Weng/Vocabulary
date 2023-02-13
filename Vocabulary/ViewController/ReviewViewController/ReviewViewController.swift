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
    
    private let solutionViewSegue = "SolutionViewSegue"
    
    private var isNextVocabulary = false
    private var isAnimationStop = false
    private var repeatAnimateLoopCount = 3
    private var searchWordCount = 10
    private var speakAnimateLoopCount = 0
    private var questionLevel: Constant.QuestionLevel = .read
    
    private var reviewWordList: [[String : Any]] = []
    private var reviewWordDetailList: [[String : Any]] = []
    private var vocabularyArray: [String] = []
    
    private var vocabularyList: VocabularyList?
    private var disappearImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initReviewWordList(count: searchTotalCount())
    }
    
    /// 取得各難度的搜尋總數量
    /// - Returns: Int
    func searchTotalCount() -> Int {
        let totalCount = Constant.searchCountWithLevel.reduce(0) { return $0 + $1.value }
        return totalCount
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
    @IBAction func refreshQuestion(_ sender: UIBarButtonItem) { initReviewWordList(count: searchTotalCount()); Utility.shared.flashHUD(with: .nice) }
    @IBAction func questionLevel(_ sender: UIBarButtonItem) { levelMenu() }
}

// MARK: - MyNavigationControllerDelegate
extension ReviewViewController: MyNavigationControllerDelegate {
    func refreshRootViewController() { initReviewWordList(count: searchTotalCount()) }
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
    func initReviewWordList(count: Int) {
        
        initTitle(with: "單字複習")
        
        isNextVocabulary = true
        answerLabel.text = ""
        interpretLabel.text = ""
        vocabularyArray = []
        reviewWordDetailList = []
        answearButtonStatus(isEnabled: false)
        
        reviewWordList = reviewWordRandomListArray()
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
    
    /// 讀出單字 (單字解譯 / 單字例句)
    /// - Parameters:
    ///   - level: Constant.QuestionLevel
    func playWordSound(with level: Constant.QuestionLevel) {
        
        guard let answerText = answerLabel.text,
              let interpretText = interpretLabel.text
        else {
            return
        }
        
        switch level {
        case .read:
            Utility.shared.speak(string: answerText, voice: Constant.currentTableName)
        case .listen:
            Utility.shared.speak(string: answerText, voice: Constant.currentTableName)
            Utility.shared.speak(string: interpretText, voice: Constant.currentTableName)
        }
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
    /// - Parameters:
    ///   - vocabularyList: VocabularyList?
    ///   - level: Constant.QuestionLevel
    func speakVocabulary(_ vocabularyList: VocabularyList?, level: Constant.QuestionLevel) {
        
        guard let vocabularyList = vocabularyList else { return }
        
        self.vocabularyList = vocabularyList
        
        interpretLabelAction(vocabularyList, level: questionLevel)
        speakVocabularyAction(with: .speak, loopCount: repeatAnimateLoopCount)
        playWordSound(with: questionLevel)
    }
    
    /// 讀出單字時所顯示單字的提示 (單字翻譯 / 單字例句)
    /// - Parameters:
    ///   - vocabularyList: VocabularyList?
    ///   - level: Constant.QuestionLevel
    func interpretLabelAction(_ vocabularyList: VocabularyList, level: Constant.QuestionLevel) {
        
        if (reviewWordDetailList.isEmpty) { reviewWordDetailList = API.shared.searchWordDetailList(vocabularyList.word, for: Constant.currentTableName) }
        
        guard let detailList = reviewWordDetailList.popLast() else { interpretLabel.text = ""; return }
        
        let vocabulary = detailList._jsonClass(for: Vocabulary.self)
        reviewWordDetailList.insert(detailList, at: 0)
        
        answerLabel.text = vocabularyList.word
        answerLabel.textColor = .clear
        
        switch level {
        case .read:
            interpretLabel.text = vocabulary?.interpret
            interpretLabel.textColor = level.color()
            interpretLabel.font = Constant.VoiceCode.chinese.font(size: 24.0)
        case .listen:
            interpretLabel.text = vocabulary?.example
            interpretLabel.textColor = level.color()
            interpretLabel.font = Constant.currentTableName.font(size: 24.0)
        }
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
        
        if (!isNextVocabulary) { speakVocabulary(vocabularyList, level: questionLevel); return }
        
        guard let examinationList = reviewWordList.popLast(),
              let vocabularyList = examinationList._jsonClass(for: VocabularyList.self)
        else {
            return
        }
                
        let count = searchWordCount - reviewWordList.count
        initTitle(with: "單字複習 - \(count) / \(searchWordCount)")
        speakVocabulary(vocabularyList, level: questionLevel)
    }
    
    /// 填寫解答之後的動作
    /// - Parameters:
    ///   - word: String
    ///   - vocabularyList: VocabularyList
    func solutionAction(with vocabularyList: VocabularyList, isCorrect: Bool) -> Bool {
        
        isNextVocabulary = true
        answearButtonStatus(isEnabled: false)
        reviewWordDetailList = []
        
        answerLabel.textColor = .systemBlue
        interpretLabel.textColor = .darkText
        
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
    
    /// 產生隨機的題目
    /// - Returns: [[String : Any]]
    func reviewWordRandomListArray() -> [[String : Any]] {
        
        var list: [[String : Any]] = []
        
        for (level, count) in Constant.searchCountWithLevel {
            list += API.shared.searchGuessWordList(with: level, for: Constant.currentTableName, count: count, offset: 0)
        }
        
        return list.shuffled()
    }
    
    /// 猜字等級選單
    func levelMenu() {

        let alertController = UIAlertController(title: "請選擇等級", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        Constant.QuestionLevel.allCases.forEach { level in
            
            let action = UIAlertAction(title: level.value(), style: .default) { [weak self] _ in
                
                guard let this = self else { return }
                
                this.questionLevel = level
                this.repeatAnimateLoopCount = level.repeatAnimateLoopCount()
                this.initReviewWordList(count: this.searchTotalCount())
                
                Utility.shared.flashHUD(with: .nice)
            }
            
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        
        present(alertController, animated: true, completion: nil)
    }
}
