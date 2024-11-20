import Foundation

enum SSHAuthType: String, Codable {
    case password
    case privateKey
}

struct SSHConfigModel: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let host: String
    let port: Int
    let username: String
    let authType: SSHAuthType
    let password: String?
    let privateKeyPath: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authType: SSHAuthType = .password,
        password: String? = nil,
        privateKeyPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authType = authType
        self.password = password
        self.privateKeyPath = privateKeyPath
    }
    
    var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty &&
        (authType == .password ? password != nil : privateKeyPath != nil)
    }
    
    static func == (lhs: SSHConfigModel, rhs: SSHConfigModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
class SSHConfigManager: ObservableObject {
    @Published var configs: [SSHConfigModel] = []
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
