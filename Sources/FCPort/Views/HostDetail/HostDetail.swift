import SwiftUI

struct HostDetail: View {
    let host: SSHConfigModel
    @StateObject private var configManager = SSHConfigManager()
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            Toolbar(
                host: host,
                onEdit: { isEditing = true },
                onDelete: {}  // Will be handled by parent
            )
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    PortMapping(host: host)
                }
                .padding()
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationView {
                HostEdit(host: host, onAdd: { config in
                    Task {
                        await configManager.updateConfig(config)
                    }
                })
            }
        }
    }
}
