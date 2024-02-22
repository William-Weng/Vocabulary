//
//  ViewController.swift
//  ChatGPTAPI
//
//  Created by William.Weng on 2022/12/15.
//

import UIKit
import WWPrint
import WWHUD
import WWSimpleChatGPT
import WWKeyboardShadowView

// MARK: - 對話功能頁
final class ChatViewController: UIViewController {
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var myTextField: UITextField!
    @IBOutlet weak var connentView: UIView!
    @IBOutlet weak var keyboardShadowView: WWKeyboardShadowView!
    @IBOutlet weak var keyboardConstraintHeight: NSLayoutConstraint!
    
    static var chatMessageList: [Constant.ChatMessage] = []
    
    private var bearerToken = "<BearerToken>"
        
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
            
    @IBAction func sendMessage(_ sender: UIButton) { sendMessage(with: myTextField.text) }
    
    @objc func dimissKeyboard() { view.endEditing(true) }
    
    deinit { wwPrint("deinit => \(Self.self)") }
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
extension ChatViewController: WWKeyboardShadowViewDelegate {
    
    func keyboardWillChange(view: WWKeyboardShadowView, information: WWKeyboardShadowView.KeyboardInfomation) -> Bool { return true }
    func keyboardDidChange(view: WWKeyboardShadowView) {}
}

// MARK: - 小工具
private extension ChatViewController {
    
    /// 初始化設定
    func initSetting() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Self.dimissKeyboard))
        
        myTableView.delegate = self
        myTableView.dataSource = self
        
        myTextField.delegate = self
        myTableView.addGestureRecognizer(tapGesture)
                
        keyboardConstraintHeight.constant = 128
        keyboardShadowView.configure(target: self, keyboardConstraintHeight: keyboardConstraintHeight)
        keyboardShadowView.register()
        
        WWSimpleChatGPT.configure(bearerToken: bearerToken)
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
        
        defer { dimissKeyboard(); myTextField.text = "" }
        
        guard let message = message,
              !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            Utility.shared.diplayHUD(with: .fail); return
        }
        
        sendMessage(message)
    }
}

// MARK: - CharGPT
private extension ChatViewController {
    
    /// 傳送文字訊息
    /// - Parameter message: String?
    func sendMessage(_ message: String) {
                
        let chatMessage = Constant.ChatMessage(message, true)
        let content = phaseMessage(chatMessage)
        
        if let content = content {
            
            Utility.shared.diplayHUD(with: .nice)
            
            Task {
                
                let result = await WWSimpleChatGPT.shared.chat(model: .v3_5, temperature: 0.7, content: content)
                
                switch result {
                case .failure(let error): wwPrint(error); Utility.shared.diplayHUD(with: .fail)
                case .success(let message):
                    
                    Utility.shared.dismissHUD()
                    
                    if let message = message {
                        let gptMessage = Constant.ChatMessage(message, false)
                        _ = phaseMessage(gptMessage)
                    }
                }
            }
        }
    }
}
