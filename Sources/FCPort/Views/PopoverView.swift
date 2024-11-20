import SwiftUI

struct PopoverView: View {
    let openSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 状态指示器
            StatusIndicatorView(status: .partial, size: 16)
                .padding(.top, 8)
            
            Divider()
            
            // 按钮区域
            HStack(spacing: 20) {
                Button {
                    openSettings()
                } label: {
                    VStack {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                        Text("Settings")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 50)
                }
                .buttonStyle(BorderlessButtonStyle())
                .contentShape(Rectangle())
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    VStack {
                        Image(systemName: "power")
                            .font(.system(size: 20))
                        Text("Quit")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 50)
                }
                .buttonStyle(BorderlessButtonStyle())
                .contentShape(Rectangle())
            }
            .padding(.bottom, 8)
        }
        .frame(width: 200)
    }
}

// 用于访问 NSWindow 的辅助视图
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        callback(nsView.window)
    }
}
