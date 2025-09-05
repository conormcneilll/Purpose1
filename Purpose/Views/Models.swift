import Foundation


struct Post: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let username: String
    let caption: String?
    let image_url: String?
    let video_url: String?
    let created_at: String
    let profile_image_url: String?
    let prompt_text: String?
}

struct FeedResponse: Codable {
    let success: Bool
    let posts: [Post]
}

struct UserProfileResponse: Codable {
    let success: Bool
    let profile: UserProfile
    let posts: [Post]
}

struct UserProfile: Codable {
    let id: Int
    let username: String
    let email: String?
    let bio: String
    let profile_image_url: String?
    private let is_following: Int?
    

    var isFollowingBool: Bool {
        return is_following == 1
    }
}


struct SearchResponse: Codable {
    let success: Bool
    let users: [SearchUser]
}

struct SearchUser: Codable, Identifiable {
    let id: Int
    let username: String
    let profile_image_url: String?
    private let is_following: Int?
    
    var isFollowingBool: Bool {
        return is_following == 1
    }
}

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


struct Comment: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let username: String
    let comment_text: String
    let created_at: String
}

struct SinglePostResponse: Codable {
    let success: Bool
    let post: Post
    let comments: [Comment]
}

struct CommentResponse: Codable {
    let success: Bool
    let message: String
    let comment_id: Int?
}
