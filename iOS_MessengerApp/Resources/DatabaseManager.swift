//
//  DatabaseManager.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/14.
//

import Foundation
import FirebaseDatabase
import MessageKit

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

// MARK: - Account Management
extension DatabaseManager {
    
    /// 유저가 이미 있는지 확인
    public func userExists(with email: String, completion: @escaping( (Bool) -> Void) ){
        // 이메일의 기호 변경 안정성 문제
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value){ snapshot in
            // 존재하지 않음 false
            guard (snapshot.value as? [String: Any]) != nil else {
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

// MARK: - getDataFor mothod
extension DatabaseManager {
    // 접속한 유저의 이메일 노드에 해당하는 데이터 반환
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


// MARK: - Conversation Database query methods
extension DatabaseManager {
    
    // 대화방 리스트 로딩에 사용
    // 해당하는 이메일로 이전에 메세지들의 정보를 요청하고 리턴 받는다.
    public func getAllConversation(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        // 현재 유저의 대화정보들을 리턴
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedError))
                return
            }
            
            // 리턴 받은 대화들을 맵핑하여 Conversation 오브젝트의 리스트로 생성후 반환
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
    
    
    // 셀에서 대화방이 클릭 된 후
    // 데이터베이스 대화방id에 해당하는 테이블에서 대화방에 대화 데이터들 리턴
    public func getAllMessageForConversation(with id: String, completion : @escaping (Result<[Message], Error>) -> Void){
        // 대화방 아이디에 해당하는 대화 데이터들을 리턴
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedError))
                return
            }
            // 대화 한개씩 분리 후 Message객체의 리스트로 반환
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
                
                // 메세지 종류를 판별
                let kind: MessageKind?
                
                if type == "photo"{
                    guard let url = URL(string: content), let placeholder = UIImage(systemName: "photo") else {
                        return nil
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height:300))
                    kind = .photo(media)
                    
                }else if type == "video"{
                    guard let url = URL(string: content), let placeholder = UIImage(systemName: "camera") else {
                        return nil
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height:300))
                    kind = .video(media)
            
                }else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else { return nil }
                
                // 해당하는 메세지 타입으로 메세지 객체 리턴
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            })
            
            completion(.success(messages))
        })
    }
    
    
