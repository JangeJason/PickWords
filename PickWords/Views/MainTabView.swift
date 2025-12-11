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
            
            CollectionListPlaceholderView()
                .tabItem {
                    Label("收藏", systemImage: "folder.fill")
                }
        }
    }
}

// MARK: - 占位视图

struct CollectionListPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                
                Text("场景收藏集")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("按生活场景分类单词")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("收藏")
        }
    }
}

#Preview {
    MainTabView()
}
