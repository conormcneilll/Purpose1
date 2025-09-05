import SwiftUI

struct ContentView: View {
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("username") private var storedUsername = ""
    @AppStorage("email") private var storedEmail = ""
    @AppStorage("user_id") private var userId: Int = 0
    
    @State private var email = ""
    @State private var password = ""
    @State private var username = "" 
    @State private var isLogin = true
    @State private var message = ""
    
    var body: some View {
    
        if isLoggedIn {
            MainAppView()
        } else {
            NavigationStack {
                VStack(spacing: 20) {
                    Image("PurposeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding(.bottom, 20)
                    
                    
                    if !isLogin {
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: {
                        if isLogin {
                            loginUser()
                        } else {
                            signupUser()
                        }
                    }) {
                        Text(isLogin ? "Login" : "Sign Up")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        isLogin.toggle()
                    }) {
                        Text(isLogin ? "Don’t have an account? Sign Up" : "Already have an account? Login")
                            .font(.footnote)
                    }
                    
                    Text(message)
                        .foregroundColor(.red)
                        .padding()
                }
                .padding()
            }
        }
    }
    
    // MARK: - Networking
    func loginUser() {
        sendRequest(endpoint: "login")
    }
    
    func signupUser() {
        sendRequest(endpoint: "signup")
    }
    
    func sendRequest(endpoint: String) {
        guard let url = URL(string: "http://127.0.0.1:3000/\(endpoint)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["email": email, "password": password]
        if !isLogin {
            body["username"] = username
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { self.message = "Error: \(error.localizedDescription)" }
                return
            }
            
            if let data = data {
                if let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    DispatchQueue.main.async {
                        self.message = responseJSON["message"] as? String ?? "Unknown response"
                        
                       
                        if responseJSON["success"] as? Bool == true {
                            
                            if let username = responseJSON["username"] as? String {
                                self.storedUsername = username
                            }
                            if let email = responseJSON["email"] as? String {
                                self.storedEmail = email
                            }
                            if let id = responseJSON["user_id"] as? Int { // Saves my user_id
                                self.userId = id
                            }
                            
                            self.isLoggedIn = true
                        }
                    }
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
