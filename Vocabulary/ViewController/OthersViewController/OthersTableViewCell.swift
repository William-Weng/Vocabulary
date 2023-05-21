//
//  OthersTableViewCell.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/11.
//

import UIKit
import WWPrint
import WWNetworking_UIImage

// MARK: - 其它設定Cell
final class OthersTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    static var othersViewDelegate: OthersViewDelegate?
    static var bookmarksArray: [[String : Any]] = []
    static var defaultImage = UIImage(named: "Picture")
    
    var indexPath: IndexPath = []
    
    private var bookmarkSite: BookmarkSite?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.gestureRecognizers?.forEach({
            iconImageView.removeGestureRecognizer($0)
            iconImageView.image = Self.defaultImage
        })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @objc func loadImage(_ sender: UITapGestureRecognizer) {
        guard let filename = iconFilename() else { return }
        Self.othersViewDelegate?.loadImage(with: indexPath, filename: filename)
    }
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - 小工具
extension OthersTableViewCell {
    
    /// 取得書籤
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
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(Self.loadImage(_:)))
        
        self.indexPath = indexPath
        self.bookmarkSite = bookmarkSite
        
        titleLabel.text = bookmarkSite.title
        
        iconImageView.addGestureRecognizer(tapRecognizer)
        iconImageView.WW.downloadImage(with: bookmarkSite.icon, defaultImage: Self.defaultImage)
    }
    
    /// 讀取存在手機的圖示檔
    /// - Parameter filename: String?
    /// - Returns: UIImage?
    func iconImage(with filename: String?) -> UIImage? {
        
        guard let imageFolderUrl = Constant.FileFolder.image.url(),
              let filename = filename
        else {
            return nil
        }
        
        let url = imageFolderUrl.appendingPathComponent(filename, isDirectory: false)
        return UIImage(contentsOfFile: url.path)
    }
    
    /// 圖示檔的名稱 (SHA1)
    /// - Returns: String?
    func iconFilename() -> String? {
        guard let bookmarkSite = bookmarkSite else { return nil }
        return bookmarkSite.iconName()
    }
}
