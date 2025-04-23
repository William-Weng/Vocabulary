//
//  ViewController.swift
//  ChatGPTAPI
//
//  Created by William.Weng on 2022/12/15.
//

import UIKit
import WWPrint
import WWHUD
import WWUserDefaults
import WWSimpleAI_Ollama
import WWSimpleAI_ChatGPT
import WWKeyboardShadowView
import WWExpandableTextView

// MARK: - 對話功能頁
final class ChatViewController: UIViewController {
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var connentView: UIView!
    @IBOutlet weak var chatImageView: UIImageView!
    @IBOutlet weak var keyboardConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var keyboardShadowView: WWKeyboardShadowView!
    @IBOutlet weak var expandableTextView: WWExpandableTextView!
    
    static var chatMessageList: [Constant.ChatMessage] = []
    
    weak var sentenceViewDelegate: SentenceViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
        
    @IBAction func sendMessage(_ sender: UIButton) { sendMessage(with: expandableTextView.text) }
    @IBAction func tokenSetting(_ sender: UIBarButtonItem) { bearerTokenTextHint(title: "請輸入Token") }
    
    @objc func dimissKeyboard() { view.endEditing(true) }
    
    deinit {
        sentenceViewDelegate = nil
        keyboardShadowView.unregister()
        sentenceViewDelegate?.tabBarHidden(false)
        wwPrint("deinit => \(Self.self)")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.chatMessageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = chatCellMaker(tableView, cellForRowAt: indexPath) else { fatalError() }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dimissKeyboard()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UITextFieldDelegate
extension ChatViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITextFieldDelegate
extension ChatViewController: WWKeyboardShadowView.Delegate {
    
    func keyboardViewChange(_ view: WWKeyboardShadowView, status: WWKeyboardShadowView.DisplayStatus, information: WWKeyboardShadowView.KeyboardInformation, height: CGFloat) -> Bool {
        return true
    }
    
    func keyboardView(_ view: WWKeyboardShadowView, error: WWKeyboardShadowView.CustomError) {
        wwPrint(error)
    }
}

// MARK: - 小工具
private extension ChatViewController {
    
    /// 初始化設定
    func initSetting() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Self.dimissKeyboard))
        
        myTableView.delegate = self
        myTableView.dataSource = self
        myTableView.addGestureRecognizer(tapGesture)
        
        chatImageView.image = Utility.shared.folderImage(name: "Chatting.jpg")
        
        keyboardConstraintHeight.constant = 0
        keyboardShadowView.configure(target: self, keyboardConstraintHeight: keyboardConstraintHeight)
        keyboardShadowView.register()
        
        sentenceViewDelegate?.tabBarHidden(true)
        chatSetting(bearerToken: Constant.bearerToken)
        
        initExpandableTextViewSetting()
    }
    
    /// 初始化設定可變高度的TextView (最高3行)
    func initExpandableTextViewSetting() {
        expandableTextView.configure(lines: 3, gap: 21)
        expandableTextView.setting(font: .systemFont(ofSize: 20), backgroundColor: .white, borderWidth: 1, borderColor: .gray)
    }
    
    /// 選擇Cell (自己 / ChatGPT)
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    /// - Returns: UITableViewCell?
    func chatCellMaker(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        
        let message = ChatViewController.chatMessageList[indexPath.row]
        
        if (!message.isMe) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SlaveTableViewCell") as? SlaveTableViewCell
            cell?.config(with: indexPath)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MasterTableViewCell") as? MasterTableViewCell
        cell?.config(with: indexPath)
        return cell
    }
    
    /// 解析訊息
    /// - Parameter chatMessage: Constant.ChatMessage?
    /// - Returns: String?
    func phaseMessage(_ chatMessage: Constant.ChatMessage?) -> String? {
        
        guard let chatMessage = chatMessage else { return nil }
        
        Self.chatMessageList.append(chatMessage)
        let indexPath = IndexPath(row: Self.chatMessageList.count - 1, section: 0)
        
        myTableView.insertRows(at: [indexPath], with: .none)
        myTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        
        return chatMessage.text
    }
}

// MARK: - CharGPT
private extension ChatViewController {
        
    /// 傳送文字訊息
    /// - Parameter message: String?
    func sendMessage(with message: String?) {
        
        defer {
            dimissKeyboard()
            expandableTextView.text = ""
            expandableTextView.updateHeight()
        }
        
        guard let message = message,
              !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            Utility.shared.flashHUD(with: .fail); return
        }
        
        sendMessage(message)
    }
}

// MARK: - CharGPT
private extension ChatViewController {
    
    /// 傳送文字訊息
    /// - Parameter message: String?
    func sendMessage(_ message: String) {
        
        guard let chatMessage = Optional.some(Constant.ChatMessage(message, true)),
              let content = phaseMessage(chatMessage)
        else {
            Utility.shared.flashHUD(with: .fail); return
        }
        
        Utility.shared.diplayHUD(with: .loading)
        
        Task {
            
            let result = await WWSimpleAI.ChatGPT.shared.chat(model: .v3_5, temperature: 0.7, content: content)
            
            switch result {
            case .failure(let error): wwPrint(error); Utility.shared.flashHUD(with: .fail)
            case .success(let message):
                
                Utility.shared.dismissHUD()
                
                if let message = message {
                    let gptMessage = Constant.ChatMessage(message, false)
                    _ = phaseMessage(gptMessage)
                }
            }
        }
    }
    
    /// 設定ChatGPT的Token對話框
    /// - Parameters:
    ///   - title: String
    ///   - message: String?
    ///   - defaultText: String?
    func bearerTokenTextHint(title: String, message: String? = nil, defaultText: String? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let placeholder = title
        
        alertController.addTextField {
            $0.text = defaultText
            $0.placeholder = placeholder
        }
        
        let actionOK = inputTokenAction(textFields: alertController.textFields)
        let actionCancel = UIAlertAction(title: "取消", style: .cancel) {  _ in }
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// 設定ChatGPT的Token功能
    /// - Parameter textFields: [UITextField]?
    /// - Returns: UIAlertAction
    func inputTokenAction(textFields: [UITextField]?) -> UIAlertAction {
        
        let actionOK = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            
            guard let this = self,
                  let bearerToken = textFields?.first?.text?._removeWhiteSpacesAndNewlines(),
                  !bearerToken.isEmpty
            else {
                return
            }
            
            this.chatSetting(bearerToken: bearerToken)
        }
        
        return actionOK
    }
    
    /// 設定ChatGPT的Token
    /// - Parameter bearerToken: String?
    func chatSetting(bearerToken: String?) {
        
        guard let bearerToken = bearerToken else { bearerTokenTextHint(title: "請輸入Token"); return }
        
        WWSimpleAI.ChatGPT.configure(apiKey: bearerToken)
        connentView.backgroundColor = .lightGray.withAlphaComponent(0.3)
        Constant.bearerToken = bearerToken
    }
}
