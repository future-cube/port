import Foundation

struct PortMapping: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var localPort: String
    var remotePort: String
    var isEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, localPort, remotePort, isEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        
        // 处理端口的兼容性
        if let localPortInt = try? container.decode(Int.self, forKey: .localPort) {
            localPort = String(localPortInt)
        } else {
            localPort = try container.decode(String.self, forKey: .localPort)
        }
        
        if let remotePortInt = try? container.decode(Int.self, forKey: .remotePort) {
            remotePort = String(remotePortInt)
        } else {
            remotePort = try container.decode(String.self, forKey: .remotePort)
        }
    }
    
    init(id: UUID = UUID(), name: String, localPort: String, remotePort: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.localPort = localPort
        self.remotePort = remotePort
        self.isEnabled = isEnabled
    }
}

enum SSHAuthType: String, Codable {
    case password
    case privateKey
}

struct SSHConfigModel: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var user: String
    var authType: SSHAuthType
    var password: String?
    var privateKey: String?
    var privateKeyPath: String?
    private(set) var rules: [PortMapping]
    
    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        user: String,
        authType: SSHAuthType = .password,
        password: String? = nil,
        privateKey: String? = nil,
        privateKeyPath: String? = nil,
        rules: [PortMapping] = []
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.user = user
        self.authType = authType
        self.password = password
        self.privateKey = privateKey
        self.privateKeyPath = privateKeyPath
        self.rules = rules
    }
    
    var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !user.isEmpty &&
        (authType == .password ? password != nil : privateKey != nil)
    }
    
    static func == (lhs: SSHConfigModel, rhs: SSHConfigModel) -> Bool {
        lhs.id == rhs.id && lhs.rules == rhs.rules
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(rules)
    }
    
    // MARK: - Rule Management
    
    mutating func addRule(_ rule: PortMapping) -> Self {
        rules.append(rule)
        return self
    }
    
    mutating func deleteRule(_ ruleId: UUID) -> Self {
        rules.removeAll { $0.id == ruleId }
        return self
    }
    
    mutating func updateRule(_ rule: PortMapping) -> Self {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        }
        return self
    }
    
    mutating func clearRules() -> Self {
        rules.removeAll()
        return self
    }
}

@MainActor
class SSHConfigManager: ObservableObject {
    static let shared = SSHConfigManager()
    @Published private(set) var configs: [SSHConfigModel] = []
    private let configFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/FCPort/ssh_configs.json")
    
    init() {
        Task {
            await loadConfigs()
        }
    }
    
    func loadConfigs() async {
        do {
            if let data = try? Data(contentsOf: configFile) {
                configs = try JSONDecoder().decode([SSHConfigModel].self, from: data)
            }
        } catch {
            print("Failed to load SSH configs: \(error)")
        }
    }
    
    private func saveConfigs() {
        do {
            try FileManager.default.createDirectory(
                at: configFile.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(configs)
            try data.write(to: configFile)
        } catch {
            print("Failed to save SSH configs: \(error)")
        }
    }
    
    func addConfig(_ config: SSHConfigModel) async {
        configs.append(config)
        saveConfigs()
    }
    
    func updateConfig(_ config: SSHConfigModel) async {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
            saveConfigs()
        }
    }
    
    func deleteConfig(_ config: SSHConfigModel) async {
        configs.removeAll { $0.id == config.id }
        saveConfigs()
    }
}
