import Foundation
import Combine
import SwiftUI

enum PortServiceError: LocalizedError {
    case commandFailed(String)
    case processNotFound
    case invalidPort
    case sshProcessError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return "命令执行失败: \(message)"
        case .processNotFound:
            return "找不到对应的 SSH 进程"
        case .invalidPort:
            return "无效的端口号"
        case .sshProcessError(let message):
            return "SSH 进程错误: \(message)"
        case .unknownError:
            return "未知错误"
        }
    }
}

@MainActor
class PortService: ObservableObject {
    static let shared = PortService()
    
    @Published private var runningCommands: [UUID: Process] = [:]
    @Published private var isCheckingProcesses: Bool = false
    private var updateTimer: Timer?
    private var lastCheckTime: Date = .distantPast
    
    private init() {
        print("[PortService] Initializing...")
        setupTimer()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    private func setupTimer() {
        print("[PortService] Setting up timer...")
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 确保检查间隔至少5秒
            let now = Date()
            guard now.timeIntervalSince(self.lastCheckTime) >= 5.0 else {
                print("[PortService] Skipping check - too soon")
                return
            }
            
            print("[PortService] Timer triggered process check")
            Task { @MainActor in
                do {
                    try await self.checkProcesses()
                } catch {
                    print("[PortService] Error checking processes: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Process Management
    
    func startSSH(host: SSHConfigModel, rule: PortMapping) async throws {
        guard rule.isEnabled else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        
        var arguments = ["-N", "-L", "\(rule.localPort):\(host.host):\(rule.remotePort)"]
        arguments.append("-p")
        arguments.append("\(host.port)")
        
        if host.authType == .privateKey {
            if let privateKeyPath = host.privateKeyPath {
                arguments.append("-i")
                arguments.append(privateKeyPath)
            }
        }
        
        arguments.append("-o")
        arguments.append("SendEnv=FCPORT_\(rule.id.uuidString.replacingOccurrences(of: "-", with: "_"))")
        
        arguments.append("\(host.user)@\(host.host)")
        
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardError = pipe
        
        do {
            try process.run()
            runningCommands[rule.id] = process
        } catch {
            throw PortServiceError.sshProcessError(error.localizedDescription)
        }
    }
    
    func stopSSH(ruleId: UUID) async throws {
        guard let process = runningCommands[ruleId] else {
            throw PortServiceError.processNotFound
        }
        
        process.terminate()
        runningCommands.removeValue(forKey: ruleId)
    }
    
    func startAllSSH(configs: [SSHConfigModel]) async throws {
        for config in configs {
            for rule in config.rules where rule.isEnabled {
                try await startSSH(host: config, rule: rule)
            }
        }
    }
    
    func stopAllSSH() async throws {
        for (ruleId, _) in runningCommands {
            try await stopSSH(ruleId: ruleId)
        }
    }
    
    func restartAllSSH(configs: [SSHConfigModel]) async throws {
        try await stopAllSSH()
        try await startAllSSH(configs: configs)
    }
    
    // MARK: - Process Status
    
    func isCommandRunning(ruleId: UUID) -> Bool {
        guard let process = runningCommands[ruleId] else { return false }
        return process.isRunning
    }
    
    func checkProcesses() async throws {
        // 避免重复检查
        guard !isCheckingProcesses else {
            print("[PortService] Process check already in progress")
            return
        }
        
        isCheckingProcesses = true
        lastCheckTime = Date()
        
        defer {
            isCheckingProcesses = false
        }
        
        do {
            let runningProcesses = try await getRunningSSHProcesses()
            
            // 创建一个临时数组来存储需要移除的进程ID
            var processesToRemove: [UUID] = []
            
            for (ruleId, process) in runningCommands {
                let processIdentifier = "FCPORT_\(ruleId.uuidString.replacingOccurrences(of: "-", with: "_"))"
                if !process.isRunning || !runningProcesses.contains(where: { $0.contains(processIdentifier) }) {
                    process.terminate()
                    processesToRemove.append(ruleId)
                }
            }
            
            // 批量移除进程
            for ruleId in processesToRemove {
                runningCommands.removeValue(forKey: ruleId)
            }
            
            // 触发UI更新
            objectWillChange.send()
            
        } catch {
            print("[PortService] Error during process check: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Utilities
    
    func getCommand(for rule: PortMapping, in host: SSHConfigModel) -> String {
        var command = "ssh -N -L \(rule.localPort):\(host.host):\(rule.remotePort)"
        command += " -p \(host.port)"
        
        if host.authType == .privateKey {
            if let privateKeyPath = host.privateKeyPath {
                command += " -i \(privateKeyPath)"
            }
        }
        
        command += " -o SendEnv=FCPORT_\(rule.id.uuidString.replacingOccurrences(of: "-", with: "_"))"
        command += " \(host.user)@\(host.host)"
        
        return command
    }
    
    private func getRunningSSHProcesses() async throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-ax", "-o", "command"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return output.components(separatedBy: .newlines)
                .filter { $0.contains("ssh") && $0.contains("FCPORT_") }
        } catch {
            throw PortServiceError.commandFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Global Status
    
    func getGlobalStatus(from configs: [SSHConfigModel]) -> GlobalStatus {
        let enabledRules = configs.flatMap { $0.rules.filter { $0.isEnabled } }
        guard !enabledRules.isEmpty else { return .stopped }
        
        let runningCount = enabledRules.filter { isCommandRunning(ruleId: $0.id) }.count
        
        if runningCount == 0 {
            return .stopped
        } else if runningCount == enabledRules.count {
            return .running
        } else {
            return .partial
        }
    }
}
