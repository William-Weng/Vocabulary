//
//  ReviewViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/25.
//

import UIKit
import WWPrint

final class ReviewViewController: UIViewController {
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var speakImageView: UIImageView!
    @IBOutlet weak var answearButton: UIButton!
    @IBOutlet weak var answerLabel: UILabel!
    
    private let reviewWordCount = 2
    
    private var isNextVocabulary = false
    private var isAnimationStop = false
    private var speakAnimateLoopCount = 0
    private var disappearImage: UIImage?
    private var reviewWordList: [[String : Any]] = []
    private var vocabularyList: VocabularyList?
    private var vocabularyArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initReviewWordList(count: reviewWordCount)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatedBackground(with: .working)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseBackgroundAnimation()
    }
    
    deinit { wwPrint("\(Self.self) deinit") }
    
    @objc func speakVocabularyAction(_ tapGesture: UITapGestureRecognizer) {
                
        if (!isNextVocabulary) { speakVocabulary(vocabularyList); return }
                
        guard let examinationList = reviewWordList.popLast(),
              let vocabularyList = examinationList._jsonClass(for: VocabularyList.self)
        else {
            return
        }
        
        let count = reviewWordCount - reviewWordList.count
        title = "單字複習 - \(count) / \(reviewWordCount)"
        speakVocabulary(vocabularyList)
    }
        
    @IBAction func answearAction(_ sender: UIButton) {
                
        guard let vocabularyList = vocabularyList else { return }
        
        answerAlert("解答", placeholder: "請輸入您所聽到的單字") { [weak self] word in
            
            guard let this = self else { return }
            
            defer {
                this.isNextVocabulary = true
                this.answerLabel.text = vocabularyList.word
                this.answearButton._isEnabled(false, backgroundColor: .gray)
                Utility.shared.levelMenu(target: this, vocabularyList: vocabularyList)
            }
            
            if (vocabularyList.word.lowercased() != word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) { Utility.shared.flashHUD(with: .shudder); return }
                        
            _ = API.shared.updateReviewCountToList(vocabularyList.id, count: vocabularyList.review + 1, for: Constant.currentTableName)
            
            this.vocabularyArray.append(word)
            Utility.shared.flashHUD(with: .nice)
        }
    }
    
    @IBAction func createQuestion(_ sender: UIBarButtonItem) { initReviewWordList(count: reviewWordCount) }
}

// MARK: - 小工具
private extension ReviewViewController {
    
    /// 初始化設定
    func initSetting() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Self.speakVocabularyAction(_:)))
        speakImageView.addGestureRecognizer(tapGesture)
        
        answearButton._isEnabled(false, backgroundColor: .gray)
        vocabularyArray = []
        isNextVocabulary = true
        answerLabel.text = ""
    }
    
    /// 產生猜單字的字組
    /// - Parameter count: 題目數量
    func initReviewWordList(count: Int) {
        title = "單字複習"
        isNextVocabulary = true
        reviewWordList = API.shared.searchReviewWordList(for: Constant.currentTableName, count: count, offset: 0)
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
        answearButton._isEnabled(false, backgroundColor: .gray)
        
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
                    this.answearButton._isEnabled(true, backgroundColor: .red)
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
        
        answerLabel.text = ""
        playWordSound(with: vocabularyList)
        speakVocabularyAction(with: .speak, loopCount: 5)
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
}
