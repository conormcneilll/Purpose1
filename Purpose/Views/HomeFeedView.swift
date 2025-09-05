import SwiftUI
import AVKit

// MARK: - HomeFeedView
struct HomeFeedView: View {
    @AppStorage("user_id") private var userId: Int = 0
    
    @State private var posts: [Post] = []
    @State private var searchQuery: String = ""
    @State private var searchResults: [SearchUser] = []
    @State private var addedFriends: Set<Int> = []
    
    var body: some View {
        NavigationStack {
            VStack {
                // 🔍 Search Bar
                TextField("Search friends...", text: $searchQuery)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onChange(of: searchQuery) { _, newValue in
                        searchUsers(query: newValue)
                    }
                
                if !searchResults.isEmpty {
                    List(searchResults) { user in
                        
                        NavigationLink(destination: UserProfileView(profileUserId: user.id)) {
                            HStack {
                                AsyncImage(url: URL(string: user.profile_image_url ?? "")) { img in
                                    img.resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(user.username)
                                    .font(.headline)
                                
                                Spacer()
                                
                                
                                if user.isFollowingBool { // Change from user.is_following == true to user.isFollowingBool
                                    Text("Following")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(8)
                                } else {
                                    Button("Follow") {
                                        addFriend(friendId: user.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                // Main Feed
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostView(post: post, onDelete: { deletedPostId in
                                // Remove the deleted post from the array
                                posts.removeAll { $0.id == deletedPostId }
                            })
                        }
                    }
                    .padding(.bottom)
                    .refreshable {
                        fetchFeed()
                    }
                }
                .overlay(
                    
                    Group {
                        if posts.isEmpty && searchResults.isEmpty {
                            VStack(spacing: 20) {
                                Image("PurposeLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200)
                                    .opacity(0.1) // Make the logo semi-transparent
                                Text("No posts? Try your first prompt or follow some friends using the searchbar above!")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                        Text("Purpose")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .onAppear {
                fetchFeed()
            }
        }
    }
    
    // MARK: - Networking
    func fetchFeed() {
        guard userId > 0,
              let url = URL(string: "http://127.0.0.1:3000/feed/home/\(userId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let response = try? JSONDecoder().decode(FeedResponse.self, from: data),
               response.success {
                DispatchQueue.main.async { posts = response.posts }
            }
        }.resume()
    }
    
    func searchUsers(query: String) {
        guard !query.isEmpty, userId > 0 else {
            searchResults = []
            return
        }

        var components = URLComponents(string: "http://127.0.0.1:3000/users/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "current_user_id", value: String(userId))
        ]

        guard let url = components.url else {
            print("Invalid URL")
            searchResults = []
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let response = try? JSONDecoder().decode(SearchResponse.self, from: data),
               response.success {
                DispatchQueue.main.async { searchResults = response.users }
            } else {
                DispatchQueue.main.async { searchResults = [] }
            }
        }.resume()
    }
    
    func addFriend(friendId: Int) {
        guard let url = URL(string: "http://127.0.0.1:3000/friends/add") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["user_id": userId, "friend_id": friendId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                addedFriends.insert(friendId)
            }
        }.resume()
    }
}
