//
//  ReviewViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/25.
//

import UIKit
import WWPrint
import AVFAudio

// MARK: - 單字複習頁面
final class ReviewViewController: UIViewController {
    
    enum ViewSegue: String {
        case solutionView = "SolutionViewSegue"
        case speakingRateView = "SpeakingRateViewSegue"
    }
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var speakImageView: UIImageView!
    @IBOutlet weak var answearButton: UIButton!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var interpretLabel: UILabel!
    @IBOutlet weak var refreshQuestionButtonItem: UIBarButtonItem!
    @IBOutlet weak var questionLevelButtonItem: UIBarButtonItem!
    @IBOutlet weak var landscapeBottomConstraint: NSLayoutConstraint!
    
    private var isNextVocabulary = false
    private var isAnimationStop = false
    private var isGuessAnimationStop = false
    private var searchWordCount = 10
    private var questionLevel: Constant.QuestionLevel = .read
    
    private var reviewWordList: [[String : Any]] = []
    private var reviewWordDetailList: [[String : Any]] = []
    private var vocabularyArray: [String] = []
    
    private var vocabularyList: VocabularyList?
    private var disappearImage: UIImage?
        
    private lazy var speechSynthesizer = AVSpeechSynthesizer._build(delegate: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initSpeakImage()
        initReviewWordList()
        initQuestionLevelItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MyTabBarController.isHidden = false
        animatedBackground(with: .working)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MyTabBarController.isHidden = true
        pauseBackgroundAnimation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let window = view.window, window._hasSafeArea() { landscapeBottomConstraint.constant = 64 }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier,
              let viewSegue = ViewSegue(rawValue: identifier)
        else {
            return
        }
        
        switch viewSegue {
        case .solutionView: solutionPageSetting(for: segue, sender: sender)
        case .speakingRateView: speakingRatePageSetting(for: segue, sender: sender)
        }
    }
    
    @objc func guessVocabulary(_ tapGesture: UITapGestureRecognizer) { speakVocabularyAction() }
    @objc func reviewQuestionLevel(_ sender: UITapGestureRecognizer) { reviewQuestionLevelAction(questionLevel) }
    
    @IBAction func guessAnswear(_ sender: UIButton) { answearAction(sender) }
    @IBAction func reviewSolution(_ sender: UIBarButtonItem) { performSegue(withIdentifier: ViewSegue.solutionView.rawValue, sender: vocabularyArray) }
    @IBAction func refreshQuestion(_ sender: UIBarButtonItem) { initReviewWordList(); Utility.shared.flashHUD(with: .nice) }
    @IBAction func speedRate(_ sender: UIBarButtonItem) { performSegue(withIdentifier: ViewSegue.speakingRateView.rawValue, sender: nil) }
    
    deinit { wwPrint("\(Self.self) deinit", isShow: Constant.isPrint) }
}

