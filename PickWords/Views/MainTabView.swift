import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("拍照", systemImage: "camera.fill")
                }
            
            WordCardListView()
                .tabItem {
                    Label("单词", systemImage: "rectangle.stack.fill")
                }
            
            CollectionListView()
                .tabItem {
                    Label("收藏", systemImage: "folder.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
