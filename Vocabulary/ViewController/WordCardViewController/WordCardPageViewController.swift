//
//  WordCardPageViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2024/2/12.
//

import UIKit

// MARK: - 單字卡內容
final class WordCardPageViewController: UIViewController {

    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    @IBOutlet weak var speechLabel: UILabel!
    @IBOutlet weak var interpretLabel: UILabel!
    @IBOutlet weak var exampleLabel: UILabel!
    @IBOutlet weak var translateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initGestureSetting()
    }
    
    @objc func playWordSound(_ gesture: UITapGestureRecognizer) { playSound(string: wordLabel.text) }
    @objc func playExampleSound(_ gesture: UITapGestureRecognizer) { playSound(string: exampleLabel.text) }
}

// MARK: - 小工具
private extension WordCardPageViewController {
    
    /// 初始化Label點擊功能
    func initGestureSetting() {
        
        let wordGesture = UITapGestureRecognizer(target: self, action: #selector(WordCardPageViewController.playWordSound(_:)))
        let exampleGesture = UITapGestureRecognizer(target: self, action: #selector(WordCardPageViewController.playExampleSound(_:)))

        wordLabel.isUserInteractionEnabled = true
        exampleLabel.isUserInteractionEnabled = true
        wordLabel.addGestureRecognizer(wordGesture)
        exampleLabel.addGestureRecognizer(exampleGesture)
    }
    
    /// 讀出文字句子
    /// - Parameter string: String?
    func playSound(string: String?) {
        
        guard let string = string,
              let settings = Utility.shared.generalSettings(index: Constant.tableNameIndex)
        else {
            return
        }
        
        Utility.shared.speak(string: string, code: settings.voice)
    }
}
