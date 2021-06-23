//
//  ChatModels.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/23.
//

import Foundation
import CoreLocation
import MessageKit

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

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location : LocationItem {
    var location: CLLocation
    var size: CGSize
    
}
