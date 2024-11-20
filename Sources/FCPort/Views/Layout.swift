import SwiftUI
import AppKit

struct Layout: View {
    @StateObject private var configManager = SSHConfigManager()
    @State private var selectedHost: SSHConfigModel?
    @State private var isAddingHost = false
    
    var body: some View {
        NavigationView {
            // Left side - Host List with footer
            VStack(spacing: 0) {
                // Host List
                List(selection: $selectedHost) {
                    ForEach(configManager.configs) { host in
                        NavigationLink(
                            destination: HostDetail(host: host),
                            tag: host,
                            selection: $selectedHost
                        ) {
                            VStack(alignment: .leading) {
                                Text(host.name)
                                    .font(.headline)
                                Text(host.host)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 200)
                
                Divider()
                
                // Footer
                VStack(spacing: 8) {
                    Button(action: { isAddingHost = true }) {
                        Label("添加主机", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Label("退出", systemImage: "power")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(8)
            }
            .frame(minWidth: ViewConstants.minSidebarWidth)
            
            // Right side - Dynamic Content
            .toolbar {
                ToolbarItem {
                    Button(action: { isAddingHost = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingHost) {
                HostEdit(onAdd: { config in
                    Task {
                        await configManager.addConfig(config)
                    }
                })
            }
            
            if let host = selectedHost {
                HostDetail(host: host)
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
