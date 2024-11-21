import Foundation

enum SSHServiceError: LocalizedError {
    case commandNotFound
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .commandNotFound:
            return "找不到对应的 SSH 命令"
        case .operationFailed(let message):
            return "操作失败: \(message)"
        }
    }
}

// MARK: - SSHService
@MainActor
class SSHService: ObservableObject {
    static let shared = SSHService()
    
    @Published private(set) var runningCommands: [UUID: Process] = [:]
    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var ruleStatuses: [UUID: Bool] = [:]
    
    private init() {}
    
    // MARK: - 命令管理
    
    /// 获取进程标识符
    private func getProcessIdentifier(for id: UUID) -> String {
        "FCPORT_\(id.uuidString.replacingOccurrences(of: "-", with: "_"))"
    }
    
    /// 获取指定标识符的进程 PID
    private func getPid(forIdentifier identifier: String) async throws -> String? {
        try await withTimeout(seconds: 3) {
            let process = Process()
            let pipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", "ps -ax | grep /usr/bin/ssh | grep '\(identifier)' | grep -v grep"]
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            
            let handle = pipe.fileHandleForReading
            let data = handle.readDataToEndOfFile()
            process.waitUntilExit()
            
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.components(separatedBy: CharacterSet.whitespaces)
                .first { !$0.isEmpty }
        }
    }
    
    /// 获取所有当前应用程序启动的 SSH 命令的 PID
    private func getAllPids() async throws -> [String] {
        try await withTimeout(seconds: 3) {
            let process = Process()
            let pipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", "ps -ax | grep /usr/bin/ssh | grep 'SendEnv=FCPORT_' | grep -v grep"]
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            
            let handle = pipe.fileHandleForReading
            let data = handle.readDataToEndOfFile()
            process.waitUntilExit()
            
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .compactMap { line in
                    line.components(separatedBy: CharacterSet.whitespaces)
                        .first { !$0.isEmpty }
                }
        }
    }
    
