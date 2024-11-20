import SwiftUI
import AppKit

@main
struct FCPortApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "ferry", accessibilityDescription: "FCPort")
            statusButton.action = #selector(togglePopover)
            statusButton.target = self
        }
        
        // 创建弹出窗口
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        self.popover = popover
    }
    
    @objc func togglePopover() {
        guard let statusBarButton = statusItem?.button else { return }
        
        if let popover = self.popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .minY)
                // 让 popover 获得焦点
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to FCPort!")
                .font(.title)
                .padding()
            Text("This is a status bar application")
                .padding()
        }
        .frame(width: 400, height: 300)
    }
}