// MARK: - AVSpeechSynthesizerDelegate
extension ReviewViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) { isGuessAnimationStop = false }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { isGuessAnimationStop = true }
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
    
    /// 初始化SpeakImage
    func initSpeakImage() {
         
        guard let fileURL = Constant.HudGifType.speak.fileURL(),
              let image = UIImage(contentsOfFile: fileURL.path)
        else {
            return
        }
        
        speakImageView.image = image
    }
    
    /// 產生猜單字的字組
    /// - Parameter count: 一次要搜尋的單字數量
    func initReviewWordList() {
                
        isNextVocabulary = true
        answerLabel.text = ""
        interpretLabel.text = ""
        vocabularyArray = []
        reviewWordDetailList = []
        answearButtonStatus(isEnabled: false)
        
        reviewWordList = reviewWordRandomListArray()
        searchWordCount = reviewWordList.count
        
        titleViewSetting(with: "單字複習", count: 0, searchWordCount: searchWordCount)
    }
    
    /// 標題文字相關設定
    /// - Parameters:
    ///   - title: String
    ///   - count: Int
    func titleViewSetting(with title: String, count: Int, searchWordCount: Int) {
        
        let titleView = Utility.shared.titleLabelMaker(with: "\(title) - \(count) / \(searchWordCount)")
        let gesture = UITapGestureRecognizer(target: self, action: #selector(Self.reviewQuestionLevel(_:)))
        
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(gesture)
                
        navigationItem.titleView = titleView
    }
    
    /// 設定標題
    /// - Parameters:
    ///   - title: String
    ///   - count: Int
    func titleSetting(_ title: String, count: Int, searchWordCount: Int) {
        
        guard let titleView = navigationItem.titleView as? UILabel else { titleViewSetting(with: title, count: count, searchWordCount: searchWordCount); return }
        Utility.shared.titleViewSetting(with: titleView, title: title, count: count, searchWordCount: searchWordCount)
    }
    
    /// [按下語音播放猜單字的動作 (聲音播完 && 動畫完成)](https://stackoverflow.com/questions/40856037/how-to-know-when-an-avspeechutterance-has-finished-so-as-to-continue-app-activi)
    /// - Parameters:
    ///   - type: Utility.HudGifType
    ///   - loopCount: 動畫次數
    func speakVocabularyAction(with type: Constant.HudGifType = .speak) {
        
        guard let gifUrl = type.fileURL() else { return }
        
        isNextVocabulary = false
        isGuessAnimationStop = false
        speakImageView.isUserInteractionEnabled = false
        answearButtonStatus(isEnabled: false)
        
        _ = speakImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): wwPrint(error, isShow: Constant.isPrint)
            case .success(let info):
                                
                if (this.isGuessAnimationStop && info.index == 0) {
                    info.pointer.pointee = true
                    this.speakImageView.image = UIImage(contentsOfFile: gifUrl.path)
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
              let interpretText = interpretLabel.text,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        let string: String
        
        switch level {
        case .read: string = answerText
        case .listen: string = "\(answerText). \(interpretText)"
        }
        
        speechSynthesizer._speak(string: string, code: settings.code, rate: Constant.speakingSpeed)
    }
    
    /// 動畫背景設定
    /// - Parameter type: Utility.HudGifType
    func animatedBackground(with type: Constant.HudGifType) {
        
        guard let gifUrl = type.fileURL() else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): wwPrint(error, isShow: Constant.isPrint)
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
        speakVocabularyAction(with: .speak)
        playWordSound(with: questionLevel)
    }
    
    /// 讀出單字時所顯示單字的提示 (單字翻譯 / 單字例句)
    /// - Parameters:
    ///   - vocabularyList: VocabularyList?
    ///   - level: Constant.QuestionLevel
    func interpretLabelAction(_ vocabularyList: VocabularyList, level: Constant.QuestionLevel) {
        
        if (reviewWordDetailList.isEmpty), let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) {
            reviewWordDetailList = API.shared.searchWordDetailList(vocabularyList.word, for: .default(info.key))
        }
        
        guard let detailList = reviewWordDetailList.popLast() else { interpretLabel.text = ""; return }
        
        let vocabulary = detailList._jsonClass(for: Vocabulary.self)
        reviewWordDetailList.insert(detailList, at: 0)
        
        answerLabel.text = vocabularyList.word
        answerLabel.textColor = .clear
        
        switch level {
        case .read:
            interpretLabel.font = Utility.shared.font(name: "jf-openhuninn-1.1", size: 24.0)
            interpretLabel.textColor = level.color()
            interpretLabel.text = vocabulary?.interpret
        case .listen:
            interpretLabel.font = Utility.shared.dictionaryFont(with: Constant.tableNameIndex, size: 24.0)
            interpretLabel.textColor = level.color()
            interpretLabel.text = vocabulary?.example
        }
    }
    
    /// 填寫答案的提示框
    /// - Parameters:
    ///   - title: String
    ///   - message: String?
    ///   - placeholder: String?
    ///   - action: (String) -> Void
    func answerAlert(_ title: String, message: String? = nil, placeholder: String?, action: @escaping (String) -> Void) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField {
            $0.text = ""
            $0.placeholder = placeholder
        }
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { _ in
            guard let inputWord = alertController.textFields?.first?.text?._removeWhiteSpacesAndNewlines() else { return }
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
        
        titleSetting("單字複習", count: count, searchWordCount: searchWordCount)
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
    /// - Parameter sender: UIButton
    func answearAction(_ sender: UIButton) {
        
        guard let vocabularyList = vocabularyList else { return }
        
        answerAlert("解答", placeholder: "請輸入您所聽到的單字") { [weak self] inputWord in
            
            guard let this = self else { return }
            
            var isCorrect = false
            
            defer {
                
                let hudType: Constant.HudGifType = (!isCorrect) ? .shudder : .nice
                
                _ = this.solutionAction(with: vocabularyList, isCorrect: isCorrect)
                Utility.shared.flashHUD(with: hudType)
                
                this.levelMenu(target: this, vocabularyList: vocabularyList, sourceView: sender)
            }
            
            if (vocabularyList.word.lowercased() != inputWord._removeWhiteSpacesAndNewlines().lowercased()) { isCorrect = false; return }
            isCorrect = true
        }
    }
    
    /// 產生隨機的題目
    /// - Returns: [[String : Any]]
    func reviewWordRandomListArray() -> [[String : Any]] {
        
        var list: [[String : Any]] = []
        
        Constant.SettingsJSON.vocabularyLevelInformations.forEach { info in
            list += API.shared.searchGuessWordList(with: info, for: Constant.currentTableName, offset: 0)
        }
        
        return list.shuffled()
    }
    
    /// 設定解答頁的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func solutionPageSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? SolutionViewController,
              let words = sender as? [String]
        else {
            return
        }
        
        viewController.words = words
    }
    
    /// 設定語速的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func speakingRatePageSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? VolumeViewController else { return }
        
        viewController._transparent(.black.withAlphaComponent(0.3))
        viewController.soundType = .rate
        
        tabBarController?._tabBarHidden(true, animated: true)
    }
}

