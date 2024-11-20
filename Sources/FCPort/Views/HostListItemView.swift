import SwiftUI

struct HostListItemView: View {
    let config: SSHConfig
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: ViewConstants.standardPadding) {
            // 连接状态指示器
            StatusIndicatorView(status: .normal, size: ViewConstants.smallIconSize)
            
            // 主机信息
            VStack(alignment: .leading, spacing: ViewConstants.tinyPadding) {
                // 主机名
                Text(config.name)
                    .font(.system(size: ViewConstants.titleFontSize, weight: .medium))
                    .foregroundColor(.primary)
                
                // 连接信息
                Text("\(config.username)@\(config.host):\(config.port)")
                    .font(.system(size: ViewConstants.subtitleFontSize))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, ViewConstants.standardPadding)
        .frame(height: ViewConstants.hostItemHeight)
        .background(
            RoundedRectangle(cornerRadius: ViewConstants.smallCornerRadius)
                .fill(isSelected ? ViewConstants.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct HostListHeaderView: View {
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text("Hosts")
                .font(.system(size: ViewConstants.titleFontSize, weight: .bold))
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: ViewConstants.mediumIconSize))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(ViewConstants.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ViewConstants.standardPadding)
        .frame(height: ViewConstants.toolbarHeight)
        .background(ViewConstants.backgroundColor)
    }
}

struct HostListFooterView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "power.circle.fill")
                    .font(.system(size: ViewConstants.smallIconSize))
                Text("Quit")
                    .font(.system(size: ViewConstants.labelFontSize))
            }
            .foregroundColor(ViewConstants.destructiveColor)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .frame(height: ViewConstants.bottomBarHeight)
        .background(ViewConstants.backgroundColor)
    }
}
