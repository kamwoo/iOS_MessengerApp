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


