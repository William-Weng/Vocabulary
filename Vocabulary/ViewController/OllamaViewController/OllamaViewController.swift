//
//  OllamViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2025/4/25.
//

import UIKit
import JavaScriptCore
import WebKit
import WWToast
import WWNetworking
import WWEventSource
import WWSimpleAI_Ollama
import WWSimpleAI_Perplexity
import WWKeyboardShadowView
import WWExpandableTextView
import WWUserDefaults

// MARK: - OllamaViewController
final class OllamaViewController: UIViewController {
    
    @IBOutlet weak var connentView: UIView!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var forgetMemoryButtonItem: UIBarButtonItem!
    @IBOutlet weak var ollamaModelOptionButtonItem: UIBarButtonItem!
    @IBOutlet weak var generateLiveButton: UIButton!
    @IBOutlet weak var myWebView: WKWebView!
    @IBOutlet weak var keyboardConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var keyboardShadowView: WWKeyboardShadowView!
    @IBOutlet weak var expandableTextView: WWExpandableTextView!
    
    @WWUserDefaults("IP") private var ip: String?
    @WWUserDefaults("Port") private var port: String?
    @WWUserDefaults("ChatModel") private var chatModel: String?
    @WWUserDefaults("LastContext") private var lastContext: String?
    @WWUserDefaults("ApiKey") private var apiKey: String?

    var agentType: Constant.AIAgentType = .ollama
    
    private var isConfigure = false
    private var botTimestamp: Int?
    private var responseString: String = ""
    private var ollamaBaseURL: String?
    
    private var isAnimationStop = false
    private var disappearImage: UIImage?
    private var gifImageView: UIImageView?
            
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?._tabBarHidden(true)
        animatedBackground(with: .ollama)
    }

    /// [View Controller 生命週期更新 - iOS 17](https://xiaozhuanlan.com/topic/0651384792)
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        if (isConfigure) { return }
        
        let isPerplexity = (agentType == .perplexity)
        
        initSetting()
        
        isConfigure = true
        
        forgetMemoryButtonItem.isHidden = isPerplexity
        ollamaModelOptionButtonItem.isHidden = isPerplexity
        ollamaModelOptionButtonItem.isEnabled = false
        
        title = "\(agentType)".capitalized
        
        switch agentType {
        case .ollama: configure(ip: ip, port: port, model: chatModel)
        case .perplexity: configure(apiKey: apiKey)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?._tabBarHidden(false)
        pauseBackgroundAnimation()
    }
    
    @IBAction func generateLiveDemo(_ sender: UIButton) {
        
        switch agentType {
        case .ollama: ollamaLiveAction()
        case .perplexity: perplexityAction()
        }
    }
    
    @IBAction func dissmissAction(_ sender: UIBarButtonItem) {
        AssistiveTouchHelper.shared.hiddenAction(false)
        dismiss(animated: true)
    }
    
    @IBAction func configureAction(_ sender: UIBarButtonItem) {
        
        let title = "\(agentType)".capitalized
        
        switch agentType {
        case .ollama: presentOllamaConfigureAlert(title: "\(title)參數設定")
        case .perplexity: presentPerplexityConfigureAlert(title: "\(title)參數設定")
        }
    }
    
    @IBAction func forgetMemory(_ sender: UIBarButtonItem) {
        forgetMemoryAction()
    }
    
    deinit {
        WWEventSource.shared.disconnect()
        stopSpeakText(with: myWebView)
        keyboardShadowView.unregister()
        removeGifBlock()
        myPrint("deinit => \(Self.self)")
    }
}

// MARK: - WWEventSource.Delegate
extension OllamaViewController: WWEventSource.Delegate {
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, any Error>) {
        sseStatusAction(eventSource: eventSource, result: result)
    }
    
    func serverSentEventsRawData(_ eventSource: WWEventSource, result: Result<WWEventSource.RawInformation, any Error>) {
        
        switch result {
        case .failure(let error): myPrint(error)
        case .success(let rawInformation): sseRawString(eventSource: eventSource, rawInformation: rawInformation)
        }
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, eventValue: WWEventSource.EventValue) {
        myPrint(eventValue)
    }
}

// MARK: - WWKeyboardShadowView.Delegate
extension OllamaViewController: WWKeyboardShadowView.Delegate {
    
    func keyboardViewChange(_ view: WWKeyboardShadowView, status: WWKeyboardShadowView.DisplayStatus, information: WWKeyboardShadowView.KeyboardInformation, height: CGFloat) -> Bool {
        
        switch status {
        case .willShow: scrollToBottom(with: myWebView)
        case .willHide, .didShow, .didHide: break
        }
        
        return true
    }
    
    func keyboardView(_ view: WWKeyboardShadowView, error: WWKeyboardShadowView.CustomError) {
        myPrint(error)
    }
}

