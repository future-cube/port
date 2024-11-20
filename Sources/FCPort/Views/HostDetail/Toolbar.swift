import SwiftUI

struct Toolbar: View {
    let host: SSHConfigModel
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // 左侧主机名和信息
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(host.name)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("\(host.user)@\(host.host):\(host.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右侧操作按钮
            HStack(spacing: 16) {
                VStack(spacing: 1) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .help("编辑主机")
                    
                    Text("编辑")
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                }
                .frame(height: 38)
                
                VStack(spacing: 1) {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .help("删除主机")
                    
                    Text("删除")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                .frame(height: 38)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(height: 64)
        .background(Color(NSColor.windowBackgroundColor))
        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 2)
    }
}
