import SwiftUI

enum ViewConstants {
    // Window sizes
    static let minWindowWidth: CGFloat = 840
    static let minWindowHeight: CGFloat = 600
    static let hostListWidth: CGFloat = 260
    static let detailPanelMinWidth: CGFloat = 600
    
    // Spacing and padding
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let tinyPadding: CGFloat = 4
    
    // Font sizes
    static let titleFontSize: CGFloat = 15
    static let subtitleFontSize: CGFloat = 13
    static let labelFontSize: CGFloat = 12
    static let contentFontSize: CGFloat = 14
    
    // Colors
    static let accentColor = Color.blue
    static let destructiveColor = Color.red
    static let borderColor = Color(NSColor.separatorColor)
    static let backgroundColor = Color(NSColor.windowBackgroundColor)
    static let secondaryBackgroundColor = Color(NSColor.controlBackgroundColor)
    
    // Icon sizes
    static let largeIconSize: CGFloat = 48
    static let mediumIconSize: CGFloat = 24
    static let smallIconSize: CGFloat = 16
    
    // Custom styles
    static let toolbarHeight: CGFloat = 60
    static let hostItemHeight: CGFloat = 60
    static let bottomBarHeight: CGFloat = 44
    
    // Corner radius
    static let standardCornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 4
}

struct ModernButtonStyle: ButtonStyle {
    let color: Color
    let isDestructive: Bool
    
    init(color: Color = ViewConstants.accentColor, isDestructive: Bool = false) {
        self.color = color
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDestructive ? ViewConstants.destructiveColor : color)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ModernToolbarButton: View {
    let systemImage: String
    let title: String
    let action: () -> Void
    let color: Color
    let isDestructive: Bool
    
    init(systemImage: String, title: String, color: Color = ViewConstants.accentColor, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.title = title
        self.color = color
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ViewConstants.tinyPadding) {
                Image(systemName: systemImage)
                    .font(.system(size: ViewConstants.mediumIconSize))
                Text(title)
                    .font(.system(size: ViewConstants.labelFontSize))
            }
            .frame(width: ViewConstants.toolbarHeight)
        }
        .buttonStyle(ModernButtonStyle(color: color, isDestructive: isDestructive))
    }
}
