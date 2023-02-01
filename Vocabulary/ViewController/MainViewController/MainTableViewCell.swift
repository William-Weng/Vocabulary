//
//  MainTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import UIKit
import WWPrint
import AVFAudio

// MARK: - 單字頁面Cell
final class MainTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var alphabetLabel: UILabel!
    
    static var mainViewDelegate: MainViewDelegate?
    static var vocabularyListArray: [[String : Any]] = []

    var indexPath: IndexPath = []
    
    private var vocabularyList: VocabularyList?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        levelLabel.gestureRecognizers?.forEach({ levelLabel.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    deinit { wwPrint("\(Self.self) deinit") }
    
    @IBAction func playSound(_ sender: UIButton) { playWordSound() }
    
    @objc func updateLevelLabel(_ sender: UITapGestureRecognizer) { Self.mainViewDelegate?.levelMenu(with: indexPath) }
}

// MARK: - 小工具
extension MainTableViewCell {
    
    /// 取得單字列表
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func vocabularyList(with indexPath: IndexPath) -> VocabularyList? {
        guard let vocabularyList = Self.vocabularyListArray[safe: indexPath.row]?._jsonClass(for: VocabularyList.self) else { return nil }
        return vocabularyList
    }
}

// MARK: - 小工具
private extension MainTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let vocabularyList = Self.vocabularyList(with: indexPath) else { return }
        
        let levelType = Vocabulary.Level(rawValue: vocabularyList.level) ?? .easy
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateLevelLabel(_:)))
        
        self.indexPath = indexPath
        self.vocabularyList = vocabularyList
        
        levelLabel.addGestureRecognizer(tapRecognizer)
        levelLabel.text = levelType.value()
        levelLabel.backgroundColor = levelType.backgroundColor()

        countLabel.text = "\(vocabularyList.count)"
        
        wordLabel.font = Constant.currentTableName.font() ?? UIFont.systemFont(ofSize: 36.0)
        wordLabel.text = vocabularyList.word
        
        alphabetLabel.text = vocabularyList.alphabet
    }
    
    /// 讀出單字
    func playWordSound() {
        guard let vocabularyList = vocabularyList else { return }
        Utility.shared.speak(string: vocabularyList.word, voice: Constant.currentTableName)
    }
}
