//
//  GalleryViewController.swift
//  Vocabulary
//
//  Created by iOS on 2023/9/15.
//

import UIKit

// MARK: - GIF動畫選擇框
final class GalleryViewController: UIViewController {

    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    deinit {
        GalleryTableViewCell.galleryImages = []
        myPrint("\(Self.self) init")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension GalleryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { GalleryTableViewCell.galleryImages.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as GalleryTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let cell = cell as? GalleryTableViewCell else { return }
        
        cell.initGifBlockSetting()
        cell.executeAnimation(with: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let cell = cell as? GalleryTableViewCell else { return }
        cell.removeGifBlock()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let list = filterGalleryImageList()
        myPrint(list)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 128.0
    }
}

// MARK: - 小工具
private extension GalleryViewController {
    
    /// 初始化設定
    func initSetting() {
        GalleryTableViewCell.galleryImages = filterGalleryImageList()
        myTableView._delegateAndDataSource(with: self)
    }
    
    /// 過濾GIF動畫資料夾的圖片列表
    /// - Parameter extension: 要留下來的副檔名
    /// - Returns: [String]
    func filterGalleryImageList(with extension: String = "gif") -> [String] {
        
        guard let imageArray = galleryImageList() else { return [] }
        
        let imageList = imageArray.filter { filename in
            
            let array = filename.split(separator: ".")
            
            if (array.count < 2 ) { return false }
            if (array.last?.lowercased() != `extension`.lowercased()) { return false }
            
            return true
        }

        return imageList.sorted()
    }
    
    /// GIF動畫資料夾的圖片列表
    /// - Returns: [String]?
    func galleryImageList() -> [String]? {
        
        guard let animationFolderUrl = Constant.FileFolder.animation.url() else { return nil }

        let result = FileManager.default._fileList(with: animationFolderUrl)
        
        switch result {
        case .failure(let error): myPrint(error); return nil
        case .success(let list): return list
        }
    }
}
