import SwiftUI

struct Setting: View {
    @AppStorage("autoLaunchEnabled") private var autoLaunchEnabled = false
    @Environment(\.dismiss) private var dismiss
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("设置")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            
            Divider()
            
            // 设置项
            List {
                Section {
                    Toggle("开机自动启动", isOn: $autoLaunchEnabled)
                        .onChange(of: autoLaunchEnabled) { newValue in
                            toggleAutoLaunch(enabled: newValue)
                        }
                }
            }
            
            Spacer()
            
            // 版本信息
            HStack {
                Text("版本 \(version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 400, height: 200)
    }
    
    private func toggleAutoLaunch(enabled: Bool) {
        // 暂时禁用自启动功能，等完成应用打包后再实现
        print("Auto launch will be implemented after app packaging")
    }
}

struct Setting_Previews: PreviewProvider {
    static var previews: some View {
        Setting()
    }
}
