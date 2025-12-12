import SwiftUI

/// 应用主题配置 - 可爱风格
enum AppTheme {
    
    // MARK: - 可爱配色
    static let pink = Color(hex: "FF6B9D")           // 主粉色
    static let lavender = Color(hex: "C4B5FD")       // 薰衣草紫
    static let mint = Color(hex: "6EE7B7")           // 薄荷绿
    static let lemon = Color(hex: "FCD34D")          // 柠檬黄
    static let peach = Color(hex: "FBBF24")          // 蜜桃橙
    static let sky = Color(hex: "7DD3FC")            // 天空蓝
    
    // MARK: - 主色调
    static let primary = pink
    static let secondary = lavender
    static let accent = lemon
    
    // MARK: - 背景色
    static let background = Color(hex: "FFF5F8")     // 奶油粉背景
    static let cardBackground = Color.white
    static let secondaryBackground = Color(hex: "FDF2F8")
    
    // MARK: - 文字颜色
    static let textPrimary = Color(hex: "374151")
    static let textSecondary = Color(hex: "9CA3AF")
    
    // MARK: - 功能色
    static let success = mint
    static let warning = peach
    static let error = Color(hex: "F87171")
    
    // MARK: - 可爱渐变
    static let primaryGradient = LinearGradient(
        colors: [pink, lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let softGradient = LinearGradient(
        colors: [Color(hex: "FDF2F8"), Color(hex: "FCE7F3")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let rainbowGradient = LinearGradient(
        colors: [pink, lavender, sky, mint],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - 圆角（更圆润）
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 20
    static let cornerRadiusXLarge: CGFloat = 28
    
    // MARK: - 可爱装饰元素
    static let decorations = ["✨", "🌸", "⭐", "💖", "🎀", "🌈"]
}

// MARK: - Color Hex 扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 可爱按钮样式
struct CuteButtonStyle: ButtonStyle {
    var color: Color = AppTheme.pink
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                        .fill(color)
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .foregroundStyle(.white)
            .shadow(color: color.opacity(0.4), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CuteSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                    .fill(AppTheme.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                    .stroke(AppTheme.pink.opacity(0.3), lineWidth: 2)
            )
            .foregroundStyle(AppTheme.pink)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// 保留旧名称的别名
typealias PrimaryButtonStyle = CuteButtonStyle
typealias SecondaryButtonStyle = CuteSecondaryButtonStyle

// MARK: - 可爱空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // 可爱装饰背景
            ZStack {
                // 装饰圆圈
                Circle()
                    .fill(AppTheme.pink.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(AppTheme.lavender.opacity(0.15))
                    .frame(width: 110, height: 110)
                
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.primaryGradient)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // 装饰星星
                Text("✨")
                    .font(.system(size: 24))
                    .offset(x: 50, y: -40)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Text("🌸")
                    .font(.system(size: 20))
                    .offset(x: -55, y: 30)
                    .rotationEffect(.degrees(isAnimating ? -5 : 5))
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text(message)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Text("✨")
                        Text(actionTitle)
                        Text("✨")
                    }
                }
                .buttonStyle(CuteButtonStyle())
                .padding(.horizontal, 50)
                .padding(.top, 8)
            }
        }
        .padding(32)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 可爱卡片容器
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
            .shadow(color: AppTheme.pink.opacity(0.15), radius: 12, y: 6)
    }
}

// MARK: - 可爱卡片样式修饰器
struct CuteCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
            .shadow(color: AppTheme.pink.opacity(0.12), radius: 10, y: 4)
    }
}

extension View {
    func cuteCard() -> some View {
        modifier(CuteCardModifier())
    }
}

// MARK: - 可爱标题组件
struct CuteTitle: View {
    let text: String
    var decoration: String = "🌸"
    
    var body: some View {
        HStack(spacing: 8) {
            Text(decoration)
            Text(text)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(decoration)
        }
    }
}

// MARK: - 可爱标签
struct CuteTag: View {
    let text: String
    var color: Color = AppTheme.pink
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color)
            )
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
