//
//  SentenceTableViewCell.swift
//  Vocabulary
//
//  Created by iOS on 2023/2/6.
//

import UIKit
import WWPrint

final class SentenceTableViewCell: UITableViewCell, CellReusable {
    
    static var sentenceListArray: [[String : Any]] = []
    
    @IBOutlet weak var exampleLabel: UILabel!
    @IBOutlet weak var translateLabel: UILabel!
    
    var indexPath: IndexPath = []
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
}

// MARK: - 小工具
private extension SentenceTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {}
}
