import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("user_id") private var userId: Int = 0

    @State private var message = ""
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Account Settings")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                ZStack {
                    if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else if let url = viewModel.profileImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                )
                        }
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.white)
                            )
                    }

                    Button(action: { showPicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.accentColor)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: 40, y: 40)
                    }
                }
                .sheet(isPresented: $showPicker) {
                    ProfileImagePicker(sourceType: .photoLibrary) { data in
                        viewModel.profileImageData = data
                    }
                }

                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding(.horizontal)

                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding(.horizontal)

                ZStack(alignment: .topLeading) {
                    if viewModel.bio.isEmpty {
                        Text("Bio")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 5)
                    }
                    TextEditor(text: $viewModel.bio)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.5), width: 1)
                        .cornerRadius(5)
                }
                .padding(.horizontal)

                Text(message)
                    .foregroundColor(.red)
                    .padding(.top)

                Button("Update Profile") {
                    updateUser()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()

                Button("Log Out") {
                    isLoggedIn = false
                }
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarHidden(true)
            .onAppear {
                fetchProfile()
            }
        }
    }

    // MARK: - Networking
    func fetchProfile() {
        guard userId > 0,
              let url = URL(string: "http://127.0.0.1:3000/user/\(userId)/profile") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let profile = json["profile"] as? [String: Any] {

                DispatchQueue.main.async {
                    // Update ViewModel properties directly
                    viewModel.username = profile["username"] as? String ?? ""
                    viewModel.email = profile["email"] as? String ?? ""
                    viewModel.bio = profile["bio"] as? String ?? ""

                    // Update AppStorage through the ViewModel
                    viewModel.storedUsername = viewModel.username
                    viewModel.storedEmail = viewModel.email
                    viewModel.storedBio = viewModel.bio

                    if let imageUrlString = profile["profile_image_url"] as? String {
                       // ⚠️ Corrected: Use the URL as is from the server
                       viewModel.storedProfileImageUrl = imageUrlString
                       viewModel.profileImageURL = URL(string: viewModel.storedProfileImageUrl)
                    } else {
                        viewModel.storedProfileImageUrl = ""
                        viewModel.profileImageURL = nil
                    }
                }
            }
        }.resume()
    }

    func updateUser() {
        guard userId > 0,
              let url = URL(string: "http://127.0.0.1:3000/updateUser") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "user_id": userId,
            "username": viewModel.username,
            "email": viewModel.email,
            "bio": viewModel.bio
        ]

        if let data = viewModel.profileImageData {
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
                        // ⚠️ Corrected: Use the URL as is from the server
                        viewModel.storedProfileImageUrl = profileUrl
                        viewModel.profileImageURL = URL(string: viewModel.storedProfileImageUrl)
                        viewModel.profileImageData = nil
                    }
                    viewModel.storedUsername = viewModel.username
                    viewModel.storedEmail = viewModel.email
                    viewModel.storedBio = viewModel.bio
                }
            }
        }.resume()
    }
}