// MARK: - UIMenu
extension ReviewViewController {
    
    /// 單字等級選單
    /// - Parameters:
    ///   - target: UIViewController
    ///   - vocabularyList: VocabularyList?
    ///   - sourceView: UIView?
    func levelMenu(target: UIViewController, vocabularyList: VocabularyList?, sourceView: UIView? = nil) {
        
        guard let vocabularyList = vocabularyList else { return }
        
        let alertController = UIAlertController(title: "請選擇等級", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        Constant.SettingsJSON.vocabularyLevelInformations.forEach { info in
            
            let action = UIAlertAction(title: info.name, style: .default) { _ in
                let isSuccess = API.shared.updateLevelToList(vocabularyList.id, info: info, for: Constant.currentTableName)
                if (!isSuccess) { Utility.shared.flashHUD(with: .fail) }
            }
            
            alertController.addAction(action)
        }
        
        alertController.addAction(action)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.sourceView = sourceView
        
        target.present(alertController, animated: true, completion: nil)
    }
    
    /// 初始化問題等級Item
    func initQuestionLevelItem() {
        
        let actions = Constant.QuestionLevel.allCases.map { questionLevelActionMaker($0) }
        let menu = UIMenu(title: "請選擇問題等級", children: actions)
        
        questionLevelButtonItem.menu = menu
    }
    
    /// 問題等級功能
    /// - Parameter level: Constant.QuestionLevel
    /// - Returns: UIAction
    func questionLevelActionMaker(_ level: Constant.QuestionLevel) -> UIAction {
        
        let action = UIAction(title: level.value()) { [weak self] _ in
            
            guard let this = self else { return }
            
            this.questionLevel = level
            this.initReviewWordList()
            
            Utility.shared.flashHUD(with: .nice)
        }
        
        return action
    }
        
    /// 提示問題的難度類型
    /// - Parameter level: Constant.QuestionLevel
    func reviewQuestionLevelAction(_ level: Constant.QuestionLevel) {
        
        let version = Bundle.main._appVersion()
        let message = "v\(version.app) - \(version.build)"
        let title = "問題難度：\(level.value())"
        
        informationHint(with: title, message: message)
    }
    
    /// 顯示版本 / 問題的難度類型
    /// - Parameters:
    ///   - title: String?
    ///   - message: String?
    func informationHint(with title: String?, message: String?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "確認", style: .default) { _ in }
        
        alertController.addAction(actionOK)
        
        present(alertController, animated: true, completion: nil)
    }
}
