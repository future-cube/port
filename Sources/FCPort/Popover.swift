import SwiftUI
import AppKit

class Popover: NSPopover {
    init(contentSize: NSSize = NSSize(width: 800, height: 600)) {
        super.init()
        
        self.contentSize = contentSize
        self.behavior = .transient
        self.animates = true
        
        let contentView = Layout()
        self.contentViewController = NSHostingController(rootView: contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(relativeTo: NSRect, of view: NSView) {
        if !isShown {
            show(relativeTo: relativeTo, of: view, preferredEdge: .minY)
        }
    }
}
