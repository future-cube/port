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
            VStack(spacing: 8) {
                ForEach(host.rules) { rule in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("本地端口 \(rule.localPort) → 远程端口 \(rule.remotePort)")
                                .font(.body)
                            Text(rule.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
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
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .help("删除规则")
                    }
                    .padding()
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                }
                
                if host.rules.isEmpty {
                    Text("暂无规则")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
