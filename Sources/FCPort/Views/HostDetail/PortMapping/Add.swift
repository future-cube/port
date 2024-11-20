import SwiftUI

struct AddPortMapping: View {
    let host: SSHConfigModel
    let onAdd: (PortMapping) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var localPort = ""
    @State private var remotePort = ""
    @State private var isHoveringHelp = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Text("添加端口映射")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Button(action: {
                        isHoveringHelp.toggle()
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $isHoveringHelp) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("端口映射格式说明:")
                                .font(.headline)
                            Text("• 单端口映射: 80对80")
                            Text("• 多端口映射: 80,82对82,85,88")
                            Text("• 端口范围映射: 80-90对110-120")
                        }
                        .padding()
                        .frame(width: 280)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            // 表单内容
            VStack(alignment: .leading, spacing: 16) {
                // 映射名称
                HStack {
                    Text("映射名称")
                        .frame(width: 100, alignment: .leading)
                    TextField("请输入映射名称", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                // 本地端口
                HStack {
                    Text("本地端口")
                        .frame(width: 100, alignment: .leading)
                    TextField("如: 80", text: $localPort)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: localPort) { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            localPort = filtered
                        }
                }
                
                // 远程端口
                HStack {
                    Text("远程端口")
                        .frame(width: 100, alignment: .leading)
                    TextField("如: 80", text: $remotePort)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: remotePort) { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            remotePort = filtered
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.textBackgroundColor))
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("保存") {
                    guard let localPortInt = Int(localPort),
                          let remotePortInt = Int(remotePort) else { return }
                    
                    let mapping = PortMapping(
                        name: name,
                        localPort: localPortInt,
                        remotePort: remotePortInt,
                        isEnabled: true
                    )
                    onAdd(mapping)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || localPort.isEmpty || remotePort.isEmpty)
                .keyboardShortcut(.return)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            // 提示信息
            Text("端口范围：1-65535")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .frame(width: 400)
    }
}
