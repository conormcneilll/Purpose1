import SwiftUI
import AVKit

struct FeedPostView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack(spacing: 12) {
                
                if let profileImgUrl = post.profile_image_url, let url = URL(string: profileImgUrl) {
                    AsyncImage(url: url) { img in
                        img.resizable()
                           .scaledToFill()
                           .frame(width: 40, height: 40)
                           .clipShape(Circle())
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 40)
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
                
 
                VStack(alignment: .leading) {
                    Text(post.username)
                        .font(.headline)
                    Text(post.created_at) // ✅ Displays the raw string
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            NavigationLink(destination: SinglePostView(postId: post.id)) {
                if let imgUrl = post.image_url, let url = URL(string: imgUrl) {
                    AsyncImage(url: url) { img in
                        img.resizable()
                           .scaledToFill()
                           .frame(height: 250)
                           .clipped()
                           .cornerRadius(10)
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .cornerRadius(10)
                    }
                } else if let vidUrl = post.video_url, let url = URL(string: vidUrl) {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 250)
                        .cornerRadius(10)
                }
            }
            
            if let caption = post.caption {
                Text(caption)
                    .padding(.horizontal)
            }
            
            HStack {
                Spacer()
                NavigationLink(destination: CommentsView(postId: post.id)) {
                    Text("View Comments")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}
