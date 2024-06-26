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
    
    var indexPath: IndexPath = []
    weak var paletteViewDelegate: PaletteViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting(with: indexPath)
    }
    
    deinit {
        GalleryTableViewCell.galleryImages = []
        paletteViewDelegate = nil
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
        
        let filename = GalleryTableViewCell.galleryImages[safe: indexPath.row]
        paletteViewDelegate?.animation(with: self.indexPath, filename: filename)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 128.0
    }
}

// MARK: - 小工具
private extension GalleryViewController {
    
    /// 初始化設定
    func initSetting(with indexPath: IndexPath) {

        let colorSetting = PaletteTableViewCell.colorSetting(with: indexPath)
        
        GalleryTableViewCell.galleryImages = filterGalleryImageList()
        myTableView._delegateAndDataSource(with: self)
        myLabel.text = colorSetting?.name
    }
    
    /// 過濾GIF動畫資料夾的圖片列表
    /// - Parameter extensions: 要留下來的副檔名們 (gif, png, apng)
    /// - Returns: [String]
    func filterGalleryImageList(with extensions: Set<String> = ["gif", "png", "apng"]) -> [String] {
        
        guard let imageArray = galleryImageList() else { return [] }
        
        let imageList = imageArray.filter { filename in
            
            let array = filename.split(separator: ".")
            
            if (array.count < 2 ) { return false }
            if (!extensions.contains(array.last?.lowercased() ?? "")) { return false }
            
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
