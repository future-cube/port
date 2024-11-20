import SwiftUI

struct HostListView: View {
    let hosts: [SSHConfigModel]
    let selectedHost: SSHConfigModel?
    let onSelect: (SSHConfigModel) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("FC Port")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Host List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(hosts, id: \.id) { host in
                        Item(
                            host: host,
                            isSelected: selectedHost?.id == host.id
                        )
                        .onTapGesture {
                            onSelect(host)
                        }
                    }
                }
            }
        }
    }
}
