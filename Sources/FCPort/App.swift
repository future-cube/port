import SwiftUI
import AppKit

@main
struct App: SwiftUI.App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Layout()
        }
        .windowStyle(.hiddenTitleBar)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupWindow()
        
        // 注册窗口关闭事件通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowClosing),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "FC Port")
            button.action = #selector(toggleWindow)
            button.target = self
        }
    }
    
    private func setupWindow() {
        // 创建主窗口
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "FC Port"
        window.contentView = NSHostingView(rootView: Layout())
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        // 确保窗口初始时是隐藏的
        window.orderOut(nil)
    }
    
    @objc private func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func handleWindowClosing(notification: Notification) {
        if let windowToClose = notification.object as? NSWindow {
            // 阻止窗口关闭，改为隐藏
            windowToClose.orderOut(nil)
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 阻止窗口关闭，改为隐藏
        window.orderOut(nil)
        return false
    }
}
