import Foundation

enum SSHAuthType: String, Codable {
    case password
    case privateKey
}

struct SSHConfig: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var host: String
    var port: Int
    var username: String
    var authType: SSHAuthType
    var password: String?
    var privateKeyPath: String?
    
    var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty &&
        (authType == .password ? password != nil : privateKeyPath != nil)
    }
    
    static func == (lhs: SSHConfig, rhs: SSHConfig) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class SSHConfigManager: ObservableObject {
    @Published var configs: [SSHConfig] = []
    private let configFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/FCPort/ssh_configs.json")
    
    init() {
        loadConfigs()
    }
    
    private func loadConfigs() {
        do {
            if let data = try? Data(contentsOf: configFile) {
                configs = try JSONDecoder().decode([SSHConfig].self, from: data)
            }
        } catch {
            print("Failed to load SSH configs: \(error)")
        }
    }
    
    func saveConfigs() {
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
    
    func addConfig(_ config: SSHConfig) {
        configs.append(config)
        saveConfigs()
    }
    
    func updateConfig(_ config: SSHConfig) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
            saveConfigs()
        }
    }
    
    func deleteConfig(_ config: SSHConfig) {
        configs.removeAll { $0.id == config.id }
        saveConfigs()
    }
}
