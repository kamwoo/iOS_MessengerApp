//
//  ChatViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/14.
//

import UIKit
import MessageKit
import InputBarAccessoryView

// 대화창 뷰

// 메세지 타입 설정
struct Message : MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

// 메세지 종류 스트링 반환
extension MessageKind {
    var messageKindString : String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

// 보내는 사람의 타입, 정보 설정
struct Sender : SenderType {
    public var photoURL : String
    public var senderId: String
    public var displayName: String
}


class ChatViewController: MessagesViewController {
    
    // id 생성에 사용할 날짜포멧
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false

    public let otherUserEmail: String
    
    private let conversationId: String?
    
    // 메세지 어레이
    private var messages = [Message]()
    
    // 보내는 사람 설정, 현재 유저
    private var selfSender : Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return nil}
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }
    
    
    // MARK: -Lifecycle
    init(with email: String, id : String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    // 선택된 대화방의 대화 데이터를 반환
    private func listenForMessages(id : String, shouldScrollToBottom : Bool) {
        DatabaseManager.shared.getAllMessageForConversation(with: id, completion: { [weak self] result in
            print("listenForMessages - called()")
            switch result {
            case .success(let messages) :
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                    
                }
            case .failure(let error):
                print("failed to get messages \(error)")
            }
            
        })
    }

}

// 대화 입력 딜리게이트
extension ChatViewController : InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // 공백 허용
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId()
        else {
            print("error")
            return
        }
        
        // 처음 메세지를 담고
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        // send Message
        if isNewConversation {
            // 새로운 대화 생성
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                }else{
                    print("failed to send")
                }
            })
        }else{
            guard let conversationId = conversationId, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: otherUserEmail , newMessage: message, completion: { success in
                if success {
                    print("message sent")
                }else{
                    print("failed to send")
                }
            })
        }
        
    }
    
    // 날짜, 상대유저 이메일, 보내는 사람의 이메일로 아이디 생성
    private func createMessageId() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier =  "\(otherUserEmail)_\(safeEmail)_\(dateString)"
        print("create messageId: \(newIdentifier)")
        return newIdentifier
    }
}

// MARK: -MessageKit Delegates
extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    // 메세지 보낸 사람
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("보내는 사람의 정보가 없습니다.")
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
