//
//  User.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let handle: String
    let username: String
    let password: String
    let profileImageUrl: String?
    let backgroundImageUrl: String?
    let phone: String?
    let postCount: Int?
    let friendCount: Int?
    let streakCount: Int?
}

struct UserProfile: Codable {
    let id: Int
    let username: String
    let name: String
    let profileImageUrl: String?
    let backgroundImageUrl: String?
    let postCount: Int
    let friendCount: Int
    let streakCount: Int
    let mutualFriendsText: String?
}
