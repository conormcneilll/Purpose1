import SwiftUI
import AVKit

struct ProfileView: View {
    @AppStorage("user_id") private var userId: Int = 0
    
    @State private var username: String = ""
    @State private var bio: String?
    @State private var profileImageURL: URL?
    @State private var posts: [Post] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Profile").font(.title2).bold()
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }
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
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Text(username).font(.title).bold()
                
                if let bio = bio {
                    Text(bio).multilineTextAlignment(.center).padding(.horizontal)
                }
                
                Divider()
                
                if posts.isEmpty {
                    Text("You haven't posted anything yet.").foregroundColor(.gray).padding()
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
                // ⚠️ Corrected: Access properties from the nested 'profile' object
                self.username = response.profile.username
                self.bio = response.profile.bio
                self.posts = response.posts

                if let imgUrl = response.profile.profile_image_url {
                    self.profileImageURL = URL(string: imgUrl)
                } else {
                    self.profileImageURL = nil
                }
            }
        }.resume()
    }
}
