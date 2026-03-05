//
//  RSSReaderViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2026/3/5.
//

import UIKit
import WWRssParser

// MARK: - RSS / Atom讀取器
final class RSSReaderViewController: UIViewController {
    
    @IBOutlet weak var rssImageView: UIImageView!
    @IBOutlet weak var rssTableView: UITableView!
    
    var bookmarkSite: BookmarkSite?
        
    weak var othersViewDelegate: OthersViewDelegate?
    
    private lazy var dataSource = dataSourceMaker()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearAction()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearAction()
    }
        
    @IBAction func reloadDataAction(_ sender: UIBarButtonItem) {
        reloadData(with: bookmarkSite)
    }
    
    deinit {
        othersViewDelegate = nil
        RSSReaderTableViewCell.items.removeAll()
    }
}

// MARK: - UITableViewDelegate
extension RSSReaderViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = RSSReaderTableViewCell.items[indexPath.row]
        title = item.title
    }
}

// MARK: - UITableViewDiffableDataSource
private extension RSSReaderViewController {
    
    /// 取代UITableViewDataSource
    /// - Returns: UITableViewDiffableDataSource<Int, WWRssParser.RssItem>
    func dataSourceMaker() -> UITableViewDiffableDataSource<Int, WWRssParser.RssItem> {
        
        let source = UITableViewDiffableDataSource<Int, WWRssParser.RssItem>(tableView: rssTableView) { tableView, indexPath, rss in
            
            let cell = tableView._reusableCell(at: indexPath) as RSSReaderTableViewCell
            
            cell.configure(with: indexPath)
            return cell
        }
        
        return source
    }
    
    /// 設定數值更新
    /// - Parameter animatingDifferences: Bool
    func applySnapshot(animatingDifferences: Bool = true) {
        
        let section: Int = 0
        var snapshot = NSDiffableDataSourceSnapshot<Int, WWRssParser.RssItem>()
        
        snapshot.appendSections([section])
        snapshot.appendItems(RSSReaderTableViewCell.items, toSection: section)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

// MARK: - 小工具
private extension RSSReaderViewController {
    
    /// 畫面將要出現的動作
    func viewWillAppearAction() {
        othersViewDelegate?.navigationBarHidden(false)
        othersViewDelegate?.tabBarHidden(true)
    }
    
    /// 畫面將要消失的動作
    func viewWillDisappearAction() {
        othersViewDelegate?.navigationBarHidden(false)
        othersViewDelegate?.tabBarHidden(false)
    }
}

// MARK: - 小工具
private extension RSSReaderViewController {
    
    /// 初始化設定
    func initSetting() {
        
        rssTableView.delegate = self
        reloadData(with: bookmarkSite)
        
        RSSReaderTableViewCell.expandRowsList = [:]
        RSSReaderTableViewCell.rssTableView = rssTableView
        RSSReaderTableViewCell.expandedCell(section: 0, row: 0)
    }
    
    /// 重新讀取資料
    /// - Parameter bookmarkSite: BookmarkSite?
    func reloadData(with bookmarkSite: BookmarkSite?) {
        
        guard let bookmarkSite = bookmarkSite else { return }
        
        title = bookmarkSite.title
        RSSReaderTableViewCell.expandRowsList = [:]
        RSSReaderTableViewCell.expandedCell(section: 0, row: 0)
        reloadData(urlString: bookmarkSite.url)
    }
    
    /// 重新讀取RSS
    /// - Parameter urlString: String
    func reloadData(urlString: String) {
        
        Utility.shared.displayHUD(with: .loading)
        
        Task {
            do {
                let xmlItems = try await WWRssParser.shared.parse(url: urlString).get()
                
                switch xmlItems {
                case .Atom(let items): RSSReaderTableViewCell.items = items
                case .RSS(let items): RSSReaderTableViewCell.items = items
                }
                                
                await MainActor.run { self.applySnapshot() }
                
                Utility.shared.flashHUD(with: .loading)
                
            } catch {
                Utility.shared.flashHUD(with: .fail)
            }
        }
    }
}

