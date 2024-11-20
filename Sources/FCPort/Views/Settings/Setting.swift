import SwiftUI

struct Setting: View {
    @AppStorage("autoLaunchEnabled") private var autoLaunchEnabled = false
    @AppStorage("autoForwardEnabled") private var autoForwardEnabled = false
    @AppStorage("showInDock") private var showInDock = false
    @AppStorage("useSystemSSH") private var useSystemSSH = false
    @AppStorage("showPortStatus") private var showPortStatus = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("系统设置")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // 设置项
            ScrollView {
                VStack(spacing: 20) {
                    GroupBox("通用") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("开机自启动", isOn: $autoLaunchEnabled)
                            Toggle("显示在 Dock 中", isOn: $showInDock)
                        }
                        .padding(8)
                    }
                    
                    GroupBox("SSH") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("使用系统 SSH 配置", isOn: $useSystemSSH)
                            Toggle("自动连接", isOn: $autoForwardEnabled)
                        }
                        .padding(8)
                    }
                    
                    GroupBox("端口映射") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("自动映射端口", isOn: $autoForwardEnabled)
                            Toggle("显示端口状态", isOn: $showPortStatus)
                        }
                        .padding(8)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            HStack {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("退出应用") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
}
