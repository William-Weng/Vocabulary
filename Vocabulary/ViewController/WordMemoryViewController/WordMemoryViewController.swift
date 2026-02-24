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
    
    /// 轉到單字列表
    /// - Parameter indexPath: IndexPath
    func itemDetail(with indexPath: IndexPath)
}

// MARK: - 單字記憶
final class WordMemoryViewController: UIViewController {
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    weak var mainViewDelegate: MainViewDelegate?
        
    private var canDelete = false
    
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
        
    func itemDetail(with indexPath: IndexPath) {
        guard let vocabularyList = WordMemoryItemCell.vocabularyList(with: indexPath) else { return }
        Utility.shared.displaySearchView(like: vocabularyList.word)
    }
}

// MARK: - UICollectionViewDragDelegate
extension WordMemoryViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return beginningItems(at: indexPath)
    }
}

// MARK: - UICollectionViewDropDelegate
extension WordMemoryViewController: UICollectionViewDropDelegate {
        
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {}
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return canHandleRule(session: session)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .cancel)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: any UIDropSession) {
        let backgroundColor: UIColor = .black.withAlphaComponent(0.2)
        collectionView.layer.backgroundColor = backgroundColor.cgColor
        canDelete = false
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: any UIDropSession) {
        let backgroundColor: UIColor = .clear
        collectionView.layer.backgroundColor = backgroundColor.cgColor
        canDelete = true
    }
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: any UIDropSession) {
        let backgroundColor: UIColor = .clear
        collectionView.layer.backgroundColor = backgroundColor.cgColor
        deleteItem()
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
        myCollectionView._dragAndDropdelegate(with: self)
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
    func suitableWidth(with size: CGSize, precent: CGFloat = 0.7) -> CGFloat {
        
        let width = (size.height > size.width) ? size.width : size.height
        return width * precent
    }
}

// MARK: - 拖放功能
private extension WordMemoryViewController {
    
    /// [按住鎖定將要開始拖放的Items](https://juejin.cn/post/6872696500284686350)
    /// - Parameter indexPath: IndexPath
    /// - Returns: [UIDragItem]
    func beginningItems(at indexPath: IndexPath) -> [UIDragItem] {
        
        let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        
        dragItem.localObject = WordMemoryItemCell.vocabularyListArray[indexPath.row]
        
        return [dragItem]
    }
    
    /// [可以有動作反應的規則](https://blog.csdn.net/u014029960/article/details/118371984)
    /// - Parameter session: UIDropSession
    /// - Returns: Bool
    func canHandleRule(session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    /// 刪除該項目
    func deleteItem() {
        
        if !canDelete { return }
        canDelete = false
        
        let indexPath = IndexPath(row: 0, section: 0)
        _ = WordMemoryItemCell.vocabularyListArray._popFirst()
                
        myCollectionView._performBatchUpdates({ collectionView in
            collectionView.deleteItems(at: [indexPath])
        }, completion: { collectionView in
            collectionView.reloadItems(at: [indexPath])
        })
    }
}
