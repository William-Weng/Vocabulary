//
//  RSSReaderTableViewCell.swift
//  Vocabulary
//
//  Created by iOS on 2026/3/5.
//

import UIKit
import WWExpandableCell
import WWRssParser

final class RSSReaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var expandableView: WWExpandView!
    
    static var items: [WWRssParser.RssItem] = []
    static var expandRowsList: [Int: Set<IndexPath>] = [:]
    static weak var rssTableView: UITableView?
    
    var indexPath: IndexPath = []
    
    private let isSingle = true
    
    /// 展開 / 折疊
    /// - Parameter sender: UIButton
    @IBAction func expandAction(_ sender: UIButton) {
        guard let rssTableView = Self.rssTableView else { return }
        RSSReaderTableViewCell.exchangeExpandState(rssTableView, indexPath: indexPath, isSingle: isSingle)
    }
    
    deinit {
        Self.rssTableView = nil
        Self.items.removeAll()
    }
}

// MARK: - WWCellExpandable
extension RSSReaderTableViewCell: WWCellExpandable {
    
    /// 設定長相
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath) {
        
        guard let item = Self.items[safe: indexPath.row] else { return }
        
        self.indexPath = indexPath
        
        titleLabel.text =  "\(indexPath.row + 1) - \(item.title)"
        contentLabel.text = item.description
        expandableView.isHidden = !(Self.expandRowsList[indexPath.section]?.contains(indexPath) ?? false)
    }
    
    func expandView() -> WWExpandView? {
        return expandableView
    }
}
