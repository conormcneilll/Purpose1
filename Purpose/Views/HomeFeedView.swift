//
//  HomeFeedView.swift
//  Purpose
//
//  Created by Conor McNeill on 05/09/2025.
//

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
                            
                            Button(addedFriends.contains(user.id) ? "Added" : "Add") {
                                addFriend(friendId: user.id)
                            }
                            .disabled(addedFriends.contains(user.id))
                        }
                    }
                    .listStyle(.plain)
                }
                
                // Main Feed
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostView(post: post)
                        }
                    }
                    .padding(.bottom)
                    .refreshable {
                        fetchFeed()
                    }
                }
            }
            .navigationTitle("Purpose")
            .navigationBarTitleDisplayMode(.inline)
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
        guard !query.isEmpty,
              let url = URL(string: "http://127.0.0.1:3000/users/search?query=\(query)") else {
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
