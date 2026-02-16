//
//  SimilarWordCell.swift
//  Vocabulary
//
//  Created by William Weng on 2026/2/15.
//

import UIKit

// MARK: - 相似字Cell
final class SimilarWordCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet var levelImageViews: [UIImageView]!
    
    static var words: [SimilarWord] = []

    var indexPath: IndexPath = .init()

    func configure(with indexPath: IndexPath) {
        configure(for: indexPath)
    }
    
    deinit { myPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
private extension SimilarWordCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let list = Self.words[safe: indexPath.row] else { return }
        
        wordLabel.text = list.word
        
        for index in 0..<levelImageViews.count {
            
            let levelImageView = levelImageViews[index]
            let imageName = (index < list.level) ? "star.fill" : "star"
            
            levelImageView.image = UIImage(systemName: imageName)
        }
    }
}
