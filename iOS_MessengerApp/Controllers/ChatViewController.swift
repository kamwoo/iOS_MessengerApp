//
//  ChatViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/14.
//

import UIKit
import MessageKit

// 대화창 뷰

// 메세지 타입 설정
struct Message : MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
}

// 보내는 사람의 타입, 정보 설정
struct Sender : SenderType {
    var photoURL : String
    var senderId: String
    var displayName: String
}


class ChatViewController: MessagesViewController {
    // 메세지 어레이
    private var messages = [Message]()
    // 보내는 사람 설정
    private let selfSender = Sender(photoURL: "", senderId: "1", displayName: "kamwoo")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: selfSender,
                               messageId: "1",
                               sentDate: Date(),
                               kind: .text("hello world message. ")))
        messages.append(Message(sender: selfSender,
                               messageId: "1",
                               sentDate: Date(),
                               kind: .text("hello world message.hello world message.hello world message.hello world message. ")))
        
        view.backgroundColor = .white
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    

}

// MARK: -MessageKit Delegates
extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    // 메세지 보낸 사람
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        // 메세지 당 단일 섹션으로 둔다
        return messages[indexPath.section]
    }
    
    // 메세지 수 반환
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
