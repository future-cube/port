import SwiftUI

struct HostList: View {
    @Binding var selectedHost: SSHConfigModel?
    @Binding var isAddingHost: Bool
    let onHostSelected: (SSHConfigModel) -> Void
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text("主机列表")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { isAddingHost = true }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
            
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
                            onHostSelected(host)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 底部退出按钮
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .padding()
        }
    }
}
