//
//  SentenceTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng 2023/2/6.
//

import UIKit
import WWPrint

// MARK: - 例句列表
final class SentenceTableViewCell: UITableViewCell, CellReusable {
    
    static var sentenceListArray: [[String : Any]] = []
    
    @IBOutlet weak var exampleLabel: UILabel!
    @IBOutlet weak var translateLabel: UILabel!
    @IBOutlet weak var speechLabel: UILabel!
    
    static var sentenceViewDelegate: SentenceViewDelegate?
    
    var indexPath: IndexPath = []
    
    private var sentenceList: VocabularySentenceList?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        speechLabel.gestureRecognizers?.forEach({ speechLabel.removeGestureRecognizer($0) })
        accessoryView?.gestureRecognizers?.forEach({ accessoryView?.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @objc func updateSpeechLabel(_ sender: UITapGestureRecognizer) { Self.sentenceViewDelegate?.speechMenu(with: indexPath) }
    @objc func persentNetDictionary(_ sender: UITapGestureRecognizer) { Self.sentenceViewDelegate?.wordDictionary(with: indexPath) }

    @IBAction func playSound(_ sender: UIButton) { playExampleSound() }
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
extension SentenceTableViewCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func sentenceList(with indexPath: IndexPath) -> VocabularySentenceList? {
        guard let sentenceList = Self.sentenceListArray[safe: indexPath.row]?._jsonClass(for: VocabularySentenceList.self) else { return nil }
        return sentenceList
    }
}

// MARK: - 小工具
private extension SentenceTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let sentenceList = Self.sentenceList(with: indexPath) else { return }
        
        let speechType = VocabularySentenceList.Speech(rawValue: sentenceList.speech) ?? .general
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateSpeechLabel(_:)))

        self.accessoryView = accessoryViewMaker()
        self.indexPath = indexPath
        self.sentenceList = sentenceList
        
        speechLabel.addGestureRecognizer(tapRecognizer)
        speechLabel.text = speechType.value()
        speechLabel.backgroundColor = speechType.backgroundColor()
        
        exampleLabel.font = Constant.currentTableName.font(size: 24.0) ?? UIFont.systemFont(ofSize: 24.0)
        exampleLabel.text = sentenceList.example
        
        translateLabel.text = sentenceList.translate
    }
    
    /// 讀出例句
    func playExampleSound() {
        
        guard let sentenceList = sentenceList,
              let example = sentenceList.example
        else {
            return
        }
        
        Utility.shared.speak(string: example, voice: Constant.currentTableName)
    }
    
    /// 最右側的箭頭View
    /// - Returns: UIImageView
    func accessoryViewMaker() -> UIImageView {
        
        let imageView = UIImageView(image: UIImage(imageLiteralResourceName: "NextArrow"))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(Self.persentNetDictionary(_:)))
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapRecognizer)
        
        return imageView
    }
}
