import SwiftUI

struct APIKeySettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var isKeyVisible = false
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gemini API Key")
                            .font(.headline)
                        
                        HStack {
                            if isKeyVisible {
                                TextField("输入 API Key", text: $apiKey)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("输入 API Key", text: $apiKey)
                                    .textContentType(.password)
                            }
                            
                            Button {
                                isKeyVisible.toggle()
                            } label: {
                                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } footer: {
                    Text("API Key 将安全存储在设备 Keychain 中")
                }
                
                Section {
                    Button {
                        saveAPIKey()
                    } label: {
                        HStack {
                            Spacer()
                            Text("保存")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(apiKey.isEmpty)
                }
                
                Section {
                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.blue)
                            Text("获取 Gemini API Key")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("帮助")
                } footer: {
                    Text("访问 Google AI Studio 免费获取 API Key")
                }
            }
            .navigationTitle("API 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 加载已保存的 API Key
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
