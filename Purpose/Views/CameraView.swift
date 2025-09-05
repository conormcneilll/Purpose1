import SwiftUI
import PhotosUI
import AVFoundation

struct MediaPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType
    var completion: (Data?, String) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.videoQuality = .typeHigh
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: MediaPicker
        init(_ parent: MediaPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.completion(data, "image")
            } else if let url = info[.mediaURL] as? URL,
                      let data = try? Data(contentsOf: url) {
                parent.completion(data, "video")
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CameraView: View {
    @AppStorage("user_id") private var userId: Int = 0
    @State private var dailyPrompt: Prompt? = nil
    @State private var caption: String = ""
    @State private var selectedData: Data? = nil
    @State private var selectedType: String = "image"
    @State private var isUploading: Bool = false
    @State private var uploadMessage: String = ""

    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showActionSheet = false

    var body: some View {
        VStack(spacing: 20) {
            // Prompt
            if let prompt = dailyPrompt {
                Text("📌 Today's Prompt:")
                    .font(.headline)
                Text(prompt.prompt_text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("Loading today's prompt...")
                    .foregroundColor(.gray)
            }

            // Media Preview
            ZStack {
                if let data = selectedData {
                    if selectedType == "image", let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .cornerRadius(10)
                            .overlay(Text("Video Selected").foregroundColor(.gray))
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(10)
                        .overlay(Text("Select or Capture Media").foregroundColor(.gray))
                }
            }

            TextField("Add a caption...", text: $caption)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)


            HStack(spacing: 16) {
                // Upload / Capture Button
                Button(action: { showActionSheet = true }) {
                    Text(selectedData == nil ? "Upload / Pose" : "Change Media")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(title: Text("Select Media Source"), buttons: [
                        .default(Text("Photo/Video Library")) {
                            pickerSource = .photoLibrary
                            showPicker = true
                        },
                        .default(Text("Camera")) {
                            pickerSource = .camera
                            showPicker = true
                        },
                        .cancel()
                    ])
                }

                Button(action: uploadPost) {
                    if isUploading { ProgressView() }
                    Text("Post").bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedData != nil ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedData == nil || isUploading)
            }

            // Cancel / Reset Button
            if selectedData != nil {
                Button("Cancel Selection") {
                    selectedData = nil
                    caption = ""
                    selectedType = "image"
                    uploadMessage = ""
                }
                .foregroundColor(.red)
                .padding(.top, 8)
            }

            // Upload status message
            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .onAppear(perform: fetchDailyPrompt)
        .sheet(isPresented: $showPicker) {
            MediaPicker(sourceType: pickerSource) { data, type in
                self.selectedData = data
                self.selectedType = type
            }
        }
    }

    func fetchDailyPrompt() {
    
        guard let url = URL(string: "http://127.0.0.1:3000/prompts/random") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            if let result = try? JSONDecoder().decode(PromptResponse.self, from: data) {
                DispatchQueue.main.async { self.dailyPrompt = result.prompt }
            }
        }.resume()
    }

    func uploadPost() {
        guard let data = selectedData,
              let prompt = dailyPrompt,
              userId > 0 else {
            uploadMessage = "Missing required information"
            return
        }

        isUploading = true
        uploadMessage = ""

        let base64Media = data.base64EncodedString()
        let body: [String: Any] = [
            "user_id": userId,
            "image_base64": base64Media,
            "media_type": selectedType,
            "caption": caption,
            "prompt_id": prompt.id
        ]

        guard let url = URL(string: "http://127.0.0.1:3000/posts") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isUploading = false }

            if let error = error {
                DispatchQueue.main.async { self.uploadMessage = "Error: \(error.localizedDescription)" }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 409 {
                    DispatchQueue.main.async { self.uploadMessage = "Oops! You've already shared for today's prompt. ✨ Check back tomorrow!" }
                    return
                }
            }

            if let data = data,
               let response = try? JSONDecoder().decode(UploadResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.uploadMessage = response.message
                    if response.success {
                        self.selectedData = nil
                        self.caption = ""
                    }
                }
            }
        }.resume()
    }
}

#Preview {
    CameraView()
}
