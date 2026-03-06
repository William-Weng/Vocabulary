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
    
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var expandableView: WWExpandView!
    
    static var expandRowsList: [Int: Set<IndexPath>] = [:]
    static weak var rssTableView: UITableView?
        
    var indexPath: IndexPath = []
    var item: WWRssParser.RssItem?
    
    func configure(with indexPath: IndexPath) {
        configure(indexPath: indexPath)
    }
    
    /// 展開 / 折疊
    /// - Parameter sender: UIButton
    @IBAction func expandAction(_ sender: UIButton) {
        
        guard let rssTableView = Self.rssTableView else { return }
        
        RSSReaderTableViewCell.exchangeExpandState(rssTableView, indexPath: indexPath, isSingle: true) { [weak self] isExpanded in
            guard let this = self else { return }
            this.titleViewExpandState(isExpanded: isExpanded)
        }
    }
        
    deinit { myPrint("\(Self.self) init") }
}

// MARK: - WWCellExpandable
extension RSSReaderTableViewCell: WWCellExpandable {
        
    func expandView() -> WWExpandView? {
        return expandableView
    }
}

// MARK: - 小工具
private extension RSSReaderTableViewCell {
    
    /// 設定長相
    /// - Parameter indexPath: IndexPath
    func configure(indexPath: IndexPath) {
        
        guard let item = item else { return }
        
        let isHidden = !(Self.expandRowsList[indexPath.section]?.contains(indexPath) ?? false)
        
        self.indexPath = indexPath
        titleLabel.text = "\(indexPath.row + 1) - \(item.title)"
        contentLabel.attributedText = item.description._html(font: .systemFont(ofSize: 20), foregroundColor: .white)
        titleView.layer.zPosition = 10
        
        titleViewExpandState(isExpanded: !isHidden)
        expandableViewExpandState(isHidden: isHidden)
    }
    
    /// 設定titleView的展開狀態
    /// - Parameters:
    ///   - isExpanded: 是否展開
    ///   - radius: 圓角大小
    func titleViewExpandState(isExpanded: Bool, radius: CGFloat = 8.0) {
        
        var corners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        
        if (isExpanded) { corners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] }
        titleView.layer._maskedCorners(radius: radius, corners: corners)
    }
    
    /// 設定expandableView的隱藏狀態
    /// - Parameters:
    ///   - isHidden: 是否隱藏
    ///   - radius: 圓角大小
    func expandableViewExpandState(isHidden: Bool, radius: CGFloat = 8.0) {
        
        let corners: CACornerMask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        expandableView.layer._maskedCorners(radius: radius, corners: corners)
        expandableView.isHidden = isHidden
    }
}
