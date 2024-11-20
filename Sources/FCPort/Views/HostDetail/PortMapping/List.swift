import SwiftUI

struct PortMappingList: View {
    let mappings: [PortMapping]
    let onToggle: (PortMapping) -> Void
    let onDelete: (PortMapping) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("名称")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("本地端口")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 100)
                
                Text("远程端口")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 100)
                
                Text("状态")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 60)
                
                Text("操作")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 60)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 列表内容
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(mappings) { mapping in
                        HStack {
                            Text(mapping.name)
                                .font(.body)
                            
                            Spacer()
                            
                            Text(String(mapping.localPort))
                                .font(.body)
                                .frame(width: 100)
                            
                            Text(String(mapping.remotePort))
                                .font(.body)
                                .frame(width: 100)
                            
                            // 状态指示器
                            Circle()
                                .fill(mapping.isEnabled ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                                .frame(width: 60)
                            
                            // 操作按钮
                            HStack(spacing: 8) {
                                Button(action: { onToggle(mapping) }) {
                                    Image(systemName: mapping.isEnabled ? "stop.circle" : "play.circle")
                                        .foregroundColor(mapping.isEnabled ? .red : .green)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { onDelete(mapping) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(width: 60)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        
                        Divider()
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// 辅助函数
private func formatPortDisplay(_ port: Int) -> String {
    String(port)
}
