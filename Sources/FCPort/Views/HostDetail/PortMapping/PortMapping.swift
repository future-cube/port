import SwiftUI
import Combine

struct PortMappingView: View {
    @EnvironmentObject private var configManager: SSHConfigManager
    let host: SSHConfigModel
    @State private var showAddForm = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题区域
            VStack(spacing: 16) {
                HStack {
                    Text("端口映射")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        var updatedHost = host
                        updatedHost = updatedHost.clearRules()
                        Task {
                            await configManager.updateConfig(updatedHost)
                            EventService.shared.publishHostEvent(.updated(updatedHost))
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清空规则")
                        }
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                    
                    Button(action: { showAddForm.toggle() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加规则")
                        }
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.accentColor)
                }
                
                if showAddForm {
                    AddPortMapping(host: host, onAdd: { rule in
                        var updatedHost = host
                        updatedHost = updatedHost.addRule(rule)
                        Task {
                            await configManager.updateConfig(updatedHost)
                            EventService.shared.publishHostEvent(.updated(updatedHost))
                            showAddForm = false
                        }
                    })
                }
            }
            .padding()
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: .infinity)
            
            // 规则列表
            VStack(spacing: 0) {
                // 表头
                HStack(spacing: 0) {
                    Text("规则名称")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("本地端口")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 120, alignment: .leading)
                    
                    Text("远程端口")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 120, alignment: .leading)
                    
                    Text("操作")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.windowBackgroundColor))
                
                Divider()
                
                // 规则内容
                ForEach(host.rules) { rule in
                    HStack(spacing: 0) {
                        Text(rule.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(rule.localPort)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 120, alignment: .leading)
                        
                        Text(rule.remotePort)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 120, alignment: .leading)
                        
                        HStack(spacing: 8) {
                            Toggle("启用", isOn: Binding(
                                get: { rule.isEnabled },
                                set: { newValue in
                                    var updatedRule = rule
                                    updatedRule.isEnabled = newValue
                                    var updatedHost = host
                                    updatedHost = updatedHost.updateRule(updatedRule)
                                    Task {
                                        await configManager.updateConfig(updatedHost)
                                        EventService.shared.publishHostEvent(.updated(updatedHost))
                                    }
                                }
                            ))
                            .labelsHidden()
                            
                            Button(action: {
                                var updatedHost = host
                                updatedHost = updatedHost.deleteRule(rule.id)
                                Task {
                                    await configManager.updateConfig(updatedHost)
                                    EventService.shared.publishHostEvent(.updated(updatedHost))
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.borderless)
                        }
                        .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    if rule.id != host.rules.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct PortNumberView: View {
    let port: String
    
    var body: some View {
        if port.contains("-") {
            let parts = port.split(separator: "-")
            if parts.count == 2 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(parts[0]))
                    Text("-")
                    Text(String(parts[1]))
                }
                .font(.system(.body, design: .monospaced))
            } else {
                Text(port)
                    .font(.system(.body, design: .monospaced))
            }
        } else if port.contains(",") {
            let parts = port.split(separator: ",")
            VStack(alignment: .leading, spacing: 2) {
                ForEach(parts, id: \.self) { part in
                    Text(String(part))
                }
            }
            .font(.system(.body, design: .monospaced))
        } else {
            Text(port)
                .font(.system(.body, design: .monospaced))
        }
    }
}
