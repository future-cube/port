import SwiftUI

struct AddPortMapping: View {
    let host: SSHConfigModel
    let onAdd: (PortMappingModel) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var localPort = ""
    @State private var remotePort = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("名称", text: $name)
                    TextField("本地端口", text: $localPort)
                        .onChange(of: localPort) { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            localPort = filtered
                        }
                    TextField("远程端口", text: $remotePort)
                        .onChange(of: remotePort) { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            remotePort = filtered
                        }
                }
            }
            .navigationTitle("添加端口映射")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let localPortInt = Int(localPort),
                              let remotePortInt = Int(remotePort) else { return }
                        
                        let mapping = PortMappingModel(
                            id: UUID(),
                            hostId: host.id,
                            name: name,
                            localPort: localPortInt,
                            remotePort: remotePortInt,
                            isEnabled: false
                        )
                        onAdd(mapping)
                        dismiss()
                    }
                    .disabled(name.isEmpty || localPort.isEmpty || remotePort.isEmpty)
                }
            }
        }
    }
}
