import SwiftUI
import UIKit

// MARK: - Profile Image Picker
struct ProfileImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType
    var completion: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.mediaTypes = ["public.image"]
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ProfileImagePicker
        init(_ parent: ProfileImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.completion(data)
            } else {
                parent.completion(nil)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("user_id") private var userId: Int = 0
    @AppStorage("username") private var storedUsername: String = ""
    @AppStorage("email") private var storedEmail: String = ""
    @AppStorage("bio") private var storedBio: String = ""
    @AppStorage("profile_image_url") private var storedProfileImageUrl: String? = nil

    @State private var username: String
    @State private var email: String
    @State private var bio: String
    @State private var message = ""
    
    @State private var profileImageData: Data? = nil
    @State private var profileImageURL: URL? = nil
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    init() {
        _username = State(initialValue: storedUsername)
        _email = State(initialValue: storedEmail)
        _bio = State(initialValue: storedBio)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Account Settings")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                ZStack {
                    if let data = profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else if let url = profileImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                }
                .onTapGesture { showPicker = true }
                
                Text("Tap to change profile image")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding(.horizontal)
                
                ZStack(alignment: .topLeading) {
                    if bio.isEmpty {
                        Text("Bio")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 5)
                    }
                    TextEditor(text: $bio)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        .frame(height: 100)
                }
                .padding(.horizontal)
                
                Button(action: updateUser) {
                    Text("Save Changes")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: logOut) {
                    Text("Log Out")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Text(message)
                    .foregroundColor(.blue)
                    .padding()
                
                Spacer()
            }
            .sheet(isPresented: $showPicker) {
                ProfileImagePicker(sourceType: pickerSource) { data in
                    self.profileImageData = data
                }
            }
            .onAppear {
                if let urlString = storedProfileImageUrl, !urlString.isEmpty {
                    profileImageURL = URL(string: urlString.replacingOccurrences(of: "127.0.0.1", with: "192.168.x.x"))
                }
            }
        }
    }
    
    // MARK: - Actions
    func logOut() {
        isLoggedIn = false
        userId = 0
        storedUsername = ""
        storedEmail = ""
        storedBio = ""
        storedProfileImageUrl = nil
    }
    
    func updateUser() {
        guard let url = URL(string: "http://127.0.0.1:3000/updateUser") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "user_id": userId,
            "username": username,
            "email": email,
            "bio": bio
        ]
        
        if let data = profileImageData {
            body["profile_image_base64"] = data.base64EncodedString()
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { message = "Error: \(error.localizedDescription)" }
                return
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                DispatchQueue.main.async {
                    message = json["message"] as? String ?? "Updated successfully!"
                    if let profileUrl = json["profile_image_url"] as? String {
                        storedProfileImageUrl = profileUrl.replacingOccurrences(of: "127.0.0.1", with: "192.168.x.x")
                        profileImageURL = URL(string: storedProfileImageUrl ?? "")
                        profileImageData = nil
                    }
                    storedUsername = username
                    storedEmail = email
                    storedBio = bio
                }
            }
        }.resume()
    }
}

#Preview {
    SettingsView()
}