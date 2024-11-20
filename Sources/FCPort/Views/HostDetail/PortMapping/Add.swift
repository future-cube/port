import SwiftUI

struct AddPortMapping: View {
    let host: SSHConfigModel
    let onAdd: (PortMappingModel) -> Void
    
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
                            let filtered = newValue.filter { $0.isNumber }.prefix(5)
                            localPort = String(filtered)
                        }
                    TextField("远程端口", text: $remotePort)
                        .onChange(of: remotePort) { newValue in
                            let filtered = newValue.filter { $0.isNumber }.prefix(5)
                            remotePort = String(filtered)
                        }
                }
            }
            .navigationTitle("添加端口映射")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let mapping = PortMappingModel(
                            name: name,
                            localPort: Int(localPort) ?? 0,
                            remotePort: Int(remotePort) ?? 0,
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
