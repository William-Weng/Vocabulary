//
//  Protocol.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import UIKit

// MARK: - 顏色設定檔 (Settings.json)
protocol ColorSettings {
    
    var key: String { get set }                 // 英文代碼
    var name: String { get set }                // 顯示名稱
    var value: Int { get set }                  // 資料庫數值
    var backgroundColor: String { get set }     // 背景顏色
    var color: String { get set }               // 文字顏色
}

// MARK: - 可重複使用的Cell (UITableViewCell / UICollectionViewCell)
protocol CellReusable: AnyObject {
    
    static var identifier: String { get }           /// Cell的Identifier
    var indexPath: IndexPath { get set }            /// Cell的IndexPath
    
    /// Cell的相關設定
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath)
}

// MARK: - 預設 identifier = class name (初值)
extension CellReusable {
    static var identifier: String { return String(describing: Self.self) }
    var indexPath: IndexPath { return [] }
}
