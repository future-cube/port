import SwiftUI
import Combine

struct Layout: View {
    @StateObject private var configManager = SSHConfigManager()
    @State private var selectedHost: SSHConfigModel?
    @State private var isAddingHost = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            // 左侧 - 主机列表
            HostList(
                selectedHost: $selectedHost,
                isAddingHost: $isAddingHost
            )
            .frame(minWidth: ViewConstants.minSidebarWidth)
            
            // 右侧 - 动态内容
            if isAddingHost {
                HostEdit(
                    onAdd: { config in
                        Task {
                            await configManager.addConfig(config)
                            EventService.shared.publish(.hostAdded(config))
                        }
                    },
                    onCancel: {
                        isAddingHost = false
                    }
                )
            } else if let host = selectedHost {
                HostDetail(host: host)
            } else {
                EmptyState(message: "请选择一个主机")
            }
        }
        .environmentObject(configManager)
        .task {
            await configManager.loadConfigs()
            
            // 订阅事件
            EventService.shared.eventPublisher
                .receive(on: DispatchQueue.main)
                .sink { event in
                    switch event {
                    case .hostSelected(let host):
                        // 重置所有状态，确保显示选中主机的详情
                        isAddingHost = false
                        selectedHost = host
                        
                    case .hostAdded(let host):
                        // 添加主机后，显示该主机的详情
                        isAddingHost = false
                        selectedHost = host
                        
                    case .hostUpdated(let host):
                        // 更新主机后，刷新显示
                        selectedHost = host
                        
                    case .hostDeleted(let host):
                        // 删除主机后，清除选择
                        if selectedHost?.id == host.id {
                            selectedHost = nil
                        }
                        
                    case .portMappingAdded, .portMappingUpdated, .portMappingDeleted:
                        // 端口映射变更不影响主界面状态
                        break
                    }
                }
                .store(in: &cancellables)
        }
    }
}
