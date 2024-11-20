import SwiftUI

struct AddPortMapping: View {
    let host: SSHConfigModel
    let onAdd: (PortMapping) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var localPort = ""
    @State private var remotePort = ""
    @State private var isHoveringHelp = false
    @State private var errorMessage: String?
    
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
                            Text("• 单端口映射: 80")
                            Text("• 多端口映射: 80,82,85")
                            Text("• 端口范围映射: 80-90")
                            Text("• IPv6 端口映射: [::1]:80")
                            Text("\n所有端口必须在1-65535之间")
                                .foregroundColor(.secondary)
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
                    TextField("如: 80,81,82 或 80-90 或 [::1]:80", text: $localPort)
                        .textFieldStyle(.roundedBorder)
                }
                
                // 远程端口
                HStack {
                    Text("远程端口")
                        .frame(width: 100, alignment: .leading)
                    TextField("如: 80,81,82 或 80-90 或 [::1]:80", text: $remotePort)
                        .textFieldStyle(.roundedBorder)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
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
                    do {
                        // 验证端口格式
                        try PortValidator.validate(localPort)
                        try PortValidator.validate(remotePort)
                        
                        // 创建新规则
                        let mapping = PortMapping(
                            name: name.isEmpty ? "新规则" : name,
                            localPort: localPort,
                            remotePort: remotePort
                        )
                        
                        onAdd(mapping)
                        dismiss()
                    } catch let error as PortValidationError {
                        errorMessage = error.localizedDescription
                    } catch {
                        errorMessage = "发生未知错误"
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400)
    }
}
