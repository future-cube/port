import SwiftUI
import Combine

struct Layout: View {
    @StateObject private var configManager = SSHConfigManager.shared
    @State private var selectedHost: SSHConfigModel?
    @State private var isAddingHost = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            HostList(selectedHost: $selectedHost, isAddingHost: $isAddingHost)
                .environmentObject(configManager)
                .frame(minWidth: 200)
            
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
                onAdd: { config in
                    Task {
                        await configManager.addConfig(config)
                        EventService.shared.publishHostEvent(.created(config))
                        isAddingHost = false
                    }
                },
                onCancel: {
                    isAddingHost = false
                }
            )
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
