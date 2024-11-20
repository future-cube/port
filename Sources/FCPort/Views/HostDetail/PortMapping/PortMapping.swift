import SwiftUI
import Combine

struct PortMappingView: View {
    let host: SSHConfigModel
    @EnvironmentObject var configManager: SSHConfigManager
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
                        Task {
                            EventService.shared.publishRuleEvent(.cleared(host.id))
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
                        Task {
                            EventService.shared.publishRuleEvent(.created(rule, host.id))
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
                ForEach(host.rules, id: \.id) { rule in
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
                                Task {
                                    var updatedRule = rule
                                    updatedRule.isEnabled = newValue
                                    EventService.shared.publishRuleEvent(.updated(updatedRule, host.id))
                                }
                            }
                        ))
                        .labelsHidden()
                        
                        Button(action: {
                            Task {
                                EventService.shared.publishRuleEvent(.deleted(rule.id, host.id))
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
        .onAppear {
            // rules = host.rules
        }
    }
}
