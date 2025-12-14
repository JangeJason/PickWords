import SwiftUI

struct APIKeySettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var isKeyVisible = false
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 图标
                        Circle()
                            .fill(AppTheme.pink.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "key.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(AppTheme.pink)
                            )
                            .padding(.top, 20)
                        
                        // 标题
                        Text("通义千问 API Key")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        // 输入框卡片
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                if isKeyVisible {
                                    TextField("输入 API Key", text: $apiKey)
                                        .textContentType(.password)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .font(.system(size: 15, design: .rounded))
                                } else {
                                    SecureField("输入 API Key", text: $apiKey)
                                        .textContentType(.password)
                                        .font(.system(size: 15, design: .rounded))
                                }
                                
                                Button {
                                    isKeyVisible.toggle()
                                } label: {
                                    Image(systemName: isKeyVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundStyle(AppTheme.lavender)
                                }
                            }
                            .padding(16)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                            
                            Text("API Key 将安全存储在设备 Keychain 中")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 20)
                        
                        // 保存按钮
                        Button {
                            saveAPIKey()
                        } label: {
                            Text("保存")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    apiKey.isEmpty ? AppTheme.pink.opacity(0.5) : AppTheme.pink
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: AppTheme.pink.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(apiKey.isEmpty)
                        .padding(.horizontal, 20)
                        
                        // 帮助链接
                        VStack(spacing: 12) {
                            Text("帮助")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Link(destination: URL(string: "https://dashscope.console.aliyun.com/apiKey")!) {
                                HStack {
                                    Circle()
                                        .fill(AppTheme.lavender.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "link")
                                                .font(.system(size: 16))
                                                .foregroundStyle(AppTheme.lavender)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("获取通义千问 API Key")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(AppTheme.textPrimary)
                                        
                                        Text("访问阿里云 DashScope 控制台")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                .padding(12)
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("API 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.pink)
                }
            }
            .onAppear {
                if let savedKey = KeychainService.shared.getGeminiAPIKey() {
                    apiKey = savedKey
                }
            }
            .alert("保存成功", isPresented: $showSaveSuccess) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("API Key 已安全保存")
            }
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if KeychainService.shared.saveGeminiAPIKey(trimmedKey) {
            showSaveSuccess = true
        }
    }
}

#Preview {
    APIKeySettingView()
}
