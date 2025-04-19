//
//  WordMemoryViewController.swift
//  Vocabulary
//
//  Created by William Weng on 2025/4/19.
//

import UIKit
import WWCollectionViewLayout

// MARK: - WordMemoryDelegate
protocol WordMemoryDelegate: NSObject {
    
    /// 刪除單字
    func deleteItem()
    
    /// 到單字列表
    /// - Parameter indexPath: IndexPath
    func itemDetail(with indexPath: IndexPath)
}

// MARK: - 單字記憶
final class WordMemoryViewController: UIViewController {
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    weak var mainViewDelegate: MainViewDelegate?
    
    private let segueIdentifier = "MemoryListViewSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearAction(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearAction(animated)
    }
    
    @IBAction func refreshVocabularyListAction(_ sender: UIBarButtonItem) {
        refreshVocabularyList()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        vocabularyListPageSetting(for: segue, sender: sender)
    }
    
    deinit {
        WordMemoryItemCell.wordMemoryDelegate = nil
        mainViewDelegate = nil
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension WordMemoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return WordMemoryItemCell.vocabularyListArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView._reusableCell(at: indexPath) as WordMemoryItemCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? WordMemoryItemCell else { return }
        cell.playWordSound()
    }
}

// MARK: - WordMemoryDelegate
extension WordMemoryViewController: WordMemoryDelegate {
    
    func deleteItem() {
        
        let indexPath = IndexPath(row: 0, section: 0)
        _ = WordMemoryItemCell.vocabularyListArray._popFirst()
        
        myCollectionView._performBatchUpdates({ collectionView in
            collectionView.deleteItems(at: [indexPath])
        }, completion: { collectionView in
            collectionView.reloadData()
        })
    }
    
    func itemDetail(with indexPath: IndexPath) {
        performSegue(withIdentifier: segueIdentifier, sender: indexPath)
    }
}

// MARK: - 小工具
private extension WordMemoryViewController {
    
    /// 初始化設定
    func initSetting() {
                
        let layout = WWCollectionViewLayout.Stack.layout()
        let width = suitableWidth(with: myCollectionView.bounds.size)
        
        layout.itemSize = CGSize(width: width, height: width)
        layout.angles = [0, -15, -30, 15, 30]
        
        WordMemoryItemCell.wordMemoryDelegate = self
        refreshVocabularyList()
        
        updateLayout(layout)
        myCollectionView._delegateAndDataSource(with: self)
    }
    
    /// 重新產生單字集
    func refreshVocabularyList() {
        
        guard let info = Utility.shared.generalSettings(index: Constant.tableNameIndex) else { return }
        
        WordMemoryItemCell.vocabularyListArray = API.shared.searchWordRandomListDetail(info: info)
        myCollectionView.reloadSections(IndexSet(integer: 0))
    }
    
    /// 更新Layout
    /// - Parameters:
    ///   - layout: UICollectionViewLayout
    ///   - animated: Bool
    func updateLayout(_ layout: UICollectionViewLayout, animated: Bool = true) {
        myCollectionView.collectionViewLayout.invalidateLayout()
        myCollectionView.setCollectionViewLayout(layout, animated: animated)
    }
    
    /// View將要顯示時的動作
    /// - Parameter animated: Bool
    func viewWillAppearAction(_ animated: Bool) {
        mainViewDelegate?.navigationBarHidden(false)
        mainViewDelegate?.tabBarHidden(true)
    }
    
    /// View將要消失時的動作
    /// - Parameter animated: Bool
    func viewWillDisappearAction(_ animated: Bool) {
        mainViewDelegate?.navigationBarHidden(false)
        mainViewDelegate?.tabBarHidden(false)
    }
    
    /// 適合的寬度
    /// - Parameters:
    ///   - size: 尺寸
    ///   - precent: 比例
    /// - Returns: CGFloat
    func suitableWidth(with size: CGSize, precent: CGFloat = 0.65) -> CGFloat {
        
        let width = (size.height > size.width) ? size.width : size.height
        return width * precent
    }
    
    /// 設定單字列表頁的相關數值
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func vocabularyListPageSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? ListViewController,
              let indexPath = sender as? IndexPath,
              let vocabularyList = WordMemoryItemCell.vocabularyList(with: indexPath)
        else {
            return
        }
        
        viewController.canDelete = false
        viewController.vocabularyList = vocabularyList
        viewController.vocabularyListIndexPath = indexPath
        viewController.mainViewDelegate = mainViewDelegate
    }
}
