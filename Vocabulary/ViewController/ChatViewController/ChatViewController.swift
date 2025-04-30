//
//  ChatViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2025/4/25.
//

import UIKit
import JavaScriptCore
import WebKit
import WWHUD
import WWToast
import WWNetworking
import WWEventSource
import WWSimpleAI_Ollama
import WWKeyboardShadowView
import WWExpandableTextView
import WWUserDefaults

// MARK: - ChatViewController
final class ChatViewController: UIViewController {
    
    @IBOutlet weak var connentView: UIView!
    @IBOutlet weak var generateLiveButton: UIButton!
    @IBOutlet weak var myWebView: WKWebView!
    @IBOutlet weak var keyboardConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var keyboardShadowView: WWKeyboardShadowView!
    @IBOutlet weak var expandableTextView: WWExpandableTextView!
    
    @WWUserDefaults("IP") private var ip: String?
    @WWUserDefaults("Port") private var port: String?
    @WWUserDefaults("ChatModel") private var chatModel: String?
    @WWUserDefaults("LastContext") private var lastContext: String?
    
    weak var sentenceViewDelegate: SentenceViewDelegate?
    
    private var isConfigure = false
    private var botTimestamp: Int?
    private var responseString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        if (isConfigure) { return }
        
        isConfigure = true
        configure(ip: ip, port: port, model: chatModel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sentenceViewDelegate?.tabBarHidden(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sentenceViewDelegate?.tabBarHidden(false)
    }
    
    @IBAction func generateLiveDemo(_ sender: UIButton) {
        generateLiveAction()
    }
    
    @IBAction func configureAction(_ sender: UIBarButtonItem) {
        presentOllamaConfigureAlert()
    }
    
    @IBAction func forgetMemory(_ sender: UIBarButtonItem) {
        forgetMemoryAction()
    }
    
    deinit {
        WWEventSource.shared.disconnect()
        keyboardShadowView.unregister()
        sentenceViewDelegate = nil
        myPrint("deinit => \(Self.self)")
    }
}

// MARK: - WWEventSource.Delegate
extension ChatViewController: WWEventSource.Delegate {
    
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
extension ChatViewController: WWKeyboardShadowView.Delegate {
    
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
private extension ChatViewController {
    
    /// 初始化設定
    func initSetting() {
        initKeyboardShadowViewSetting()
        initExpandableTextViewSetting()
        initWebView(filename: "index.html")
        sentenceViewDelegate?.tabBarHidden(true)
    }
    
    /// 初始化鍵盤高度設定
    func initKeyboardShadowViewSetting() {
        
        let bottom = tabBarController?.view.safeAreaInsets.bottom ?? 0.0
        
        keyboardConstraintHeight.constant = bottom
        keyboardShadowView.configure(target: self, keyboardConstraintHeight: keyboardConstraintHeight, bottomType: .custom(bottom))
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
}

// MARK: - 小工具
private extension ChatViewController {
    
    /// 參數設定
    /// - Parameters:
    ///   - ip: String?
    ///   - port: String?
    ///   - model: String?
    func configure(ip: String?, port: String?, model: String?) {
        
        guard let ip, let port, let model else { return }
        
        WWSimpleAI.Ollama.configure(baseURL: "http://\(ip):\(port)", model: model)
        checkConfigure()
    }
    
    /// 及時回應 (SSE)
    /// - Parameters:
    ///   - prompt: 提問文字
    func liveGenerate(prompt: String) {
        
        guard let chatModel else { return }
        
        let urlString = WWSimpleAI.Ollama.API.generate.url()
        let context = lastContext?._base64JSONObjectDecode() as [Int]?
        
        let json = """
        {
          "model": "\(chatModel)",
          "prompt": "\(prompt)",
          "context": \(context ?? []),
          "stream": true
        }
        """
        
        myPrint(json)
        
        _ = WWEventSource.shared.connect(httpMethod: .POST, delegate: self, urlString: urlString, httpBodyType: .string(json))
    }
    
    /// 問問題 (執行SSE串流)
    func generateLiveAction() {
        
        let text = expandableTextView.text._removeWhitespacesAndNewlines()
        if (text.isEmpty) { return }
        
        generateLiveAction(webView: myWebView, text: text)
    }
}

// MARK: - SSE (Server Sent Events - 單方向串流)
private extension ChatViewController {
    
