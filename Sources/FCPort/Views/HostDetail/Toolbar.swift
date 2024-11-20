import SwiftUI

struct Toolbar: View {
    let host: SSHConfigModel
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // 主机信息
            VStack(alignment: .leading, spacing: 4) {
                Text(host.name)
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("\(host.user)@\(host.host):\(host.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("编辑主机")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("删除主机")
            }
        }
        .padding(.horizontal)
        .frame(height: 64)
    }
}
