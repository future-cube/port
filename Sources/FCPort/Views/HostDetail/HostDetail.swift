import SwiftUI

struct HostDetail: View {
    let host: SSHConfigModel
    let onHostUpdated: (SSHConfigModel) -> Void
    @State private var isEditing = false
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            Toolbar(
                host: host,
                onEdit: { isEditing = true },
                onDelete: {
                    Task {
                        await configManager.deleteConfig(host)
                    }
                }
            )
            
            Divider()
            
            if isEditing {
                HostEdit(
                    host: host,
                    onAdd: { config in
                        Task {
                            await configManager.updateConfig(config)
                            onHostUpdated(config)
                            isEditing = false
                        }
                    },
                    onCancel: {
                        isEditing = false
                    }
                )
            } else {
                // 端口映射管理
                PortMapping(host: host)
            }
        }
    }
}
