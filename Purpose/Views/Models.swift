//
//  Models.swift
//  Purpose
//
//  Created by Conor McNeill on 05/09/2025.
//


import Foundation

// MARK: - Post Model
struct Post: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let username: String?
    let caption: String?
    let image_url: String?
    let video_url: String?
    let created_at: String
    let profile_image_url: String?
}

// MARK: - Feed Response
struct FeedResponse: Codable {
    let success: Bool
    let posts: [Post]
}

// MARK: - Comment Models
struct Comment: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let username: String
    let comment_text: String
    let created_at: String
}


// MARK: - User Profile Response
struct UserProfileResponse: Codable {
    let success: Bool
    let profile: UserProfile
    let posts: [Post]
}

struct UserProfile: Codable {
    let id: Int
    let username: String
    let email: String?
    let bio: String?
    let profile_image_url: String?
}



// MARK: - Search Models
struct SearchResponse: Codable {
    let success: Bool
    let users: [SearchUser]
}

struct SearchUser: Codable, Identifiable {
    let id: Int
    let username: String
    let profile_image_url: String?
}

// MARK: - Camera Models
struct Prompt: Codable, Identifiable {
    let id: Int
    let prompt_text: String
}

struct PromptResponse: Codable {
    let success: Bool
    let prompt: Prompt
}

struct UploadResponse: Codable {
    let success: Bool
    let message: String
    let post_id: Int?
}
