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
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
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
                "latest_message" : [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                print("add origin conversation")
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode){ [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(conversationID: conversationId,
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
                    
                    self?.finishCreatingConversation(conversationID: conversationId,
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
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        
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
            "isRead": false
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
    
    // 해당하는 이메일로 이전에 메세지 데이터들을 요청하고 리턴 받는다.
    public func getAllConversation(for email: String, completion: @escaping (Result<String, Error>) -> Void){
        
    }
    
    public func getAllMessageForConversation(with id: String, completion : @escaping (Result<String, Error>) -> Void){
        
    }
    
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void){
        
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


