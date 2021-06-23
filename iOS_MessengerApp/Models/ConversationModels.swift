//
//  ConversationModels.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/23.
//

import Foundation

// 대화 세부 정보
struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

// 가장 최근 메세지
struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
