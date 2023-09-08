//
//  PaletteViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/9/8.
//

import UIKit

// MARK: - 調色盤
final class PaletteViewController: UIViewController {

    typealias PaletteInformation = (color: UIColor?, backgroundColor: UIColor?)
    typealias SelectedPaletteInformation = (indexPath: IndexPath?, color: UIColor?)

    @IBOutlet weak var myTableView: UITableView!
    
    private var didSelectPaletteInfo: SelectedPaletteInformation = (nil, nil)
    private var paletteInformation: [IndexPath: PaletteInformation] = [:]
    private var colorPicker: UIColorPickerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    @IBAction func changeSystemColor(_ sender: UIBarButtonItem) {
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PaletteViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return PaletteTableViewCell.colorKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let settings = PaletteTableViewCell.colorKeys[safe: section],
              let informations = settings.informations()
        else {
            return 0
        }
        
        return informations.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return paletteTableViewHeader(tableView, viewForHeaderInSection: section)
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = paletteTableViewCell(tableView, cellForRowAt: indexPath)
        cell.configure(with: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return palettePicker(with: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension PaletteViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        didSelectPaletteInfo.color = viewController.selectedColor
    }
        
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        colorPickerViewControllerDidFinishAction(viewController)
    }
}

// MARK: - 小工具
private extension PaletteViewController {
    
    /// 初始化設定
    func initSetting() {
        myTableView._delegateAndDataSource(with: self)
        initPalettePicker()
    }
    
    /// 初始化調色盤
    func initPalettePicker() {
        
        let colorPicker = UIColorPickerViewController._build(delegate: self)
        colorPicker.supportsAlpha = false
        
        self.colorPicker = colorPicker
    }
    
    /// 調色盤Cell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: PaletteTableViewCell
    func paletteTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> PaletteTableViewCell {
        
        let cell = tableView._reusableCell(at: indexPath) as PaletteTableViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 調色盤Header
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - section: Int
    /// - Returns: UIView
    func paletteTableViewHeader(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView {
        
        let headerView = UIView()
        let label = UILabel()
        
        label.frame = CGRect(x: 15, y: 5, width: tableView.frame.size.width - 100, height: 20)
        label.text = groupTitle(with: section)
        label.textColor = .black
        
        headerView.backgroundColor = .clear
        headerView.addSubview(label)
        
        return headerView
    }
    
    /// 設定顏色群組的標題文字
    /// - Parameter section: Int
    /// - Returns: String?
    func groupTitle(with section: Int) -> String? {
        
        guard let colorKey = PaletteTableViewCell.colorKeys[safe: section] else { return nil }
        return colorKey.name()
    }
}

// MARK: - 小工具
private extension PaletteViewController {
        
    /// 彈出調色盤Picker
    /// - Parameter indexPath: IndexPath?
    func palettePicker(with indexPath: IndexPath) {
                
        guard let colorPicker = colorPicker,
              let informations = PaletteTableViewCell.colorKeys[safe: indexPath.section]?.informations(),
              let info = informations[safe: indexPath.row]
        else {
            return
        }

        didSelectPaletteInfo.indexPath = indexPath
        colorPicker.selectedColor = UIColor(rgb: info.backgroundColor)
        
        present(colorPicker, animated: true)
    }
    
    /// 調色盤顏色選好後的動作
    /// - Parameter viewController: UIColorPickerViewController
    func colorPickerViewControllerDidFinishAction(_ viewController: UIColorPickerViewController) {
        
        guard let didSelectIndexPath = didSelectPaletteInfo.indexPath,
              let cell = myTableView.cellForRow(at: didSelectIndexPath) as? PaletteTableViewCell,
              let didSelectColor = didSelectPaletteInfo.color
        else {
            return
        }
        
        cell.myView.backgroundColor = didSelectColor
        didSelectPaletteInfo = (nil, nil)
    }
}
