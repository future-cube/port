import SwiftUI
import AppKit

@main
struct App: SwiftUI.App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let sshService = SSHService.shared
    private let configManager = SSHConfigManager.shared
    private var statusItem: NSStatusItem!
    private var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 应用启动时，启动所有已启用的转发规则
        Task {
            do {
                try await sshService.startAllServices(configs: configManager.configs)
            } catch {
                print("启动服务失败: \(error.localizedDescription)")
            }
        }
        
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
    
    func applicationWillTerminate(_ notification: Notification) {
        // 应用退出时，终止所有转发
        Task {
            do {
                try await sshService.stopAllCommands()
            } catch {
                print("停止服务失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if let image = Bundle.main.image(forResource: "StatusBarIcon") {
                image.size = NSSize(width: 18, height: 18)  // 调整图标大小为状态栏合适的尺寸
                image.isTemplate = true  // 使图标适应深色/浅色模式
                button.image = image
            } else {
                // 如果找不到自定义图标，使用系统图标作为后备
                button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "FC Port")
            }
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
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