// MARK: - 小工具
private extension OllamaViewController {
    
    /// 初始化設定
    func initSetting() {
        initKeyboardShadowViewSetting()
        initExpandableTextViewSetting()
        initWebView(filename: "chat.html")
    }
    
    /// 初始化鍵盤高度設定
    func initKeyboardShadowViewSetting() {

        let bottom = view.window?.safeAreaInsets.bottom ?? 0
        
        keyboardConstraintHeight.constant = bottom
        keyboardShadowView.configure(target: self, keyboardConstraintHeight: keyboardConstraintHeight, bottomType: .custom(44))
        keyboardShadowView.register()
    }
    
    /// 初始化設定可變高度的TextView (最高3行)
    func initExpandableTextViewSetting() {
        generateLiveButton(isEnabled: false)
        expandableTextView.configure(lines: 3, gap: 21)
        expandableTextView.setting(font: .systemFont(ofSize: 20), textColor: .white, backgroundColor: .white.withAlphaComponent(0.2), borderWidth: 1, borderColor: .white)
    }
    
    /// 初始化WebView
    /// - Parameter filename: HTML檔案名稱
    func initWebView(filename: String) {
        
        _ = myWebView._loadFile(filename: filename)
        
        myWebView.backgroundColor = .clear
        myWebView.scrollView.backgroundColor = .clear
        myWebView.isOpaque = false
    }
    
    /// 暫停背景動畫
    func pauseBackgroundAnimation() {
        disappearImage = myImageView.image
        isAnimationStop = true
    }
    
    /// 移除GIF動畫Block
    func removeGifBlock() {
        
        isAnimationStop = true
        gifImageView?.removeFromSuperview()
        gifImageView = nil
    }
}

// MARK: - gif工具
private extension OllamaViewController {
    
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
}

// MARK: - 小工具
private extension OllamaViewController {
    
    /// 參數設定 (Ollama)
    /// - Parameters:
    ///   - ip: String?
    ///   - port: String?
    ///   - model: String?
    func configure(ip: String?, port: String?, model: String?) {
        
        guard let ip, let port else { return }
        
        let baseURL = "http://\(ip):\(port)"
        ollamaBaseURL = baseURL
        
        WWSimpleAI.Ollama.shared.baseURL = baseURL
        if let model { WWSimpleAI.Ollama.shared.model = model }

        checkConfigure(isInitModel: true)
    }
    
    /// 初始化可用AI模型名稱
    func initModels() {
        
        Task {
            do {
                let _models = try await WWSimpleAI.Ollama.shared.models().get()
                let models = _models.map { $0.name.replacingOccurrences(of: ":latest", with: "") }.sorted()
                let actions = models.compactMap { self.modelActionsMaker($0) }
                let menu = UIMenu(title: "請選擇模型", options: .singleSelection, children: actions)
                
                ollamaModelOptionButtonItem.isEnabled = !models.isEmpty
                ollamaModelOptionButtonItem.menu = menu
                
            } catch {
                print(error)
            }
        }
    }
    
    /// AI模型選單
    /// - Parameter model: String
    /// - Returns: UIAction
    func modelActionsMaker(_ model: String) -> UIAction {
        
        let action = UIAction(title: model) { [unowned self] _ in
            WWSimpleAI.Ollama.shared.model = model
            chatModel = model
            checkConfigure(isInitModel: false)
        }
        
        return action
    }
    
    /// 參數設定 (Perplexity)
    /// - Parameters:
    ///   - apiKey: String?
    func configure(apiKey: String?) {
        
        guard let apiKey else { return }
        
        WWSimpleAI.Perplexity.shared.configure(apiKey: apiKey)
        generateLiveButton(isEnabled: true)
    }
    
    /// 及時回應 (SSE)
    /// - Parameters:
    ///   - prompt: 提問文字
    func liveGenerate(prompt: String) {
        
        guard let chatModel, let ollamaBaseURL else { return }
        
        let urlString = WWSimpleAI.Ollama.API.generate.url(for: ollamaBaseURL)
        let context = lastContext?._base64JSONObjectDecode() as [Int]?
        let fixPrompt = prompt.replacingOccurrences(of: "\n", with: " ")
        
        let json = """
        {
          "model": "\(chatModel)",
          "prompt": "\(fixPrompt)",
          "context": \(context ?? []),
          "stream": true
        }
        """
        
        myPrint(json)
        
        _ = WWEventSource.shared.connect(httpMethod: .POST, delegate: self, urlString: urlString, httpBodyType: .string(json))
    }
    
    /// 問問題 (執行SSE串流)
    func ollamaLiveAction() {
        
        let prompt = expandableTextView.text._removeWhitespacesAndNewlines()
        if (prompt.isEmpty) { return }
        
        view.endEditing(true)
        generateLiveAction(webView: myWebView, text: prompt)
    }
    
