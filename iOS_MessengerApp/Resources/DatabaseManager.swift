//
//  DatabaseManager.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/14.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    // firebase의 데이터 저장소를 참조
    private let database = Database.database().reference()
    
    // safe 이메일로 변경해주는 기능
    static func safeEmail(emailAddress : String ) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

// MARK: -Account Management
extension DatabaseManager {
    
    /// 유저가 이미 있는지 확인
    public func userExists(with email: String, completion: @escaping( (Bool) -> Void) ){
        // 이메일의 기호 변경 안정성 문제
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value){ snapshot in
            // 존재하지 않음 false
            guard (snapshot.value as? NSDictionary) != nil else {
                print("DatabaseManager - userExists() user not exist")
                completion(false)
                return
            }
            print("DatabaseManager - userExists() user exist \(String(describing: snapshot.value as? NSDictionary)) ")
            completion(true)
        }
    }
    
    /// 새로운 유저의 관련 데이터 저장
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        // database 이메일 디렉토리에 이름 저장
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "seconde_name" : user.secondName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print(" DatabaseManager - insertUser() fail to write to database")
                completion(false)
                return
            }
            
            // DB에 유저마다 테이블로 관리하기위해 작성. 한번의 요청으로 유저의 대화 등의 정보를 얻어오기 깔끔하다
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                // 이미 유저의 테이블이 존재한다면 추가
                if var userCollection = snapshot.value as? [[String: String]] {
                    
                    let newElement = [
                        "name": user.firstName,
                        "email": user.safeEmail
                    ]
                    userCollection.append(newElement)
                    self.database.child("users").setValue(userCollection){ error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }else{ // 유저의 테이블이 없다면 생성
                    let newCollection: [[String :String]] = [
                        [
                            "name": user.firstName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection){ error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            })
        })
    }
    
    // 저장소에 name 필드의 value값을 다 가지고 온다.
    public func getAllUsers(completion : @escaping (Result<[[String:String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedError))
                return
            }
            
            completion(.success(value))
        })
    }
    
    public enum DatabaseError : Error {
        case failedError
    }
    

}

extension DatabaseManager {
    // 접속한 유저의 이메일 노드에 데이터 반환
    public func getDataFor(path: String, completion : @escaping (Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedError))
                return
            }
            completion(.success(value))
        })
    }
}

extension DatabaseManager {
    /* 데이터 베이스 대화 스키마
     
        "asfdasdf" {
            "message" : [
                {
                    "id" : String,
                    "type" : text, photo, video,
                    "content" : String,
                    "date" : Date()
                    "sender_email" : String
                    "isRead": true/false
                }
            ]
        }
     
        conversation => [
            [
                "conversation_id" : "asfdasdf"
                "other_user_email" :
                "latest_message" : => {
                    "date": Date()
                    "latest_message" : "message"
                    "is_read": true/false
                }
            ]
        ]
     */
    
    // 선택된 유저와 새로운 채팅을 만들고 첫번째 메세지를 보낸다
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String
          else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind{
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData : [String: Any] = [
                "id" : conversationId,
                "other_user_email" : otherUserEmail,
                "name" : name,
                "latest_message" : [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData : [String: Any] = [
                "id" : conversationId,
                "other_user_email" : safeEmail,
                "name" : currentName,
                "latest_message" : [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]]{
                    print("otherUserEmail add conversation")
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }else{
                    print("otherUserEmail create conversation")
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
                
            })
            
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                print("add origin conversation")
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode){ [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation( name: name,
                                                    conversationID: conversationId,
                                                    firstMessage: firstMessage,
                                                    completion: completion)
                }
            }else{
                // 대화 리스트가 존재하지 않으면 생성
                print("create new conversation")
                userNode["conversations"] = [ newConversationData ]
                
                ref.setValue(userNode){ [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation( name: name,
                                                    conversationID: conversationId,
                                                    firstMessage: firstMessage,
                                                    completion: completion)
                }
            }
            
        })
    }
    
    /* 데이터 베이스에 대화 스키마를 따로 하나더 만드는 이유는
        실시간으로 메세지를 관찰하고
        대화할 때 다른 사용자를 통해 쿼리하지 않기 위해 생성
     */
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        
        var message = ""
        
        switch firstMessage.kind{
        
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let MyEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: MyEmail)
        
        let CollectionMessage : [String: Any] = [
            "id" : firstMessage.messageId,
            "type" : firstMessage.kind.messageKindString,
            "content" : message,
            "date" : dateString,
            "sender_email" : currentUserEmail,
            "is_read": false,
            "name" : name
        ]
        
        let value : [String: Any] = [
            "messages" : [
                CollectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    // 해당하는 이메일로 이전에 메세지들의 정보를 요청하고 리턴 받는다.
    public func getAllConversation(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        // 현재 유저의 대화정보들을 리턴
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedError))
                return
            }
            
            // 리턴 받은 대화들을 맵핑하여 Conversation 오브젝트의 리스트 생성후 반환
            let conversations: [Conversation] = value.compactMap({ dictionaly in
                guard let conversationId = dictionaly["id"] as? String,
                      let name = dictionaly["name"] as? String,
                      let otherUserEmail = dictionaly["other_user_email"] as? String,
                      let latestMessage = dictionaly["latest_message"] as? [String : Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            
            completion(.success(conversations))
        })
    }
    
    
    // 데이터베이스 대화방id에 해당하는 테이블에서 대화방에 대화 데이터들 리턴
    public func getAllMessageForConversation(with id: String, completion : @escaping (Result<[Message], Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedError))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionaly in
                guard let name = dictionaly["name"] as? String,
                      let isRead = dictionaly["is_read"] as? Bool,
                      let messageId = dictionaly["id"] as? String,
                      let content = dictionaly["content"] as? String,
                      let senderEmail = dictionaly["sender_email"] as? String,
                      let dateString = dictionaly["date"] as? String,
                      let type = dictionaly["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)
                else {
                    print("messages error")
                    return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: .text(content))
                
            })
            
            completion(.success(messages))
        })
    }
    
    public func sendMessage(to conversation: String, name: String, otherUserEmail: String ,newMessage: Message, completion: @escaping (Bool) -> Void){
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var currentMessgaes = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let MyEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: MyEmail)
            
            let newMessageEntry : [String: Any] = [
                "id" : newMessage.messageId,
                "type" : newMessage.kind.messageKindString,
                "content" : message,
                "date" : dateString,
                "sender_email" : currentUserEmail,
                "is_read": false,
                "name" : name
            ]
            
            currentMessgaes.append(newMessageEntry)
            self?.database.child("\(conversation)/messages").setValue(currentMessgaes){ [weak self] error, _  in
                guard let self = self else {return}
                
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String:Any]] else {
                        completion(false)
                        return
                    }
                    
                    let updateValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    var targetConversation : [String: Any]?
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation{
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updateValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    
                    currentUserConversations[position] = finalConversation
                    self.database.child("\(currentEmail)/conversations").setValue(currentUserConversations){ error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // update latest message for recipient user
                        self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String:Any]] else {
                                completion(false)
                                return
                            }
                            
                            let updateValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            
                            var targetConversation : [String: Any]?
                            var position = 0
                            
                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation{
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            
                            targetConversation?["latest_message"] = updateValue
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            
                            otherUserConversations[position] = finalConversation
                            self.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations){ error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        })
                        
                    }
                })
            }
        })
    }
}

// 유저 정보 model
struct ChatAppUser {
    let firstName : String
    let secondName : String
    let emailAddress : String
    var safeEmail : String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName : String {
        return "\(safeEmail)_profile_picture.png"
    }
}


