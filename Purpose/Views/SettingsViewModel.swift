import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("username") var storedUsername: String = ""
    @AppStorage("email") var storedEmail: String = ""
    @AppStorage("bio") var storedBio: String = ""
    @AppStorage("profile_image_url") var storedProfileImageUrl: String = ""

    @Published var username: String = "" // Give it a default value
    @Published var email: String = "" // Give it a default value
    @Published var bio: String = "" // Give it a default value
    
    @Published var profileImageData: Data? = nil
    @Published var profileImageURL: URL? = nil

    init() {
        // Now that the @Published properties have a default value, we can safely
        // access 'self' and its other properties like storedUsername.
        self.username = storedUsername
        self.email = storedEmail
        self.bio = storedBio
        
        if !storedProfileImageUrl.isEmpty {
            self.profileImageURL = URL(string: storedProfileImageUrl)
        }
    }
}
