import SwiftUI

struct MainAppView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Home Feed Tab
            HomeFeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Camera / Post Content Tab
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Post")
                }
                .tag(1)
            
            // Profile / Settings Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainAppView()
}
