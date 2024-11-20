import SwiftUI
import Combine

struct HostDetail: View {
    let host: SSHConfigModel
    @State private var isEditing = false
    @State private var cancellables = Set<AnyCancellable>()
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
                        EventService.shared.publish(.hostDeleted(host))
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
                            EventService.shared.publish(.hostUpdated(config))
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
        .task {
            // 订阅主机选择事件，取消编辑状态
            EventService.shared.eventPublisher
                .receive(on: DispatchQueue.main)
                .sink { event in
                    if case .hostSelected = event {
                        isEditing = false
                    }
                }
                .store(in: &cancellables)
        }
    }
}
