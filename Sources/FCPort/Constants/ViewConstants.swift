import SwiftUI

enum ViewConstants {
    static let defaultPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let cornerRadius: CGFloat = 8
    static let minSidebarWidth: CGFloat = 250
    static let defaultFormWidth: CGFloat = 300
    static let statusIndicatorSize: CGFloat = 8
    
    static let colors = Colors()
    static let fonts = Fonts()
}

extension ViewConstants {
    struct Colors {
        let accent = Color.accentColor
        let background = Color(NSColor.controlBackgroundColor)
        let separator = Color(NSColor.separatorColor)
        let text = Color(NSColor.labelColor)
        let secondaryText = Color(NSColor.secondaryLabelColor)
        
        let success = Color.green
        let error = Color.red
        
        let selection = Color.accentColor.opacity(0.1)
    }
    
    struct Fonts {
        let title = Font.title
        let headline = Font.headline
        let subheadline = Font.subheadline
        let body = Font.body
        let caption = Font.caption
    }
}
