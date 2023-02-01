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
        
    @IBOutlet weak var speechLabel: UILabel!
    @IBOutlet weak var interpretLabel: UILabel!
    @IBOutlet weak var exampleLabel: UILabel!
    @IBOutlet weak var translateLabel: UILabel!
    
    static var listViewDelegate: ListViewDelegate?
    static var exmapleList: [[String : Any]] = []

    var indexPath: IndexPath = []
    
    private var vocabulary: Vocabulary?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        exampleLabel.gestureRecognizers?.forEach({ exampleLabel.removeGestureRecognizer($0) })
    }
    
    deinit { wwPrint("\(Self.self) deinit") }

    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @IBAction func playSound(_ sender: UIButton) { playExampleSound() }
    
    @objc func updateSpeechLabel(_ sender: UITapGestureRecognizer) { Self.listViewDelegate?.speechMenu(with: indexPath) }
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
    func configure(for indexPath: IndexPath) {
        
        guard let vocabulary = Self.vocabulary(with: indexPath) else { return }
        
        let speechType = Vocabulary.Speech(rawValue: vocabulary.speech) ?? .noue
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateSpeechLabel(_:)))
        
        self.indexPath = indexPath
        self.vocabulary = vocabulary
        
        speechLabel.text = speechType.value()
        speechLabel.backgroundColor = speechType.backgroundColor()
        speechLabel.addGestureRecognizer(tapRecognizer)
        
        interpretLabel.text = vocabulary.interpret ?? ""

        exampleLabel.text = vocabulary.example ?? ""
        exampleLabel.font = Constant.currentTableName.font(size: 24.0) ?? UIFont.systemFont(ofSize: 24.0)

        translateLabel.text = vocabulary.translate ?? ""
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
}
