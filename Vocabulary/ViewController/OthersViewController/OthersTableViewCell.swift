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
    @IBOutlet weak var favoriteImageView: UIImageView!
    
    static var othersViewDelegate: OthersViewDelegate?
    static var bookmarksArray: [[String : Any]] = []
    static var defaultImage = UIImage(named: "Picture")
    
    var indexPath: IndexPath = []
    
    private var isFavorite = false
    private var bookmarkSite: BookmarkSite?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        iconImageView.gestureRecognizers?.forEach({
            iconImageView.removeGestureRecognizer($0)
            iconImageView.image = Self.defaultImage
        })
        
        favoriteImageView.gestureRecognizers?.forEach({ favoriteImageView.removeGestureRecognizer($0) })
    }
    
    func configure(with indexPath: IndexPath) { configure(for: indexPath) }
    
    @objc func loadImage(_ sender: UITapGestureRecognizer) {
        guard let filename = iconFilename() else { return }
        Self.othersViewDelegate?.loadImage(with: indexPath, filename: filename)
    }
    
    @objc func updateFavorite(_ recognizer: UITapGestureRecognizer) {
        isFavorite.toggle()
        updateFavorite(isFavorite, with: indexPath)
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
        self.isFavorite = ((bookmarkSite.favorite ?? 0) != 0)

        titleLabel.text = bookmarkSite.title
        
        iconImageView.addGestureRecognizer(tapRecognizer)
        iconImageView.WW.downloadImage(with: bookmarkSite.icon, defaultImage: Self.defaultImage)
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        initFavoriteImageViewTapGestureRecognizer()
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
    
    /// FavoriteImageView點擊功能
    func initFavoriteImageViewTapGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(Self.updateFavorite(_:)))
        favoriteImageView.addGestureRecognizer(recognizer)
    }
    
    /// 更新Favorite狀態
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavorite(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard let bookmark = Self.bookmarkSite(with: indexPath) else { return }
        
        let isSuccess = API.shared.updateBookmarkFavoriteToList(bookmark.id, isFavorite: isFavorite, for: Constant.currentTableName)
        if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
        
        favoriteImageView.image = Utility.shared.favoriteIcon(isFavorite)
        updateFavoriteDictionary(isFavorite, with: indexPath)
    }
    
    /// 更新暫存的我的最愛資訊
    /// - Parameters:
    ///   - isFavorite: Bool
    ///   - indexPath: IndexPath
    func updateFavoriteDictionary(_ isFavorite: Bool, with indexPath: IndexPath) {
        
        guard var dictionary = Self.bookmarksArray[safe: indexPath.row] else { return }
        
        let favorite = isFavorite._int()
        dictionary["favorite"] = favorite
        
        Self.bookmarksArray[indexPath.row] = dictionary
    }
}
