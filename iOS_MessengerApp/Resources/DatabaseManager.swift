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
    
    private let database = Database.database().reference()
    
}

// MARK: -Account Management
extension DatabaseManager {
    
    /// 유저가 이미 있는지 확인
    public func userExists(with email: String, completion: @escaping( (Bool) -> Void) ){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value){ snapshot in
            // 존재하지 않음 false
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// 새로운 유저의 관련 데이터 저장
    public func insertUser(with user: ChatAppUser){
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "seconde_name" : user.secondName
        ])
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
//    let profileImageUrl : String
}


