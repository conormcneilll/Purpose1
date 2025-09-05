import SwiftUI
import AVKit

struct UserProfileView: View {
    let userId: Int
    let username: String?
    
    @State private var bio: String = ""
    @State private var profileImageURL: URL?
    @State private var posts: [Post] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text(username ?? "Profile").font(.title2).bold()
                    Spacer()
                }.padding()
                
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
                
                Text(username ?? "User").bold()
                Text(bio.isEmpty ? "No bio" : bio).foregroundColor(.gray)
                
                Divider()
                
                // Posts
                if isLoading {
                    ProgressView().padding()
                } else if posts.isEmpty {
                    Text("This user hasn't posted anything yet.").foregroundColor(.gray).padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                PostView(post: post)
                            }
                        }.padding(.bottom)
                        .refreshable { fetchProfile() }
                    }
                }
                
                Spacer()
            }
            .onAppear { fetchProfile() }
        }
    }
    
    // MARK: - Networking
    func fetchProfile() {
        guard userId > 0,
              let url = URL(string: "http://127.0.0.1:3000/user/\(userId)/profile") else { return }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async { isLoading = false }
            guard let data = data,
                  let response = try? JSONDecoder().decode(UserProfileResponse.self, from: data),
                  response.success else { return }
            
            DispatchQueue.main.async {
                bio = response.profile.bio ?? ""
                if let imgUrl = response.profile.profile_image_url {
                    profileImageURL = URL(string: imgUrl)
                }
                posts = response.posts
            }
        }.resume()
    }
}
