import SwiftUI
import AVKit

struct PostView: View {
    @AppStorage("user_id") private var userId: Int = 0
    
    let post: Post
    var onDelete: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    
                    NavigationLink(destination: UserProfileView(profileUserId: post.user_id)) {
                        HStack(spacing: 12) {
                            
                            if let profileImgUrl = post.profile_image_url, let url = URL(string: profileImgUrl) {
                                AsyncImage(url: url) { img in
                                    img.resizable()
                                       .scaledToFill()
                                       .frame(width: 50, height: 50)
                                       .clipShape(Circle())
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 50, height: 50)
                                }
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(post.username)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(post.created_at.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                    
                    if post.user_id == userId {
                        Menu {
                            Button(role: .destructive, action: {
                                deletePost()
                            }) {
                                Label("Delete Post", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .imageScale(.large)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
     
                if let promptText = post.prompt_text, !promptText.isEmpty {
                    Text("Prompt: \(promptText)")
                        .font(.footnote)
                        .italic()
                        .foregroundColor(.purple)
                        .padding(.leading, 62)
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
            
            
            NavigationLink(destination: SinglePostView(postId: post.id)) {
                Group {
                    if let imgUrl = post.image_url, let url = URL(string: imgUrl) {
                        AsyncImage(url: url) { img in
                            img.resizable()
                               .scaledToFit()
                               .frame(maxWidth: .infinity)
                               .clipped()
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.2))
                                .frame(maxWidth: .infinity)
                                .frame(height: 280)
                        }
                    } else if let vidUrl = post.video_url, let url = URL(string: vidUrl) {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(Text("No media").foregroundColor(.gray))
                    }
                }
                .cornerRadius(10)
                .padding(.horizontal, 15)
            }
            
           
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 15)
            }
            
       
            HStack {
                Spacer()
                NavigationLink(destination: CommentsView(postId: post.id)) {
                    Label("View Comments", systemImage: "text.bubble")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
        }
    
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }


    func deletePost() {
        guard let url = URL(string: "http://127.0.0.1:3000/posts/\(post.id)/\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    onDelete(post.id) // Notify the parent view to refresh
                }
            } else {
                
                print("Failed to delete post: \(String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error")")
            }
        }.resume()
    }
}
