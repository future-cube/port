import SwiftUI

struct PortMapping: View {
    let host: SSHConfigModel
    @StateObject private var manager = PortMappingManager()
    @State private var isAddingMapping = false
    
    var body: some View {
        VStack {
            HStack {
                Text("端口映射")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { isAddingMapping = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            
            if manager.mappings.isEmpty {
                EmptyState(message: "没有端口映射, 请先添加端口映射规则")
            } else {
                List {
                    ForEach(manager.mappings) { mapping in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(mapping.name)
                                    .font(.headline)
                                Text("\(mapping.localPort) → \(mapping.remotePort)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            StatusIndicator(isActive: mapping.isEnabled)
                                .onTapGesture {
                                    Task {
                                        await manager.toggleMapping(mapping)
                                    }
                                }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await manager.removeMapping(at: manager.mappings.firstIndex(of: mapping) ?? 0)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingMapping) {
            NavigationView {
                AddPortMapping(host: host) { mapping in
                    Task {
                        await manager.addMapping(mapping)
                    }
                }
            }
        }
        .task {
            await manager.loadMappings()
        }
    }
}