    /// 問問題 (直接回答)
    func perplexityAction() {
        
        let prompt = expandableTextView.text._removeWhitespacesAndNewlines()
        if (prompt.isEmpty) { return }
        
        view.endEditing(true)
        generateAction(webView: myWebView, text: prompt)
    }
}

// MARK: - SSE (Server Sent Events - 單方向串流)
private extension OllamaViewController {
    
    /// SSE狀態處理
    /// - Parameters:
    ///   - eventSource: WWEventSource
    ///   - result: Result<WWEventSource.Constant.ConnectionStatus, any Error>
    func sseStatusAction(eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, any Error>) {
        
        switch result {
        case .failure(let error):
            self.responseString = ""
            self.generateLiveButton(isEnabled: true)
            WWToast.shared.makeText("\(error.localizedDescription)")
            
        case .success(let status):
            switch status {
            case .connecting:
                self.expandableTextView.text = ""
                self.expandableTextView.updateHeight()
                self.generateLiveButton(isEnabled: false)
            case .open: break
            case .closed:
                self.responseString = ""
                self.generateLiveButton(isEnabled: true)
            }
        }
    }
    
    /// SSE資訊處理
    /// - Parameters:
    ///   - eventSource: WWEventSource
    ///   - rawInformation: WWEventSource.RawInformation
    func sseRawString(eventSource: WWEventSource, rawInformation: WWEventSource.RawInformation) {
        
        defer { refreashWebSlaveCell(with: myWebView, botTimestamp: botTimestamp, responseString: responseString) }
        
        if rawInformation.response.statusCode != 200 {
            responseString = rawInformation.data._string() ?? "\(rawInformation.response.statusCode)"; return
        }
        
        guard let jsonObject = rawInformation.data._jsonObject() as? [String: Any],
              let response = jsonObject["response"] as? String,
              let isDone = jsonObject["done"] as? Bool
        else {
            return
        }
        
        responseString += response
        
        if isDone {
            let context = jsonObject["context"] as? [Int]
            lastContext = context?._base64JSONDataString()
        }
    }
}

// MARK: - SSE for WKWebView (Server Sent Events - 單方向串流)
private extension OllamaViewController {
    
    /// 顯示Markdown文字
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - botTimestamp: TimeInterval?
    ///   - responseString: String
    func refreashWebSlaveCell(with webView: WKWebView, botTimestamp: Int?, responseString: String) {
        
        guard let base64Encoded = responseString._base64Encoded(),
              let botTimestamp = botTimestamp
        else {
            return
        }
        
        let jsCode = """
            window.displayMarkdown("\(base64Encoded)", \(botTimestamp))
        """
        
        webView._evaluateJavaScript(script: jsCode) { result in
            
            switch result {
            case .failure(let error): myPrint(error)
            case .success(let value): if let value { myPrint(value) }
            }
        }
    }
        
    /// 使用WKWebView去執行SSE問問題
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - text: String
    func generateLiveAction(webView: WKWebView, text: String) {
        
        appendRole(with: webView, role: .user, message: text) { _ in
            
            self.appendRole(with: webView, role: .bot, message: "") { dict in
                
                guard let botTimestamp = dict["timestamp"] else { return }
                
                self.botTimestamp = botTimestamp
                self.liveGenerate(prompt: text)
            }
        }
    }
    
    /// 使用WKWebView顯示回答
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - text: String
    func generateAction(webView: WKWebView, text: String) {
        
        expandableTextView.text = ""
        appendRole(with: webView, role: .user, message: text) { [unowned self] _ in
            
            appendRole(with: webView, role: .bot, message: "") { dict in
                
                guard let botTimestamp = dict["timestamp"] else { return }
                
                self.botTimestamp = botTimestamp
                
                Task {
                    do {
                        guard let responseString = try await WWSimpleAI.Perplexity.shared.chat(text: text).get() else { return }
                        self.refreashWebSlaveCell(with: webView, botTimestamp: botTimestamp, responseString: responseString)
                    } catch {
                        myPrint(error)
                        Utility.shared.flashHUD(with: .fail)
                    }
                }
            }
        }
    }
    
    /// 加上角色Cell
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - role: Constant.AgentRoleType
    ///   - message: String
    ///   - result: ([String: Int]) -> Void
    func appendRole(with webView: WKWebView, role: Constant.AgentRoleType, message: String = "",  result: @escaping (([String: Int]) -> Void)) {
                
        let jsCode = """
            window.appendRole("\(role)", "\(message._base64Encoded() ?? "???")")
        """
        
        webView._evaluateJavaScript(script: jsCode) { _result_ in
            
            switch _result_ {
            case .failure(let error): myPrint(error)
            case .success(let dict):
                guard let dict = dict as? [String: Int] else { return }
                return result(dict)
            }
        }
    }
    
