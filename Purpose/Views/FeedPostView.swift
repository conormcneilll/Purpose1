import SwiftUI
import AVKit

struct FeedPostView: View {
    let post: FeedPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with User Info
            HStack {
                AsyncImage(url: URL(string: post.profile_image_url ?? "")) { img in
                    img.resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                NavigationLink(destination: UserProfileView(userId: post.user_id, username: post.username)) {
                    Text(post.username).bold()
                }
            }
            
            // Media
            if let imgUrl = post.image_url, let url = URL(string: imgUrl) {
                AsyncImage(url: url) { img in
                    img.resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                        .cornerRadius(10)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 250)
                        .cornerRadius(10)
                }
            } else if let vidUrl = post.video_url, let url = URL(string: vidUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 250)
                    .cornerRadius(10)
            }
            
            // Caption
            if let caption = post.caption {
                Text(caption)
                    .font(.body)
            }
        }
        .padding(.horizontal)
    }
}
