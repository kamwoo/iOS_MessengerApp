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
            completion(true)
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


