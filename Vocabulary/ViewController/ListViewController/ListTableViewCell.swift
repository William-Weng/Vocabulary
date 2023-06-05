//
//  ListTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import UIKit
import WWPrint
import AVFAudio

// MARK: - 單字列表Cell
final class ListTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var interpretLabel: UILabel!
    @IBOutlet weak var exampleLabel: UILabel!
    @IBOutlet weak var translateLabel: UILabel!
    @IBOutlet weak var speechButton: UIButton!

    static var exmapleList: [[String : Any]] = []

    var indexPath: IndexPath = []
    
    private var vocabulary: Vocabulary?
        
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
        
    @IBAction func playSound(_ sender: UIButton) { playExampleSound() }
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
extension ListTableViewCell {
    
    /// 取得單字例句
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabulary(with indexPath: IndexPath) -> Vocabulary? {
        guard let vocabulary = Self.exmapleList[safe: indexPath.row]?._jsonClass(for: Vocabulary.self) else { return nil }
        return vocabulary
    }
}

// MARK: - 小工具
private extension ListTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let vocabulary = Self.vocabulary(with: indexPath) else { return }
        
        let speechType = Vocabulary.Speech(rawValue: vocabulary.speech) ?? .noue
        
        self.indexPath = indexPath
        self.vocabulary = vocabulary
        
        interpretLabel.text = vocabulary.interpret ?? ""
        interpretLabel.textColor = .clear

        exampleLabel.text = vocabulary.example ?? ""
        exampleLabel.font = Constant.currentTableName.font(size: 24.0) ?? UIFont.systemFont(ofSize: 24.0)

        translateLabel.text = vocabulary.translate ?? ""
        translateLabel.textColor = .clear
        
        speechButton.setTitle(speechType.value(), for: .normal)
        speechButton.backgroundColor = speechType.backgroundColor()
        speechButton.showsMenuAsPrimaryAction = true
        speechButton.menu = UIMenu(title: "請選擇詞性", children: speechMenuActionMaker())
    }
    
    /// 讀出例句
    func playExampleSound() {
        
        guard let vocabulary = vocabulary,
              let example = vocabulary.example
        else {
            return
        }
        
        Utility.shared.speak(string: example, voice: Constant.currentTableName)
    }
    
    /// 產生SpeechButton選到時的動作
    /// - Returns: [UIAction]
    func speechMenuActionMaker() -> [UIAction] {
        
        let actions = Vocabulary.Speech.list(for: Constant.currentTableName).map { speech in
            
            let action = UIAction(title: speech.value()) { [weak self] action in
                
                guard let this = self else { return }
                
                this.updateSpeech(speech, with: this.indexPath)
                this.updateSpeechDictionary(speech, with: this.indexPath)
            }
            
            return action
        }
        
        return actions
    }
    
    /// 更新SpeechButton文字
    /// - Parameters:
    ///   - speech: Vocabulary.Speech
    ///   - indexPath: IndexPath
    func updateSpeech(_ speech: Vocabulary.Speech, with indexPath: IndexPath) {
        
        guard let vocabulary = Self.vocabulary(with: indexPath) else { return }
        
        let isSuccess = API.shared.updateSpeechToList(vocabulary.id, speech: speech, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        speechButton.setTitle(speech.value(), for: .normal)
        speechButton.backgroundColor = speech.backgroundColor()
    }
    
    /// 更新暫存的例句列表資訊
    /// - Parameters:
    ///   - level: Vocabulary.Level
    ///   - indexPath: IndexPath
    func updateSpeechDictionary(_ speech: Vocabulary.Speech, with indexPath: IndexPath) {
        
        guard var dictionary = Self.exmapleList[safe: indexPath.row] else { return }
        
        dictionary["speech"] = speech.rawValue
        Self.exmapleList[indexPath.row] = dictionary
    }
}
