import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("username") var storedUsername: String = ""
    @AppStorage("email") var storedEmail: String = ""
    @AppStorage("bio") var storedBio: String = ""
    @AppStorage("profile_image_url") var storedProfileImageUrl: String = ""

    @Published var username: String = ""
    @Published var email: String = ""
    @Published var bio: String = ""
    
    @Published var profileImageData: Data? = nil
    @Published var profileImageURL: URL? = nil

    init() {
        
        self.username = storedUsername
        self.email = storedEmail
        self.bio = storedBio
        
        if !storedProfileImageUrl.isEmpty {
            self.profileImageURL = URL(string: storedProfileImageUrl)
        }
    }
}
