//
//  Protocol.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/23.
//

import UIKit

// MARK: - [強制畫面旋轉](https://johnchihhonglin.medium.com/限制某個頁面的螢幕旋轉方向-8c7235d5a774)
protocol OrientationLockable where Self: UIViewController {
    var lockOrientationMask: UIInterfaceOrientationMask { get set }
    var isAutorotate: Bool { get set }
}

// MARK: - 顏色設定檔 (Settings.json)
protocol ColorSettings {
    
    var key: String { get set }                 // 英文代碼
    var name: String { get set }                // 顯示名稱
    var value: Int { get set }                  // 資料庫數值
    var backgroundColor: String { get set }     // 背景顏色
    var color: String { get set }               // 文字顏色
}

// MARK: - 動畫設定檔 (Settings.json)
protocol AnimationSettings {
    var filename: String { get set }            // 動畫檔名
}

// MARK: - 可重複使用的Cell (UITableViewCell / UICollectionViewCell)
protocol CellReusable: AnyObject {
    
    static var identifier: String { get }       // Cell的Identifier
    var indexPath: IndexPath { get set }        // Cell的IndexPath
    
    /// Cell的相關設定
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath)
}

// MARK: - OrientationLockable
extension OrientationLockable {
    
    /// 更新畫面方向
    /// - Parameters:
    ///   - isAutorotate: 是否自動旋轉
    ///   - lockOrientationMask: 允許使用的畫面方向
    func updateOrientations(isAutorotate: Bool, lockOrientationMask: UIInterfaceOrientationMask) {
        self.isAutorotate = isAutorotate
        self.lockOrientationMask = lockOrientationMask
        self.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

// MARK: - 預設 identifier = class name (初值)
extension CellReusable {
    static var identifier: String { return String(describing: Self.self) }
    var indexPath: IndexPath { return [] }
}
