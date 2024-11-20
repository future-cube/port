import SwiftUI
import AppKit

@main
struct FCPortApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var settingsWindow: NSWindow?
    var lastWindowFrame: NSRect?  // 记住窗口最后的位置
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置为代理应用
        NSApp.setActivationPolicy(.accessory)
        
        // 如果有默认窗口，关闭它
        NSApp.windows.first?.close()
        
        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "FC"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // 创建弹出窗口
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(openSettings: openSettings))
        
        // 注册退出菜单
        if let button = statusItem.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                let menu = NSMenu()
                menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
                statusItem.menu = menu
                statusItem.button?.performClick(nil)
                statusItem.menu = nil
                return
            }
        }
        
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc func openSettings() {
        if let window = settingsWindow {
            // 如果窗口存在但被隐藏，则显示它
            if !window.isVisible {
                // 如果有保存的位置，使用保存的位置
                if let lastFrame = lastWindowFrame {
                    window.setFrame(lastFrame, display: true)
                } else {
                    window.center()
                }
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建新窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.delegate = self
        window.contentView = NSHostingView(rootView: SettingsWindowView())
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        settingsWindow = window
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window === settingsWindow {
                // 保存窗口位置
                lastWindowFrame = window.frame
                // 隐藏窗口
                window.orderOut(nil)
            }
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender === settingsWindow {
            // 保存窗口位置
            lastWindowFrame = sender.frame
            // 隐藏窗口而不是关闭
            sender.orderOut(nil)
            return false
        }
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
