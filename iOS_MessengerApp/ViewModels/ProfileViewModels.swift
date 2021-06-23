//
//  ProfileViewModels.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/23.
//

import Foundation

enum profileViewModelType {
    case info, logout
}

struct profileViewModel {
    let viewModelType: profileViewModelType
    let title : String
    let handler : (() -> Void)?
}
