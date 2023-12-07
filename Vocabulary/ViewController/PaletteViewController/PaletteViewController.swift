//
//  PaletteViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/9/8.
//

import UIKit
import WWJavaScriptContext
import WWFloatingViewController

// MARK: - OthersViewDelegate
protocol PaletteViewDelegate {
    
    func palette(with indexPath: IndexPath, colorType: PaletteViewController.ColorType, info: Constant.PaletteInformation)
    func tabBarHidden(_ isHidden: Bool)
    func gallery(with indexPath: IndexPath)
    func animation(with indexPath: IndexPath, filename: String?)
}

// MARK: - 相關設定 (調色盤 / 動畫設定)
final class PaletteViewController: UIViewController {
    
    /// 要更新的顏色 (文字色 / 背景色)
    enum ColorType {
        case text
        case background
    }
        
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myTableView: UITableView!
    
    var othersViewDelegate: OthersViewDelegate?
    
    private var isAnimationStop = false
    private var isGoToPreviousPage = false
    private var disappearImage: UIImage?
    private var didSelectPaletteInfo: Constant.SelectedPaletteInformation = (nil, nil, nil)
    private var colorPicker: UIColorPickerViewController?
    private var scriptKey = "settingsJSON"
    private var scriptContext: WWJavaScriptContext?
    private var galleryViewController: GalleryViewController?
    private var floatingViewController: WWFloatingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
        initScriptContext()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearAction()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearAction()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if (parent == nil && !isGoToPreviousPage) { previousPageHint(with: "記錄設定值了嗎？", message: nil) }
    }
    
    @IBAction func changeSystemColor(_ sender: UIBarButtonItem) {
        paletteSettingHint(target: self, title: "請選擇功能", message: nil, barButtonItem: sender)
    }
    
    deinit {
        NotificationCenter.default._remove(observer: self, name: .viewDidTransition)
        PaletteTableViewCell.colorSettings = []
        scriptContext = nil
        othersViewDelegate = nil
        myPrint("\(Self.self) init")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PaletteViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return PaletteTableViewCell.colorSettings.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settings = PaletteTableViewCell.colorSettings(with: section) else { return 0 }
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return paletteTableViewHeader(tableView, viewForHeaderInSection: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = paletteTableViewCell(tableView, cellForRowAt: indexPath)
        cell.configure(with: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        animtionWillDisplay(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        animtionDidEndDisplaying(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48.0
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension PaletteViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        didSelectPaletteInfo.color = viewController.selectedColor
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        colorPickerViewControllerDidFinishAction(with: myTableView, info: didSelectPaletteInfo)
    }
}

// MARK: - PaletteViewDelegate
extension PaletteViewController: PaletteViewDelegate {
    
    func palette(with indexPath: IndexPath, colorType: ColorType, info: Constant.PaletteInformation) {
        palettePicker(with: indexPath, colorType: colorType, info: info)
    }
    
    func tabBarHidden(_ isHidden: Bool) {
        tabBarHiddenAction(isHidden)
    }
    
    func gallery(with indexPath: IndexPath) {
        galleryAction(with: indexPath)
    }
    
    func animation(with indexPath: IndexPath, filename: String?) {
        animationAction(with: indexPath, filename: filename)
        floatingViewController?.dismissViewController()
    }
}

// MARK: - 小工具
private extension PaletteViewController {
    
    /// 初始化設定
    func initSetting() {
        
        PaletteTableViewCell.paletteViewDelegate = self
        PaletteTableViewCell.colorSettings = Constant.SettingsColorKey.allCases.compactMap { $0.informations() }
        
        myTableView._delegateAndDataSource(with: self)
        updateTableViewBottomActionNotification()
        initPalettePicker()
    }
    
    /// 修正Tabbar對TableView的Bottom影響
    func fixContentInsetForSafeArea() {
        
        guard let frame = navigationController?.navigationBar.frame else { return }
        myTableView._fixContentInsetForSafeArea(top: frame.minY + frame.height, bottom: 0, scrollTo: IndexPath(row: 0, section: 0))
    }
    
    /// 更新TableView的Bottom
    func updateTableViewBottomActionNotification() {
        
        NotificationCenter.default._register(name: .viewDidTransition) { [weak self] _ in
            guard let this = self else { return }
            this.fixContentInsetForSafeArea()
        }
    }
    
    /// 初始化調色盤
    func initPalettePicker() {
        
        let colorPicker = UIColorPickerViewController._build(delegate: self)
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
        
        let header = PaletteHeader(frame: tableView.frame)
        header.configure(with: section)
        
        return header
    }
}

// MARK: - 小工具
private extension PaletteViewController {
        
    /// 彈出調色盤Picker
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - colorType: PaletteViewController.ColorType
    ///   - info: Constant.PaletteInformation
    func palettePicker(with indexPath: IndexPath, colorType: PaletteViewController.ColorType, info: Constant.PaletteInformation) {
        
        guard let colorPicker = colorPicker,
              let color = info.color,
              let backgroundColor = info.backgroundColor
        else {
            return
        }
        
        switch colorType {
        case .text: colorPicker.selectedColor = color
        case .background: colorPicker.selectedColor = backgroundColor
        }
        
        didSelectPaletteInfo = (indexPath, colorType, nil)
        present(colorPicker, animated: true)
    }
    
    /// 調色盤顏色選好後的動作 (記錄數值)
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - info: Constant.SelectedPaletteInformation
    func colorPickerViewControllerDidFinishAction(with tableView: UITableView, info: Constant.SelectedPaletteInformation) {
        
        defer { didSelectPaletteInfo = (nil, nil, nil) }
        
        guard let indexPath = info.indexPath,
              var setting = PaletteTableViewCell.colorSetting(with: indexPath),
              let color = info.color,
              let type = info.type,
              let cell = visibleCell(tableView, cellForRowAt: indexPath)
        else {
            return
        }
        
        switch type {
        case .text:
            cell.myLabel.textColor = color
            setting.color = color.cgColor._hexString() ?? setting.color
        case .background:
            cell.myView.backgroundColor = color
            setting.backgroundColor = color.cgColor._hexString() ?? setting.backgroundColor
        }
        
        PaletteTableViewCell.colorSettings[indexPath.section][indexPath.row] = setting
        settingsJSONAction(with: indexPath)
    }
    
    /// 選擇GIF動畫後的設定
    /// - Parameter indexPath: IndexPath
    func galleryAction(with indexPath: IndexPath) {
        
        let galleryViewController = UIStoryboard._instantiateViewController() as GalleryViewController
        
        galleryViewController.indexPath = indexPath
        galleryViewController.paletteViewDelegate = self
        self.galleryViewController = galleryViewController
        
        presentSearchVocabularyViewController(target: self, currentView: galleryViewController.view)
    }
    
    /// 找出可以要設定的Cell
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: PaletteTableViewCell?
    func visibleCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> PaletteTableViewCell? {
        
        let cell = myTableView.visibleCells.first { cell in
            
            guard let cell = cell as? CellReusable,
                  cell.indexPath == indexPath
            else {
                return false
            }
            
            return true
        }
        
        return cell as? PaletteTableViewCell
    }
    
    /// 產生WWFloatingViewController
    /// - Parameters:
    ///   - target: UIViewController
    ///   - currentView: UIView?
    func presentSearchVocabularyViewController(target: UIViewController, currentView: UIView?) {
        
        let floatingViewController = WWFloatingView.shared.maker()
        floatingViewController.configure(animationDuration: 0.25, backgroundColor: .black.withAlphaComponent(0.1), multiplier: 0.55, completePercent: 0.5, currentView: currentView)
        self.floatingViewController = floatingViewController
        
        target.present(floatingViewController, animated: false)
    }
    
    /// 畫面將要出現的動作
    func viewWillAppearAction() {
        othersViewDelegate?.navigationBarHidden(false)
        othersViewDelegate?.tabBarHidden(true)
        animatedBackground(with: .palette)
    }
    
    /// 畫面將要消失的動作
    func viewWillDisappearAction() {
        othersViewDelegate?.navigationBarHidden(false)
        othersViewDelegate?.tabBarHidden(false)
        pauseBackgroundAnimation()
    }
    
    /// 設定TabBar顯示與否功能
    /// - Parameters:
    ///   - isHidden: Bool
    func tabBarHiddenAction(_ isHidden: Bool) {
        
        guard let tabBarController = tabBarController else { return }
        
        NotificationCenter.default._post(name: .viewDidTransition, object: isHidden)
        tabBarController._tabBarHidden(isHidden, duration: Constant.duration)
    }
    
    /// 動畫背景設定
    /// - Parameter type: Constant.AnimationGifType
    func animatedBackground(with type: Constant.AnimationGifType) {
        
        guard let gifUrl = type.fileURL(with: .background) else { return }
        
        isAnimationStop = false
        
        _ = myImageView._GIF(url: gifUrl) { [weak self] result in
            
            guard let this = self else { return }
            
            switch result {
            case .failure(let error): myPrint(error)
            case .success(let info):
                info.pointer.pointee = this.isAnimationStop
                if (this.isAnimationStop) { this.myImageView.image = this.disappearImage }
            }
        }
    }
    
    /// 暫停背景動畫
    func pauseBackgroundAnimation() {
        disappearImage = myImageView.image
        isAnimationStop = true
    }
    
    /// [調色盤設定功能Alert](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/在-iphone-ipad-上顯示-popover-彈出視窗-ac196732e557)
    /// - Parameters:
    ///   - sender: UIBarButtonItem
    ///   - title: String?
    ///   - message: String?
    func paletteSettingHint(target: UIViewController, title: String? = nil, message: String? = nil, barButtonItem: UIBarButtonItem? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let actionSetting = UIAlertAction(title: "設定", style: .default) { [weak self] _ in
            
            guard let this = self else { return }
            
            let result = this.changeSettingsJSON()
            this.settingsActionResult(result)
        }
        
        let actionRestore = UIAlertAction(title: "還原", style: .destructive) { [weak self] _ in
            
            guard let this = self else { return }
            
            let result = this.removeSettingsJSON()
            this.settingsActionResult(result)
        }
        
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) { _ in }
        
        alertController.addAction(actionSetting)
        alertController.addAction(actionRestore)
        alertController.addAction(actionCancel)
        
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = barButtonItem
        
        target.present(alertController, animated: true, completion: nil)
    }
    
    /// 回到上一頁的提示視窗
    /// - Parameters:
    ///   - title: String?
    ///   - message: String?
    func previousPageHint(with title: String?, message: String?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            guard let this = self else { return }
            this.isGoToPreviousPage = false
        }
        
        let actionSelectDatabase = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            guard let this = self else { return }
            this.isGoToPreviousPage = true
            this.navigationController?.popViewController(animated: true)
        }
        
        alertController.addAction(actionCancel)
        alertController.addAction(actionSelectDatabase)

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - JavaScriptContext (雖可恥但有用)
private extension PaletteViewController {
    
    /// 使用JavaScriptContext處理Settings.json
    func initScriptContext() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              var jsonString = appDelegate.parseDefaultSettingsJSON(with: Constant.settingsJSON)
        else {
            return
        }
        
        if let _jsonString = appDelegate.parseUserSettingsJSON(with: Constant.settingsJSON) { jsonString = _jsonString }
        let script = "var \(scriptKey) = \(jsonString)"
        
        scriptContext = WWJavaScriptContext.build(script: script)
    }
    
    /// 記錄調整後的數值 => English.settings.vocabularyLevel
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - filename: String?
    func settingsJSONAction(with indexPath: IndexPath, filename: String? = nil) {
        
        guard let tableName = Constant.tableName,
              let settingsColorKey = Constant.SettingsColorKey.allCases[safe: indexPath.section],
              let scriptContext = scriptContext,
              let setting = PaletteTableViewCell.colorSetting(with: indexPath),
              let paramater = Optional.some("\(scriptKey).\(tableName).settings.\(settingsColorKey)")
        else {
            return
        }
        
        var settingScript = ""
        
        if setting is AnimationSettings, let filename = filename {
            settingScript = """
            \(paramater).\(setting.key).filename = "\(filename)"
            """
        } else {
            settingScript = """
            \(paramater).\(setting.key).color = "\(setting.color)"
            \(paramater).\(setting.key).backgroundColor = "\(setting.backgroundColor)"
            """
        }
        
        _ = scriptContext.evaluateScript(settingScript)
    }
    
    /// 改變 / 記錄 / 刪除使用者自訂設定值的結果動作顯示
    /// => 成功就重新讀資料設定 / 失敗就不處理
    /// - Parameter result: Result<Bool, Error>
    func settingsActionResult(_ result: Result<Bool, Error>) {
        
        switch result {
        case .failure(let error): myPrint(error); Utility.shared.flashHUD(with: .fail)
        case .success(let isSuccess):
            if (!isSuccess) { Utility.shared.flashHUD(with: .fail); return }
            Utility.shared.initDictionarySettings()
        }
    }
    
    /// 改變 / 記錄使用者自訂的設定值 => Settings.json
    /// - Returns: Result<Bool, Error>
    func changeSettingsJSON() -> Result<Bool, Error> {
        
        guard let scriptContext = scriptContext,
              let dictionary = scriptContext.evaluateScript("\(scriptKey)")?.toDictionary(),
              let jsonString = dictionary._jsonData()?._string(),
              let url = FileManager.default._documentDirectory()?.appendingPathComponent(Constant.settingsJSON)
        else {
            return .failure(Constant.MyError.isEmpty)
        }
        
        return FileManager.default._writeText(to: url, text: jsonString)
    }
    
    /// 刪除使用者自訂的設定值 => Settings.json
    /// - Returns: Result<Bool, Error>
    func removeSettingsJSON() -> Result<Bool, Error> {
        
        guard let url = FileManager.default._documentDirectory()?.appendingPathComponent(Constant.settingsJSON) else { return .failure(Constant.MyError.isEmpty) }
        return FileManager.default._removeFile(at: url)
    }
}

// MARK: - 處理GIF動畫效能問題
private extension PaletteViewController {
    
    /// GIF動畫Cell要出現時的處理
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - cell: UITableViewCell
    ///   - indexPath: IndexPath
    func animtionWillDisplay(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let cell = cell as? PaletteTableViewCell,
              let colorKey = PaletteHeader.groupColorKey(with: indexPath.section),
              let key = Constant.SettingsColorKey.findKey(colorKey.value())
        else {
            return
        }
        
        switch key {
        case .sentenceSpeech, .vocabularyLevel, .wordSpeech: break
        case .animation, .background:
            cell.initGifBlockSetting()
            cell.executeAnimation(with: indexPath)
        }
    }
    
    /// GIF動畫Cell消失後的處理
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - cell: UITableViewCell
    ///   - indexPath: IndexPath
    func animtionDidEndDisplaying(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let cell = cell as? PaletteTableViewCell else { return }
        cell.removeGifBlock()
    }
    
    /// 動畫取選後的更新動作
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - filename: String?
    func animationAction(with indexPath: IndexPath, filename: String?) {
        
        guard let filename = filename,
              let cell = visibleCell(myTableView, cellForRowAt: indexPath),
              var setting = PaletteTableViewCell.colorSetting(with: indexPath) as? AnimationSettings
        else {
            return
        }
        
        setting.filename = filename
        
        if let setting = setting as? ColorSettings {
            
            PaletteTableViewCell.colorSettings[indexPath.section][indexPath.row] = setting
            settingsJSONAction(with: indexPath, filename: filename)
            animtionDidEndDisplaying(myTableView, willDisplay: cell, forRowAt: indexPath)
            animtionWillDisplay(myTableView, willDisplay: cell, forRowAt: indexPath)
        }
    }
}
