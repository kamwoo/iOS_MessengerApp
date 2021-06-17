//
//  StorageManager.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/15.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    // firebase의 저장소를 참조
    private let storage = Storage.storage().reference()
    
    public typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    
    // 받은 프로필 이미지 저장 ,firebase 저장소에 업로드하고 컴플리션 반환
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion) {
        // firebase storage에 image디렉토리에 저장
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            // 실패시 컴플리션에 error 담는다.
            guard error == nil else {
                print("StorageManager - uploadProfilePicture() fail to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            // 저장소에 이미지 주소를 반환
            self.storage.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    print("StorageManager - uploadProfilePicture() fail to get download url")
                    completion(.failure(StorageErrors.failToDownload))
                    return
                }
                // 성공시 이미지 다운로드 url을 completion으로 전달
                let urlString = url.absoluteString
                print("StorageManager - uploadProfilePicture() download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    // storage error문 지정
    public enum StorageErrors : Error {
        case failedToUpload
        case failToDownload
    }
    
}
