import SwiftUI
import Combine

struct Layout: View {
    @StateObject private var configManager = SSHConfigManager()
    @State private var selectedHost: SSHConfigModel?
    @State private var isAddingHost = false
    @State private var isShowingSettings = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            // 左侧列表
            VStack(spacing: 0) {
                // 左侧标题栏
                HStack {
                    Text("主机列表")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        isAddingHost = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.accentColor)
                    }
                    .sheet(isPresented: $isAddingHost) {
                        HostEdit(
                            host: nil,
                            onAdd: { config in
                                EventService.shared.publishHostEvent(.created(config))
                                isAddingHost = false
                            },
                            onCancel: {
                                isAddingHost = false
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .frame(height: 64)
                
                Divider()
                
                List(configManager.configs) { host in
                    Item(host: host, isSelected: selectedHost?.id == host.id)
                        .contentShape(Rectangle())  // 使整个区域可点击
                        .onTapGesture {
                            EventService.shared.publishHostEvent(.selected(host))
                        }
                }
                
                HStack {
                    Button(action: {
                        isShowingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.accentColor)
                    }
                    .sheet(isPresented: $isShowingSettings) {
                        Setting()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .frame(minWidth: 200)
            
            // 右侧详情
            HostDetail(host: selectedHost)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environmentObject(configManager)
        .task {
            await configManager.loadConfigs()
            
            // 订阅主机事件
            EventService.shared.hostEventPublisher
                .receive(on: RunLoop.main)
                .sink { event in
                    switch event {
                    case .selected(let host):
                        // 选中主机
                        selectedHost = host
                        isAddingHost = false
                        isShowingSettings = false
                        
                    case .created(let host):
                        // 创建主机
                        Task {
                            await configManager.addConfig(host)
                            selectedHost = host
                        }
                        
                    case .updated(let host):
                        // 更新主机
                        Task {
                            await configManager.updateConfig(host)
                            if selectedHost?.id == host.id {
                                selectedHost = host
                            }
                        }
                        
                    case .deleted(let hostId):
                        // 删除主机
                        Task {
                            if let host = configManager.configs.first(where: { $0.id == hostId }) {
                                await configManager.deleteConfig(host)
                                if selectedHost?.id == hostId {
                                    selectedHost = nil
                                }
                            }
                        }
                    }
                }
                .store(in: &cancellables)
                
            // 订阅规则事件
            EventService.shared.ruleEventPublisher
                .receive(on: RunLoop.main)
                .sink { event in
                    switch event {
                    case .created(let rule, let hostId),
                         .updated(let rule, let hostId):
                        // 创建或更新规则
                        Task {
                            if let index = configManager.configs.firstIndex(where: { $0.id == hostId }) {
                                var host = configManager.configs[index]
                                if case .created = event {
                                    host.addRule(rule)
                                } else {
                                    host.updateRule(rule)
                                }
                                await configManager.updateConfig(host)
                                if selectedHost?.id == hostId {
                                    selectedHost = host
                                }
                            }
                        }
                        
                    case .deleted(let ruleId, let hostId):
                        // 删除规则
                        Task {
                            if let index = configManager.configs.firstIndex(where: { $0.id == hostId }) {
                                var host = configManager.configs[index]
                                host.deleteRule(ruleId)
                                await configManager.updateConfig(host)
                                if selectedHost?.id == hostId {
                                    selectedHost = host
                                }
                            }
                        }
                        
                    case .cleared(let hostId):
                        // 清空规则
                        Task {
                            if let index = configManager.configs.firstIndex(where: { $0.id == hostId }) {
                                var host = configManager.configs[index]
                                host.clearRules()
                                await configManager.updateConfig(host)
                                if selectedHost?.id == hostId {
                                    selectedHost = host
                                }
                            }
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }
}
