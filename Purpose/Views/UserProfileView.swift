import SwiftUI
import AVKit

struct UserProfileView: View {
    
    let profileUserId: Int
    @AppStorage("user_id") private var currentUserId: Int = 0

    @State private var username: String = ""
    @State private var bio: String?
    @State private var profileImageURL: URL?
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var isFollowing: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Avatar
                if let url = profileImageURL {
                    AsyncImage(url: url) { image in
                        image.resizable()
                             .scaledToFill()
                             .frame(width: 100, height: 100)
                             .clipShape(Circle())
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3)).frame(width: 100, height: 100)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                
                Text(username).font(.title).bold()
                
                if let bio = bio {
                    Text(bio).multilineTextAlignment(.center).padding(.horizontal)
                }
                
                
                if profileUserId != currentUserId {
                    Button(action: {
                        if isFollowing {
                            unfollowUser()
                        } else {
                            followUser()
                        }
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFollowing ? Color.green : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                if posts.isEmpty {
                    Text("This user hasn't posted anything yet.").foregroundColor(.gray).padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                PostView(post: post, onDelete: { deletedPostId in
                                    
                                    posts.removeAll { $0.id == deletedPostId }
                                })
                            }
                        }.padding(.bottom)
                        .refreshable { fetchProfile() }
                    }
                }
                
                Spacer()
            }
            .onAppear { fetchProfile() }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
    func fetchProfile() {
        guard profileUserId > 0,
              let url = URL(string: "http://127.0.0.1:3000/user/\(profileUserId)/profile?current_user_id=\(currentUserId)") else {
            return
        }
        
        isLoading = true
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async { isLoading = false }
            guard let data = data,
                  let response = try? decoder.decode(UserProfileResponse.self, from: data),
                  response.success else { return }
            
            DispatchQueue.main.async {
                self.username = response.profile.username
                self.bio = response.profile.bio
                self.posts = response.posts
                self.isFollowing = response.profile.isFollowingBool

                if let imgUrl = response.profile.profile_image_url {
                    self.profileImageURL = URL(string: imgUrl)
                } else {
                    self.profileImageURL = nil
                }
            }
        }.resume()
    }
    
    
    func followUser() {
        guard let url = URL(string: "http://127.0.0.1:3000/friends/add") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["user_id": currentUserId, "friend_id": profileUserId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               responseJSON["success"] as? Bool == true {
                DispatchQueue.main.async {
                    self.isFollowing = true
                }
            }
        }.resume()
    }
    
    
    func unfollowUser() {
        guard let url = URL(string: "http://127.0.0.1:3000/friends/remove") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["user_id": currentUserId, "friend_id": profileUserId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               responseJSON["success"] as? Bool == true {
                DispatchQueue.main.async {
                    self.isFollowing = false
                }
            }
        }.resume()
    }
}
