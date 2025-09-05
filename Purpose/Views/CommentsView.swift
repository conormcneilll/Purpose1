import SwiftUI

struct CommentsView: View {
    let postId: Int
    @AppStorage("user_id") private var userId: Int = 0
    
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""
    @State private var isLoading = false
    @State private var message: String = ""
    
    var body: some View {
        VStack {
            // Display existing comments
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment)
                    }
                }
                .padding()
            }
            .refreshable {
                fetchComments()
            }
            
            // Text field and button to add new comment
            HStack {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Post") {
                    addComment()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newCommentText.isEmpty || isLoading)
            }
            .padding()
            
            if !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchComments()
        }
    }
    
    // MARK: - Networking
    
    func fetchComments() {
        guard let url = URL(string: "http://127.0.0.1:3000/posts/\(postId)") else { return }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data,
                   let response = try? JSONDecoder().decode(SinglePostResponse.self, from: data),
                   response.success {
                    self.comments = response.comments
                } else {
                    self.message = "Failed to fetch comments."
                }
            }
        }.resume()
    }
    
    func addComment() {
        guard !newCommentText.isEmpty,
              userId > 0,
              let url = URL(string: "http://127.0.0.1:3000/comments") else {
            return
        }
        
        isLoading = true
        message = ""
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_id": userId,
            "post_id": postId,
            "comment_text": newCommentText
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.message = "Error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let response = try? JSONDecoder().decode(CommentResponse.self, from: data),
                   response.success {
                    self.newCommentText = ""
                    self.fetchComments()
                } else {
                    self.message = "Failed to post comment."
                }
            }
        }.resume()
    }
}

// MARK: - CommentRow
struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(comment.username)
                .font(.headline)
            + Text(" \(comment.comment_text)")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}
