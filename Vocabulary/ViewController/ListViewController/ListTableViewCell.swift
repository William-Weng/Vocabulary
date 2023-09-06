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
    @IBOutlet weak var hardWorkImageView: UIImageView!
    
    static var exmapleList: [[String : Any]] = []

    var indexPath: IndexPath = []
    
    private var isHardWork = false
    private var vocabulary: Vocabulary?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hardWorkImageView.gestureRecognizers?.forEach({ hardWorkImageView.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @objc func updateHardWork(_ recognizer: UITapGestureRecognizer) {
        isHardWork.toggle()
        updateHardWork(isHardWork, with: indexPath)
    }
    
    @IBAction func playSound(_ sender: UIButton) { playExampleSound() }
    
    deinit { wwPrint("\(Self.self) deinit", isShow: Constant.isPrint) }
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
        
        let info = Constant.SettingsJSON.wordSpeechInformations[safe: vocabulary.speech]

        self.indexPath = indexPath
        self.vocabulary = vocabulary
        self.isHardWork = ((vocabulary.hardwork ?? 0) != 0)
        
        interpretLabel.text = vocabulary.interpret ?? ""
        interpretLabel.textColor = .clear

        exampleLabel.text = vocabulary.example ?? ""
        exampleLabel.font = Constant.currentTableName.font(size: 24.0) ?? UIFont.systemFont(ofSize: 24.0)

        translateLabel.text = vocabulary.translate ?? ""
        translateLabel.textColor = .clear
        
        speechButtonSetting(speechButton, with: info)
        speechButton.showsMenuAsPrimaryAction = true
        speechButton.menu = UIMenu(title: "請選擇詞性", children: speechMenuActionMaker())
        
        hardWorkImageView.image = Utility.shared.hardWorkIcon(isHardWork)
        initHardWorkImageViewTapGestureRecognizer()
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
        
        let actions = Constant.SettingsJSON.wordSpeechInformations.map { speechActionMaker(with: $0) }
        return actions
    }

    func speechActionMaker(with info: Settings.WordSpeechInformation) -> UIAction {
        
        let action = UIAction(title: info.name) { [weak self] _ in
            
            guard let this = self else { return }
            
            this.updateSpeech(info, with: this.indexPath)
            // this.updateSpeechDictionary(speech, with: this.indexPath)
        }
        
        return action
    }
    
    /// 更新SpeechButton文字
    /// - Parameters:
    ///   - info: Settings.WordSpeechInformation
    ///   - indexPath: IndexPath
    func updateSpeech(_ info: Settings.WordSpeechInformation, with indexPath: IndexPath) {
        
        guard let vocabulary = Self.vocabulary(with: indexPath) else { return }
        
        let isSuccess = API.shared.updateSpeechToList(vocabulary.id, info: info, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        speechButtonSetting(speechButton, with: info)
    }
    
    /// levelButton文字顏色設定
    /// - Parameters:
    ///   - button: UIButton
    ///   - info: Settings.WordSpeechInformation?
    func speechButtonSetting(_ button: UIButton, with info: Settings.WordSpeechInformation?) {
        
        button.setTitle(info?.name ?? "名詞", for: .normal)
        button.setTitleColor(UIColor(rgb: info?.color ?? "#ffffff"), for: .normal)
        button.backgroundColor = UIColor(rgb: info?.backgroundColor ?? "#000000")
    }
    
    /// 更新暫存的例句列表資訊
    /// - Parameters:
    ///   - speech: Vocabulary.Speech
    ///   - indexPath: IndexPath
    func updateSpeechDictionary(_ speech: Vocabulary.Speech, with indexPath: IndexPath) {
        
        guard var dictionary = Self.exmapleList[safe: indexPath.row] else { return }
        
        dictionary["speech"] = speech.rawValue
        Self.exmapleList[indexPath.row] = dictionary
    }
    
    /// HardWorkImageView點擊功能
    func initHardWorkImageViewTapGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateHardWork(_:)))
        hardWorkImageView.addGestureRecognizer(recognizer)
    }
    
    /// 更新HardWork狀態
    /// - Parameters:
    ///   - isHardWork: Bool
    ///   - indexPath: IndexPath
    func updateHardWork(_ isHardWork: Bool, with indexPath: IndexPath) {
        
        guard let vocabulary = Self.vocabulary(with: indexPath) else { return }
        
        let isSuccess = API.shared.updateHardWorkToList(vocabulary.id, isHardWork: isHardWork, for: Constant.currentTableName.rawValue)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        hardWorkImageView.image = Utility.shared.hardWorkIcon(isHardWork)
        updateHardWorkDictionary(isHardWork, with: indexPath)
    }
    
    /// 更新暫存的翻譯難度資訊
    /// - Parameters:
    ///   - isHardWork: Bool
    ///   - indexPath: IndexPath
    func updateHardWorkDictionary(_ isHardWork: Bool, with indexPath: IndexPath) {
        
        guard var dictionary = Self.exmapleList[safe: indexPath.row] else { return }
        
        let hardWork = isHardWork._int()
        dictionary["hardwork"] = hardWork
        
        Self.exmapleList[indexPath.row] = dictionary
    }
}
