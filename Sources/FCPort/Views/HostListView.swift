import SwiftUI

struct HostListView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @Binding var selectedConfig: SSHConfig?
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HostListHeaderView {
                // 添加新主机
                selectedConfig = nil
            }
            
            Divider()
            
            // 主机列表
            ScrollView {
                LazyVStack(spacing: ViewConstants.smallPadding) {
                    ForEach(configManager.configs) { config in
                        HostListItemView(config: config, isSelected: selectedConfig?.id == config.id)
                            .onTapGesture {
                                selectedConfig = config
                            }
                    }
                }
                .padding(.vertical, ViewConstants.smallPadding)
            }
            .background(ViewConstants.secondaryBackgroundColor)
            
            Divider()
            
            // 底部
            HostListFooterView {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: ViewConstants.hostListWidth)
    }
}
