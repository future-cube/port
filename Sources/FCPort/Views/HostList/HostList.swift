import SwiftUI

struct HostList: View {
    @Binding var selectedHost: SSHConfigModel?
    @Binding var isAddingHost: Bool
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text("主机列表")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: { isAddingHost = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("添加")
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(height: 64)
            .background(Color(NSColor.windowBackgroundColor))
            .shadow(color: Color.black.opacity(0.1), radius: 2, y: 2)
            
            // 列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(configManager.configs) { host in
                        Item(
                            host: host,
                            isSelected: selectedHost?.id == host.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            EventService.shared.publishHostEvent(.selected(host))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // 底部退出按钮
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .font(.title3)
                    Text("退出")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderless)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(8)
            .padding(12)
        }
    }
}