// MARK: - Conversation methods
    
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
        // 현재 유저의 이메일과 이름 언래핑
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String
          else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        // 현재 유저 이메일로 데이터 리턴
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            // 메세지의 전송시각
            let messageDate = firstMessage.sentDate
            // 전송시각 형태변형
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            // 메세지 종류 판별
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
            
            // 대화방 아이디 생성
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            // 현재 유저에 저장될 대화방 정보
            let newConversationData : [String: Any] = [
                "id" : conversationId,
                "other_user_email" : otherUserEmail,
                "name" : name, // 상대방 이름
                "latest_message" : [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // 상대 유저에 저장될 대화방 정보
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
            
            // 상대방 대화방 데이터 확인 후 삽입
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapshot in
                // 대화방 정보가 있다면 그 곳에 추가
                if var conversations = snapshot.value as? [[String: Any]]{
                    print("otherUserEmail add conversation")
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }else{
                    // 없다면 새로운 대화방 정보 생성
                    print("otherUserEmail create conversation")
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
                
            })
            
            // 현재 유저의 대화방 정보가 있다면
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // 그 정보에 새로운 대화내용 삽입 후 추가
                print("add origin conversation")
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode){ [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    // 생성된 대화방 아이디로 대화들 스키마 추가 ,completion 넘김
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
        
        // 메세지 보낸 시각
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        // 현재 유저의 이메일
        guard let MyEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: MyEmail)
        
        // 대화방 필드 및 값 설정
        let CollectionMessage : [String: Any] = [
            "id" : firstMessage.messageId,
            "type" : firstMessage.kind.messageKindString,
            "content" : message,
            "date" : dateString,
            "sender_email" : currentUserEmail,
            "is_read": false,
            "name" : name
        ]
        
        // 대화 집합
        let value : [String: Any] = [
            "messages" : [
                CollectionMessage
            ]
        ]
        
        // 생성된 대화방 아이디로 대화 집합체 데이터 추가
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    
    // 이전에 대화방이 존재할 때 메세지 보내기
    public func sendMessage(to conversation: String, name: String, otherUserEmail: String ,newMessage: Message, completion: @escaping (Bool) -> Void){
        // 현재 유저의 이메일을 받고, 안전한 이메일 형식으로 변환
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        // 해당하는 대화방 아이디로 대화 정보들 리턴
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            // 이전의 대화들 currentMessgaes로 저장
            guard var currentMessgaes = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            // 새로 보내는 메세지 시각
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
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
            
            // 현재 유저 이메일 받고, 변환
            guard let MyEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: MyEmail)
            
            // 새로운 메세지 세부정보 작성
            let newMessageEntry : [String: Any] = [
                "id" : newMessage.messageId,
                "type" : newMessage.kind.messageKindString,
                "content" : message,
                "date" : dateString,
                "sender_email" : currentUserEmail,
                "is_read": false,
                "name" : name
            ]
            
            // 이전에 저장된 대화방 데이터에 새로운 메세지 데이터 추가
            currentMessgaes.append(newMessageEntry)
            
            // 해당하는 대화방 아이디 새로운 정보 테이블에 저장
            self?.database.child("\(conversation)/messages").setValue(currentMessgaes){ [weak self] error, _  in
                guard let self = self else {return}
                
                guard error == nil else {
                    completion(false)
                    return
                }
                
                // 현재 유저의 대화 테이블 최신화
                self.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntryConversations = [[String:Any]]()
                    
                    // 유저 데이터에 latest_message필드에 새로 저장될 객체
                    let updateValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    if var currentUserConversations = snapshot.value as? [[String:Any]]  {
                        
                        var targetConversation : [String: Any]?
                        var position = 0
                        
                        // 유저 데이터에 대화방 중에서 현재 대화방 아이디와 일치하는 바을 타겟 대화방으로 설정
                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation{
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            // 타겟 대화방에 최근 대화를 새로운 최근 대화 객체로 변환
                            targetConversation["latest_message"] = updateValue
                            // 현재 유저 대화방 데이터 중에 타겟 대화방에 해당하는 대화방을 새로운 대화방으로 전환
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                        }else {
                            let newConversationData : [String: Any] = [
                                "id" : conversation,
                                "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name" : name, // 상대방 이름
                                "latest_message" : updateValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                        
                        
                        
                    }else {
                        let newConversationData : [String: Any] = [
                            "id" : conversation,
                            "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name" : name, // 상대방 이름
                            "latest_message" : updateValue
                        ]
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }
                    
                    
                    
                    // 현재 유저 Conversation필드에 수정된 값 대입
                    self.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations){ error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // 상대방 대화방 데이터에도 같은 로직으로 새로운 최근 대화 최신화
                        self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            
                            let updateValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            
                            var databaseEntryConversations = [[String:Any]]()
                            
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else{
                                return
                            }
                            
                            if var otherUserConversations = snapshot.value as? [[String:Any]]  {
                                var targetConversation : [String: Any]?
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation{
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updateValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversations = otherUserConversations
                                    
                                }else {
                                    let newConversationData : [String: Any] = [
                                        "id" : conversation,
                                        "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                        "name" : currentName, // 상대방 이름
                                        "latest_message" : updateValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                                
                                
                            }else{
                                let newConversationData : [String: Any] = [
                                    "id" : conversation,
                                    "other_user_email" : DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name" : currentName, // 상대방 이름
                                    "latest_message" : updateValue
                                ]
                                databaseEntryConversations = [
                                    newConversationData
                                ]

                            }
                            
                            
                            
                            
                            self.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations){ error, _ in
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
    
    public func deleteConversation(conversationId : String, completion: @escaping (Bool) -> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        // 현재 유저의 대화방 리스트 데이터를 가지고 온다.
        // 그 중에서 타겟 대화방을 삭제
        // 수정된 대화방 리스트 데이터를 업로드
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if var conversations = snapshot.value as? [[String : Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId {
                        break
                    }
                    positionToRemove += 1
                }
                
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: {error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    completion(true)
                })
            }
        })
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void){
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedError))
                return
            }
            
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }){
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedError))
                    return
                }
                
                completion(.success(id))
                return
            }
            
            completion(.failure(DatabaseError.failedError))
            return
        })
    }
}



// MARK: - user Model
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


