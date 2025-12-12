import SwiftUI

/// 应用主题配置
enum AppTheme {
    
    // MARK: - 主色调
    static let primary = Color.blue
    static let secondary = Color.gray
    static let accent = Color.orange
    
    // MARK: - 背景色
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    
    // MARK: - 文字颜色
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // MARK: - 功能色
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // MARK: - 渐变
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.blue.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color.orange, Color.red.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 阴影
    static func cardShadow() -> some View {
        Color.black.opacity(0.1)
    }
    
    // MARK: - 圆角
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 20
}

// MARK: - 自定义按钮样式
struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isDisabled ? Color.gray : (configuration.isPressed ? AppTheme.primary.opacity(0.8) : AppTheme.primary)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(configuration.isPressed ? 0.2 : 0.15))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 空状态视图组件
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }
        }
        .padding()
    }
}

// MARK: - 卡片容器
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

// MARK: - 动画修饰器
extension View {
    func cardAppearAnimation(delay: Double = 0) -> some View {
        self
            .opacity(1)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay), value: UUID())
    }
    
    func bounceEffect(_ isActive: Bool) -> some View {
        self
            .scaleEffect(isActive ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

#Preview {
    VStack(spacing: 30) {
        EmptyStateView(
            icon: "rectangle.stack.badge.plus",
            title: "还没有单词卡片",
            message: "拍摄物品开始学习英语单词",
            actionTitle: "开始拍照"
        ) {
            print("Action tapped")
        }
        
        Button("Primary Button") {}
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        
        Button("Secondary Button") {}
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal)
    }
}
