import SwiftUI
import Combine

struct HostDetail: View {
    let host: SSHConfigModel?
    @State private var isEditing = false
    @State private var cancellables = Set<AnyCancellable>()
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        VStack(spacing: 0) {
            if let host = host {
                // 工具栏
                VStack(spacing: 0) {
                    Toolbar(
                        host: host,
                        onEdit: {
                            isEditing = true
                        },
                        onDelete: {
                            Task {
                                await configManager.deleteConfig(host)
                                EventService.shared.publishHostEvent(.deleted(host.id))
                            }
                        }
                    )
                    .background(Color(.windowBackgroundColor))
                    
                    Divider()
                }
                
                // 内容区域
                ScrollView {
                    VStack(spacing: 16) {
                        if isEditing {
                            HostEdit(
                                host: host,
                                onAdd: { config in
                                    Task {
                                        await configManager.updateConfig(config)
                                        EventService.shared.publishHostEvent(.updated(config))
                                        isEditing = false
                                    }
                                },
                                onCancel: {
                                    isEditing = false
                                }
                            )
                            .background(Color(.windowBackgroundColor))
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        } else {
                            PortMappingView(host: host)
                        }
                    }
                    .padding(16)
                }
                .background(Color(.textBackgroundColor))
            } else {
                EmptyState(message: "选择一个主机")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.textBackgroundColor))
        .task {
            // 订阅主机选择事件，取消编辑状态
            EventService.shared.eventPublisher
                .receive(on: DispatchQueue.main)
                .sink { event in
                    if case .host(.selected) = event {
                        isEditing = false
                    }
                }
                .store(in: &cancellables)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
