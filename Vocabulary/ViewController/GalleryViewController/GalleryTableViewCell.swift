//
//  GalleryTableViewCell.swift
//  Vocabulary
//
//  Created by iOS on 2023/9/15.
//

import UIKit

// MARK: - 選擇GIF動畫
final class GalleryTableViewCell: UITableViewCell, CellReusable {
    
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myImageBaseView: UIView!
    
    static var galleryImages: [String] = []
    
    var indexPath: IndexPath = []
    
    private var gifImageView: UIImageView?
    private var isAnimationStop = false
    private var animationBlock: ((URL) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isAnimationStop = false
        animationBlock = nil
    }
    
    func configure(with indexPath: IndexPath) {
        configure(for: indexPath)
    }
    
    deinit {
        myPrint("\(Self.self) init")
    }
}

// MARK: - 小工具
extension GalleryTableViewCell {
    
    /// GIF檔案名稱
    /// - Parameter indexPath: IndexPath
    /// - Returns: String?
    static func animationFilename(with indexPath: IndexPath) -> String? {
        return Self.galleryImages[safe: indexPath.row]
    }
    
    /// GIF檔案URL
    /// - Parameter indexPath: IndexPath
    /// - Returns: URL?
    static func animationUrl(with indexPath: IndexPath) -> URL? {
        
        guard let animationFolderUrl = Constant.FileFolder.animation.url(),
              let filename = Self.galleryImages[safe: indexPath.row],
              let fileURL = animationFolderUrl._appendPath(filename)
        else {
            return nil
        }
        
        return fileURL
    }
}

// MARK: - 小工具
private extension GalleryTableViewCell {
    
    /// 初始化設定
    /// - Parameter indexPath: IndexPath
    func configure(for indexPath: IndexPath) {
        
        myLabel.text = Self.animationFilename(with: indexPath)
        
        if let url = Self.animationUrl(with: indexPath) {
            isAnimationStop = false
            animationBlock?(url)
        }
    }
}

// MARK: - GIF動畫
extension GalleryTableViewCell {
    
    /// 執行GIF動畫
    func executeAnimation(with indexPath: IndexPath) {
        
        if let url = Self.animationUrl(with: indexPath) {
            isAnimationStop = false
            animationBlock?(url)
        }
    }
    
    /// 移除GIF動畫Block
    func removeGifBlock() {
        
        isAnimationStop = true
        animationBlock = nil
        gifImageView?.removeFromSuperview()
        gifImageView = nil
    }
    
    /// 初始化GIF動畫Block
    func initGifBlockSetting() {
        
        let gifImageView = UIImageView()
        
        gifImageView.contentMode = .scaleAspectFit
        gifImageView._autolayout(on: myImageBaseView)
        self.gifImageView = gifImageView
        
        animationBlock = { url in
            
            _ = gifImageView._GIF(url: url) { [weak self] result in
                                
                guard let this = self else { return }
                
                switch result {
                case .failure(let error): myPrint(error)
                case .success(let info):
                    info.pointer.pointee = this.isAnimationStop
                    if (this.isAnimationStop) { this.gifImageView?.image = nil }
                }
            }
        }
    }
}

