import SwiftUI

struct Layout: View {
    @StateObject private var configManager = SSHConfigManager()
    @State private var selectedHost: SSHConfigModel?
    @State private var isAddingHost = false
    
    var body: some View {
        NavigationView {
            // 左侧 - 主机列表
            HostList(
                selectedHost: $selectedHost,
                isAddingHost: $isAddingHost,
                onHostSelected: { host in
                    if !isAddingHost {
                        selectedHost = host
                    }
                }
            )
            .frame(minWidth: ViewConstants.minSidebarWidth)
            
            // 右侧 - 动态内容
            if isAddingHost {
                HostEdit(
                    onAdd: { config in
                        Task {
                            await configManager.addConfig(config)
                            selectedHost = config
                            isAddingHost = false
                        }
                    },
                    onCancel: {
                        isAddingHost = false
                    }
                )
            } else if let host = selectedHost {
                HostDetail(
                    host: host,
                    onHostUpdated: { updatedHost in
                        selectedHost = updatedHost
                    }
                )
            } else {
                EmptyState(message: "请选择一个主机")
            }
        }
        .environmentObject(configManager)
        .task {
            await configManager.loadConfigs()
        }
    }
}
