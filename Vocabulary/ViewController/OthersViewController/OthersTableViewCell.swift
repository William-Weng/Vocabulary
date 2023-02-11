//
//  OthersTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/11.
//

import UIKit

final class OthersTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    static var bookmarksArray: [[String : Any]] = []
    
    var indexPath: IndexPath = []
    
    private var bookmarkSite: BookmarkSite?
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
}

// MARK: - 小工具
extension OthersTableViewCell {
    
    /// 取得書籤例句
    /// - Parameter indexPath: IndexPath
    /// - Returns: VocabularyList?
    static func bookmarkSite(with indexPath: IndexPath) -> BookmarkSite? {
        guard let bookmarkSite = Self.bookmarksArray[safe: indexPath.row]?._jsonClass(for: BookmarkSite.self) else { return nil }
        return bookmarkSite
    }
}

// MARK: - 小工具
private extension OthersTableViewCell {
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        guard let bookmarkSite = Self.bookmarkSite(with: indexPath) else { return }
        
        // let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateSpeechLabel(_:)))
        
        self.indexPath = indexPath
        self.bookmarkSite = bookmarkSite
        
        titleLabel.text = bookmarkSite.title
    }
}