    /// 將網頁拉到最底部
    /// - Parameter webView: WKWebView
    func scrollToBottom(with webView: WKWebView) {
        
        let jsCode = """
            window.scrollToBottom()
        """
        
        webView._evaluateJavaScript(script: jsCode) { result in
            
            switch result {
            case .failure(let error): myPrint(error)
            case .success(let value): myPrint(value ?? "")
            }
        }
    }
    
    /// 停止文字閱讀
    /// - Parameter webView: WKWebView
    func stopSpeakText(with webView: WKWebView) {
        
        let jsCode = """
            window.stopSpeakText()
        """
        
        webView._evaluateJavaScript(script: jsCode) { result in
            
            switch result {
            case .failure(let error): myPrint(error)
            case .success(let value): if let value { myPrint(value) }
            }
        }
    }
    
    /// [把Bot的記憶清除](https://tenor.com/view/downcast-face-phew-asking-embarrassed-where-gif-6508259955425936045)
    func forgetMemoryAction() {
        Utility.shared.flashHUD(with: .forgot)
        lastContext = nil
    }
    
    /// 顯示Ollama參數設定的UIAlertController
    /// - Parameters:
    ///   - title: String
    ///   - message: String?
    func presentOllamaConfigureAlert(title: String, message: String? = nil) {
        
        let alertController = UIAlertController._build(title: title, message: message)

        alertController.addTextField { (textField) in textField.text = self.ip; textField.placeholder = "127.0.0.1" }
        alertController.addTextField { (textField) in textField.text = self.port; textField.placeholder = "11434" }
        
        let sureAction = UIAlertAction(title: "確定", style: .destructive) { aciton in
            guard let textFields = alertController.textFields else { return }
            self.ollamaConfigure(textFields: textFields)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in }
        
        alertController.addAction(sureAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }
    
    /// 顯示Perplexity參數設定的UIAlertController
    /// - Parameters:
    ///   - title: String
    ///   - message: String?
    func presentPerplexityConfigureAlert(title: String, message: String? = nil) {
        
        let alertController = UIAlertController._build(title: title, message: message)

        alertController.addTextField { (textField) in textField.text = self.apiKey; textField.placeholder = "pplx-<Your-API-Key>" }
        
        let sureAction = UIAlertAction(title: "確定", style: .destructive) { aciton in
            guard let textFields = alertController.textFields else { return }
            self.perplexityConfigure(textFields: textFields)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in }
        
        alertController.addAction(sureAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }
    
    /// Ollama參數設定
    /// - Parameter textFields: [UITextField]
    func ollamaConfigure(textFields: [UITextField]) {
                
        for (index, textField) in textFields.enumerated() {
            
            guard let type = Constant.TextFieldType(rawValue: index),
                  let value = textField.text
            else {
                return
            }
            
            switch type {
            case .ip: ip = value
            case .port: port = value
            case .chatModel: chatModel = value
            }
        }
        
        configure(ip: ip, port: port, model: chatModel)
    }
    
    /// Perplexity參數設定
    /// - Parameter textFields: [UITextField]
    func perplexityConfigure(textFields: [UITextField]) {
        
        guard let apiKey = textFields.first?.text else { return }
        
        self.apiKey = apiKey
        WWSimpleAI.Perplexity.shared.configure(apiKey: apiKey)
        generateLiveButton(isEnabled: true)
    }
    
    /// 檢測參數設定是否正確
    func checkConfigure(isInitModel: Bool) {
        
        guard let ollamaBaseURL else { return }
        
        let alearTitle = "\(agentType)".capitalized
        
        _ = WWNetworking.shared.request(urlString: WWSimpleAI.Ollama.API.version.url(for: ollamaBaseURL), timeout: 5) { [unowned self] result in
            
            switch result {
            case .failure(let error): self.presentOllamaConfigureAlert(title: "\(alearTitle)參數設定", message: error.localizedDescription)
            case .success(let info):
                
                guard let data = info.data,
                      let jsonObject = data._jsonObject() as? [String: Any],
                      let version = jsonObject["version"]
                else {
                    self.generateLiveButton(isEnabled: false); return
                }
                
                let text = "您使用的Ollama版本為：\(version)，模型為：\(WWSimpleAI.Ollama.shared.model)"
                
                if (isInitModel) { initModels() }
                
                title = WWSimpleAI.Ollama.shared.model
                generateLiveButton(isEnabled: true)
                WWToast.shared.makeText(text)
            }
        }
    }
    
    /// 設定generateLiveButton是否可以使用
    /// - Parameter isEnabled: Bool
    func generateLiveButton(isEnabled: Bool) {
        generateLiveButton.isEnabled = isEnabled
    }
}
