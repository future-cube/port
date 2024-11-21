import SwiftUI
import Foundation

struct Rules: View {
    @EnvironmentObject private var configManager: SSHConfigManager
    @EnvironmentObject private var sshService: SSHService
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var isLoading: Bool = false
    @State private var refreshTimer: Timer?
    @State private var countdown: Int = 10
    @State private var isRefreshing: Bool = false
    @State private var status: GlobalStatus = .stopped
    @State private var ruleStates: [UUID: Bool] = [:]
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("端口转发规则")
                    .font(.headline)
                Spacer()
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                }
                Text("\(countdown)s")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(width: 30)
                
                HStack(spacing: 8) {
                    Label(status.text, systemImage: status.icon)
                        .foregroundColor(status.color)
                    
                    switch status {
                    case .stopped:
                        Button("启动") {
                            startAll()
                        }
                        .foregroundColor(.green)
                        .disabled(isLoading)
                    case .running:
                        Button("停止") {
                            stopAll()
                        }
                        .foregroundColor(.red)
                        .disabled(isLoading)
                    case .partial:
                        Button("重启") {
                            restartAll()
                        }
                        .disabled(isLoading)
                        .foregroundColor(.blue)
                    }
                }
                
                Button("关闭") {
                    dismiss()
                }
                .foregroundColor(.red)
                .disabled(isLoading)
            }
            .frame(maxWidth: .infinity)
            .padding()
            
            List {
                ForEach(configManager.configs) { host in
                    Section(header: Text(host.name)) {
                        ForEach(host.rules) { rule in
                            RuleRow(host: host, rule: rule, isRunning: ruleStates[rule.id] ?? false)
                                .disabled(isLoading)
                        }
                    }
                }
            }
            .refreshable {
                await refreshStatus()
            }
        }
        .frame(width: 600, height: 400)
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            refresh()
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
        .task {
            await updateStatus()
        }
    }
    
    private func startRefreshTimer() {
        countdown = 10
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countdown -= 1
            if countdown <= 0 {
                countdown = 10
                refresh()
            }
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refresh() {
        guard !isRefreshing && !isLoading else { return }
        
        Task {
            isRefreshing = true
            await updateStatus()
            isRefreshing = false
        }
    }
    
    private func updateStatus() async {
        await refreshRuleStates()
    }
    
    private func refreshStatus() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        await refreshRuleStates()
    }
    
    private func refreshRuleStates() async {
        do {
            // 获取所有规则的状态
            var newStates: [UUID: Bool] = [:]
            for host in configManager.configs {
                for rule in host.rules {
                    let isRunning = try await sshService.isServiceRunning(ruleId: rule.id)
                    newStates[rule.id] = isRunning
                }
            }
            ruleStates = newStates
            
            // 更新全局状态
            let runningCount = newStates.values.filter { $0 }.count
            let totalCount = newStates.count
            
            if runningCount == 0 {
                status = .stopped
            } else if runningCount == totalCount {
                status = .running
            } else {
                status = .partial
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func startAll() {
        guard !isLoading else { return }
        
        Task {
            isRefreshing = true
            do {
                for host in configManager.configs {
                    for rule in host.rules where rule.isEnabled {
                        try await sshService.startService(host: host, rule: rule)
                    }
                }
                await refreshRuleStates()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isRefreshing = false
        }
    }
    
    private func stopAll() {
        guard !isLoading else { return }
        
        Task {
            isRefreshing = true
            do {
                try await sshService.stopAllCommands()
                await refreshRuleStates()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isRefreshing = false
        }
    }
    
    private func restartAll() {
        guard !isLoading else { return }
        
        Task {
            isRefreshing = true
            do {
                try await sshService.stopAllCommands()
                for host in configManager.configs {
                    for rule in host.rules where rule.isEnabled {
                        try await sshService.startService(host: host, rule: rule)
                    }
                }
                await refreshRuleStates()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isRefreshing = false
        }
    }
}

struct RuleRow: View {
    let host: SSHConfigModel
    let rule: PortMapping
    let isRunning: Bool
    @EnvironmentObject private var sshService: SSHService
    @State private var showDetail = false
    @State private var isHovered = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var isLoading: Bool = false
    @State private var showCopied = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(rule.localPort) → \(rule.remotePort)")
                        .font(.system(.body, design: .monospaced))
                    Image(systemName: isRunning ? "circle.fill" : "circle")
                        .foregroundColor(isRunning ? .green : .red)
                        .font(.caption)
                }
                
                if rule.isEnabled {
                    Text("\(host.user)@\(host.host):\(host.port)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if rule.isEnabled {
                HStack(spacing: 12) {
                    // 复制命令按钮
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(sshCommand, forType: .string)
                        
                        // 显示复制成功提示
                        withAnimation {
                            showCopied = true
                        }
                        
                        // 2秒后隐藏提示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopied = false
                            }
                        }
                    }) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(showCopied ? .green : .blue)
                    }
                    .help("复制 SSH 命令")
                    
                    Button(action: {
                        showDetail.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                    .popover(isPresented: $showDetail) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("转发详情")
                                .font(.headline)
                            Text("本地端口: \(rule.localPort)")
                            Text("远程主机: \(host.host)")
                            Text("远程端口: \(rule.remotePort)")
                            Text("状态: \(isRunning ? "运行中" : "已停止")")
                            Divider()
                            Text("SSH 命令:")
                                .font(.headline)
                            Text(sshCommand)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .padding()
                        .frame(width: 500)
                    }
                    
                    if isRunning {
                        Button(action: {
                            stopSSH()
                        }) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .disabled(isLoading)
                    } else {
                        Button(action: {
                            startSSH()
                        }) {
                            Image(systemName: "play.fill")
                                .foregroundColor(.green)
                        }
                        .disabled(isLoading)
                    }
                }
            }
        }
        .opacity(rule.isEnabled ? 1 : 0.5)
        .onHover { hovering in
            isHovered = hovering
        }
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            // await updateRunningStatus()
        }
        .onAppear {
            // startRefreshTimer()
        }
        .onDisappear {
            // stopRefreshTimer()
        }
    }
    
    private var sshCommand: String {
        var command = ["ssh", "-N", "-L", "\(rule.localPort):\(host.host):\(rule.remotePort)"]
        command.append("-p")
        command.append("\(host.port)")
        
        if host.authType == .privateKey, let privateKeyPath = host.privateKeyPath {
            command.append("-i")
            command.append(privateKeyPath)
        }
        
        command.append("-o")
        command.append("SendEnv=FCPORT_\(rule.id.uuidString.replacingOccurrences(of: "-", with: "_"))")
        
        command.append("\(host.user)@\(host.host)")
        
        return command.joined(separator: " ")
    }
    
    // private func updateRunningStatus() async {
    //     isRunning = await sshService.isCommandRunning(ruleId: rule.id)
    // }
    
    private func startSSH() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                try await sshService.startService(host: host, rule: rule)
                // await updateRunningStatus()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    
    private func stopSSH() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                try await sshService.stopCommand(forId: rule.id)
                // await updateRunningStatus()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
