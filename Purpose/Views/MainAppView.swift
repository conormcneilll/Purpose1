import SwiftUI

struct MainAppView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
           
            HomeFeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
          
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Post")
                }
                .tag(1)
            
        
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
