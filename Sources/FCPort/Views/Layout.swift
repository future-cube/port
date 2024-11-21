import SwiftUI
import Combine

struct Layout: View {
    @StateObject private var configManager = SSHConfigManager.shared
    @StateObject private var sshService = SSHService.shared
    @State private var selectedHost: SSHConfigModel?
    @State private var isAddingHost = false
    @State private var showSettings = false
    @State private var showRules = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack {
                HostList(selectedHost: $selectedHost, isAddingHost: $isAddingHost)
                    .environmentObject(configManager)
                    .frame(minWidth: 200)
                
                Divider()
                
                // 底部按钮组
                HStack(spacing: 16) {
                    Button {
                        showRules = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.title)
                            Text("规则")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    
                    Button {
                        showSettings = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "gear")
                                .font(.title)
                            Text("设置")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "power")
                                .font(.title)
                            Text("退出")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(8)
            }
            
            if let host = selectedHost {
                HostDetail(host: host)
                    .environmentObject(configManager)
            } else {
                Text("Select a host")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $isAddingHost) {
            HostEdit(
                onSave: { config in
                    Task {
                        await configManager.addConfig(config)
                        EventService.shared.publishHostEvent(.created(config))
                        selectedHost = config
                        isAddingHost = false
                    }
                },
                onCancel: {
                    isAddingHost = false
                }
            )
        }
        .sheet(isPresented: $showSettings) {
            Setting()
        }
        .sheet(isPresented: $showRules) {
            Rules()
                .environmentObject(configManager)
                .environmentObject(sshService)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    isAddingHost = true
                } label: {
                    VStack {
                        Image(systemName: "plus")
                        Text("添加")
                            .font(.caption)
                    }
                }
            }
        }
        .task {
            // 订阅主机事件
            EventService.shared.hostEventPublisher
                .receive(on: DispatchQueue.main)
                .sink { event in
                    switch event {
                    case .selected(let host):
                        selectedHost = host
                    case .created(let host):
                        selectedHost = host
                    case .updated(let host):
                        if selectedHost?.id == host.id {
                            selectedHost = host
                        }
                    case .deleted(let hostId):
                        if selectedHost?.id == hostId {
                            selectedHost = nil
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }
}