    /// SSE狀態處理
    /// - Parameters:
    ///   - eventSource: WWEventSource
    ///   - result: Result<WWEventSource.Constant.ConnectionStatus, any Error>
    func sseStatusAction(eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, any Error>) {
        
        DispatchQueue.main.async {
            
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
    }
    
    /// SSE資訊處理
    /// - Parameters:
    ///   - eventSource: WWEventSource
    ///   - rawInformation: WWEventSource.RawInformation
    func sseRawString(eventSource: WWEventSource, rawInformation: WWEventSource.RawInformation) {
        
        defer {
            DispatchQueue.main.async { [unowned self] in refreashWebSlaveCell(with: myWebView, botTimestamp: botTimestamp, responseString: responseString) }
        }
        
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
private extension ChatViewController {
    
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
            case .success(let value): myPrint(value ?? "")
            }
        }
    }
    
    /// 使用WKWebView去執行SSE問問題
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - text: String
    func generateLiveAction(webView: WKWebView, text: String) {
        
        appendRole(with: webView, role: "user", message: text) { _ in
            
            self.appendRole(with: webView, role: "bot", message: "") { dict in
                
                guard let botTimestamp = dict["timestamp"] else { return }
                
                self.botTimestamp = botTimestamp
                self.liveGenerate(prompt: text)
            }
        }
    }
    
    /// 加上角色Cell
    /// - Parameters:
    ///   - webView: WKWebView
    ///   - role: String
    ///   - message: String
    ///   - result: ([String: Int]) -> Void
    func appendRole(with webView: WKWebView, role: String, message: String = "",  result: @escaping (([String: Int]) -> Void)) {
                
        let jsCode = """
            window.appendRole("\(role)", "\(message)")
        """
        
        webView._evaluateJavaScript(script: jsCode) { _result_ in
            
            switch _result_ {
            case .failure(let error): print(error)
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
    
    /// [把Bot的記憶清除](https://tenor.com/view/downcast-face-phew-asking-embarrassed-where-gif-6508259955425936045)
    func forgetMemoryAction() {
        Utility.shared.flashHUD(with: .forgot)
        lastContext = nil
    }
    
    /// 顯示Ollama參數設定的UIAlertController
    /// - Parameters:
    ///   - title: String
    ///   - message: String?
    func presentOllamaConfigureAlert(title: String = "本機Ollama參數設定", message: String? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in textField.text = self.ip; textField.placeholder = "127.0.0.1" }
        alertController.addTextField { (textField) in textField.text = self.port; textField.placeholder = "11434" }
        alertController.addTextField { (textField) in textField.text = self.chatModel; textField.placeholder = "llama3.2" }
        
        let sureAction = UIAlertAction(title: "確定", style: .destructive) { aciton in
            guard let textFields = alertController.textFields else { return }
            self.ollamaConfigure(textFields: textFields)
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
            case .ip: self.ip = value
            case .port: self.port = value
            case .chatModel: self.chatModel = value
            }
        }
        
        self.configure(ip: self.ip, port: self.port, model: self.chatModel)
    }
    
    /// 檢測參數設定是否正確
    func checkConfigure() {
        
        _ = WWNetworking.shared.request(urlString: WWSimpleAI.Ollama.API.version.url(), timeout: 5) { result in
            
            DispatchQueue.main.async {
                
                switch result {
                case .failure(let error): self.presentOllamaConfigureAlert(message: error.localizedDescription)
                case .success(let info):
                    
                    guard let data = info.data,
                          let jsonObject = data._jsonObject() as? [String: Any],
                          let version = jsonObject["version"]
                    else {
                        self.generateLiveButton(isEnabled: false); return
                    }
                    
                    let text = "您使用的Ollama版本為：\(version)，模型為：\(WWSimpleAI.Ollama.model)"
                    self.generateLiveButton(isEnabled: true)
                    WWToast.shared.makeText(text)
                }
            }
        }
    }
    
    /// 設定generateLiveButton是否可以使用
    /// - Parameter isEnabled: Bool
    func generateLiveButton(isEnabled: Bool) {
        generateLiveButton.isEnabled = isEnabled
    }
}