    /// 获取指定 ID 的 SSH 命令
    func getCommand(forId id: UUID) async throws -> String? {
        let identifier = getProcessIdentifier(for: id)
        guard let pid = try await getPid(forIdentifier: identifier) else {
            return nil
        }
        
        // 只对匹配的 PID 获取完整命令行
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", pid, "-o", "command="]
        process.standardOutput = pipe
        
        try process.run()
        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        process.waitUntilExit()
        
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.isEmpty ? nil : output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 获取所有当前应用程序启动的 SSH 命令
    private func getAllCommands() async throws -> [String] {
        try await withTimeout(seconds: 3) {
            let process = Process()
            let pipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", "ps -ax | grep /usr/bin/ssh | grep 'SendEnv=FCPORT_' | grep -v grep"]
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            
            let handle = pipe.fileHandleForReading
            let data = handle.readDataToEndOfFile()
            process.waitUntilExit()
            
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
        }
    }
    
    /// 结束所有当前应用程序启动的 SSH 命令
    func stopAllCommands() async throws {
        let commands = try await getAllCommands()
        for command in commands {
            if let idStr = command.components(separatedBy: " ").last?.replacingOccurrences(of: "FCPORT_", with: ""),
               let id = UUID(uuidString: idStr) {
                try await stopCommand(forId: id)
                // 等待进程完全停止
                for _ in 0..<10 {
                    if !(try await isServiceRunning(ruleId: id)) {
                        break
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
    }
    
    /// 结束指定 ID 的 SSH 命令
    func stopCommand(forId id: UUID) async throws {
        guard let pid = try await getPid(forIdentifier: getProcessIdentifier(for: id)),
              !pid.isEmpty else { return }
        
        let killProcess = Process()
        killProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
        killProcess.arguments = [pid]
        try killProcess.run()
        killProcess.waitUntilExit()
        
        // 如果进程仍在运行，使用 kill -9
        if try await isServiceRunning(ruleId: id) {
            let forceKillProcess = Process()
            forceKillProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
            forceKillProcess.arguments = ["-9", pid]
            try forceKillProcess.run()
            forceKillProcess.waitUntilExit()
        }
        
        // 从运行列表中移除
        runningCommands.removeValue(forKey: id)
    }
    
    /// 启动所有服务
    func startAllServices(configs: [SSHConfigModel]) async throws {
        // 先停止所有现有命令
        try await stopAllCommands()
        
        // 启动所有启用的规则
        for config in configs {
            for rule in config.rules where rule.isEnabled {
                try await startService(host: config, rule: rule)
            }
        }
    }
    
    /// 启动指定 ID 的服务
    func startService(host: SSHConfigModel, rule: PortMapping) async throws {
        // 先停止指定 ID 的命令
        try await stopCommand(forId: rule.id)
        
        // 解析端口范围
        let localPorts = parsePortRange(rule.localPort)
        let remotePorts = parsePortRange(rule.remotePort)
        
        // 确保本地端口和远程端口数量一致
        guard localPorts.count == remotePorts.count else {
            throw SSHServiceError.operationFailed("本地端口和远程端口数量不匹配")
        }
        
        // 为每个端口对创建一个 SSH 进程
        for (localPort, remotePort) in zip(localPorts, remotePorts) {
            // 创建新进程
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            
            var arguments = ["-N", "-L", "\(localPort):\(host.host):\(remotePort)"]
            
            arguments.append("-p")
            arguments.append("\(host.port)")
            
            if host.authType == .privateKey {
                if let privateKeyPath = host.privateKeyPath {
                    arguments.append("-i")
                    arguments.append(privateKeyPath)
                }
            }
            
            arguments.append("-o")
            arguments.append("SendEnv=\(getProcessIdentifier(for: rule.id))")
            
            arguments.append("\(host.user)@\(host.host)")
            
            process.arguments = arguments
            
            // 使用 /dev/null 作为标准输入和输出，让进程在后台运行
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            
            // 设置为后台运行
            process.qualityOfService = .background
            
            try process.run()
            runningCommands[rule.id] = process
        }
    }
    
    /// 解析端口范围字符串，返回所有端口号
    private func parsePortRange(_ portString: String) -> [Int] {
        // 移除所有空格
        let cleanString = portString.replacingOccurrences(of: " ", with: "")
        
        // 如果包含逗号，分别处理每个部分
        if cleanString.contains(",") {
            return cleanString.split(separator: ",")
                .flatMap { parsePortRange(String($0)) }
        }
        
        // 处理范围 (例如: "80-82")
        if cleanString.contains("-") {
            let parts = cleanString.split(separator: "-")
            if parts.count == 2,
               let start = Int(parts[0]),
               let end = Int(parts[1]),
               start <= end {
                return Array(start...end)
            }
        }
        
        // 处理单个端口
        if let port = Int(cleanString) {
            return [port]
        }
        
        return []
    }
    
    // MARK: - 状态检查
    
    /// 检查指定 ID 的 SSH 命令是否正在运行
    func isServiceRunning(ruleId: UUID) async throws -> Bool {
        guard let pid = try await getPid(forIdentifier: getProcessIdentifier(for: ruleId)) else {
            return false
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", pid]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        return process.terminationStatus == 0
    }
    
    /// 检查所有命令的运行状态
    func checkGlobalStatus(configs: [SSHConfigModel]) async -> GlobalStatus {
        let enabledRules = configs.flatMap { $0.rules.filter { $0.isEnabled } }
        guard !enabledRules.isEmpty else { return .stopped }
        
        // 获取所有运行中的命令
        let runningCommands = (try? await getAllCommands()) ?? []
        let runningCount = enabledRules.filter { rule in
            runningCommands.contains { $0.contains(getProcessIdentifier(for: rule.id)) }
        }.count
        
        if runningCount == 0 {
            return .stopped
        } else if runningCount == enabledRules.count {
            return .running
        } else {
            return .partial
        }
    }
    
    /// 刷新所有命令状态
    func refreshStatus() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        // 获取所有运行中的命令
        let runningCommands = (try? await getAllCommands()) ?? []
        
        // 清理已经不存在的进程
        for (id, _) in self.runningCommands {
            let identifier = getProcessIdentifier(for: id)
            if !runningCommands.contains(where: { $0.contains(identifier) }) {
                self.runningCommands.removeValue(forKey: id)
                self.ruleStatuses[id] = false
            }
        }
        
        // 更新规则状态
        for command in runningCommands {
            if let idStr = command.components(separatedBy: " ").last?.replacingOccurrences(of: "FCPORT_", with: ""),
               let id = UUID(uuidString: idStr) {
                self.ruleStatuses[id] = true
            }
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw SSHServiceError.operationFailed("操作超时")
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
