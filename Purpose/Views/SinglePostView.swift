import SwiftUI
import AVKit

struct SinglePostView: View {
    let postId: Int
    @State private var post: Post?
    @State private var isLoading = true
    
    
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""
    @State private var isPostingComment = false
    @State private var commentMessage: String = ""
    
    @AppStorage("user_id") private var userId: Int = 0
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Post...")
            } else if let post = post {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        
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
                                Text(post.created_at)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        
                        if let promptText = post.prompt_text {
                            Text("Prompt: \(promptText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        
                        if let imgUrl = post.image_url, let url = URL(string: imgUrl) {
                            AsyncImage(url: url) { img in
                                img.resizable()
                                   .scaledToFit()
                                   .frame(maxWidth: .infinity)
                                   .cornerRadius(10)
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.3))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .cornerRadius(10)
                            }
                        } else if let vidUrl = post.video_url, let url = URL(string: vidUrl) {
                            VideoPlayer(player: AVPlayer(url: url))
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .cornerRadius(10)
                        }
                        
                        
                        if let caption = post.caption {
                            Text(caption)
                                .font(.body)
                                .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Comments")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if comments.isEmpty {
                                Text("No comments yet.")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            } else {
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                
               
                VStack {
                    if !commentMessage.isEmpty {
                        Text(commentMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    HStack {
                        TextField("Add a comment...", text: $newCommentText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: addComment) {
                            if isPostingComment {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .disabled(newCommentText.isEmpty || isPostingComment)
                        .padding()
                        .background(newCommentText.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                }
            } else {
                Text("Post not found.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchPost()
        }
    }
    
    
    func fetchPost() {
        guard let url = URL(string: "http://127.0.0.1:3000/posts/\(postId)") else { return }
        
        isLoading = true
        let decoder = JSONDecoder()
        

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data,
                   let response = try? decoder.decode(SinglePostResponse.self, from: data),
                   response.success {
                    self.post = response.post
                    self.comments = response.comments
                }
            }
        }.resume()
    }
    
    func addComment() {
        guard !newCommentText.isEmpty, userId > 0, let post = post,
              let url = URL(string: "http://127.0.0.1:3000/comments") else {
            commentMessage = "Missing required information."
            return
        }
        
        isPostingComment = true
        commentMessage = ""
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_id": userId,
            "post_id": post.id,
            "comment_text": newCommentText
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isPostingComment = false
                if let error = error {
                    self.commentMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let response = try? JSONDecoder().decode(CommentResponse.self, from: data),
                   response.success {
                    self.newCommentText = ""
                    self.fetchPost() // Refresh post to see new comment
                } else {
                    self.commentMessage = "Failed to post comment."
                }
            }
        }.resume()
    }
}
