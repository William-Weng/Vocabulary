//
//  TableViewCell.swift
//  ChatGPTAPI
//
//  Created by William.Weng on 2023/4/24.
//

import UIKit

// MARK: - 自己的對話框
final class MasterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var chatImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabelLeading: NSLayoutConstraint!
    
    /// 設定Cell長相
    /// - Parameter indexPath: IndexPath
    func config(with indexPath: IndexPath) {
        
        let message = ChatViewController.chatMessageList[indexPath.row]
        
        nameLabel.text = (!message.isMe) ? "ChatGPT" : "User"
        iconImageView.image = UIImage(named: "User")
        chatMessageSetting(message)
    }
    
    /// 設定訊息內容
    /// - Parameter message: Constant.ChatMessage
    func chatMessageSetting(_ message: Constant.ChatMessage) {
        
        messageLabel.text = message.text
        messageLabelLeading.constant = 16
        chatImageView.contentMode = .scaleToFill
        chatImageView.image = UIImage(named: "ChatRight")
    }
}

// MARK: - ChatGPT的對話框
final class SlaveTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var chatImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabelTrailing: NSLayoutConstraint!
    
    /// 設定Cell長相
    /// - Parameter indexPath: IndexPath
    func config(with indexPath: IndexPath) {
        
        let message = ChatViewController.chatMessageList[indexPath.row]
        
        nameLabel.text = (!message.isMe) ? "ChatGPT" : "User"
        iconImageView.image = UIImage(named: "AI")
        chatMessageSetting(message)
    }
    
    /// 設定訊息內容
    /// - Parameter message: Constant.ChatMessage
    func chatMessageSetting(_ message: Constant.ChatMessage) {
        
        messageLabel.text = message.text
        messageLabelTrailing.constant = 16
        chatImageView.contentMode = .scaleToFill
        chatImageView.image = UIImage(named: "ChatLeft")
    }
}
