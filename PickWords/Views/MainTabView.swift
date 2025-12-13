import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WordCardListView()
                .tabItem {
                    Label("单词本", systemImage: "book.fill")
                }
                .tag(1)
            
            CameraView()
                .tabItem {
                    Label("拍照", systemImage: "camera.fill")
                }
                .tag(0)
            
            CollectionListView()
                .tabItem {
                    Label("收藏集", systemImage: "folder.fill")
                }
                .tag(2)
        }
        .tint(AppTheme.pink)
    }
}

#Preview {
    MainTabView()
}
