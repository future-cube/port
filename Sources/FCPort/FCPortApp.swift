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
    var lastWindowFrame: NSRect?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        NSApp.windows.first?.close()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "FC"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(openSettings: openSettings))
        
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
            if !window.isVisible {
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
                lastWindowFrame = window.frame
                window.orderOut(nil)
            }
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender === settingsWindow {
            lastWindowFrame = sender.frame
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
