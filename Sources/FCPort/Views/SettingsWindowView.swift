import SwiftUI

enum RightPanelContent {
    case empty
    case addHost
    case editHost(SSHConfig)
}

struct SettingsWindowView: View {
    @StateObject private var configManager = SSHConfigManager()
    @State private var selectedConfig: SSHConfig?
    @State private var rightPanelContent: RightPanelContent = .empty
    
    var body: some View {
        HSplitView {
            // 左侧面板
            VStack(spacing: 0) {
                HostListView(selectedConfig: $selectedConfig)
                    .environmentObject(configManager)
            }
            .frame(minWidth: 200, maxWidth: .infinity)
            
            // 右侧面板
            VStack(spacing: 0) {
                // 工具栏
                HStack {
                    if let selectedConfig = selectedConfig {
                        Button {
                            rightPanelContent = .editHost(selectedConfig)
                        } label: {
                            Label("Edit", systemImage: "pencil.circle.fill")
                                .help("Edit Host")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.accentColor)
                        
                        Button(role: .destructive) {
                            configManager.deleteConfig(selectedConfig)
                            self.selectedConfig = nil
                            rightPanelContent = .empty
                        } label: {
                            Label("Delete", systemImage: "trash.circle.fill")
                                .help("Delete Host")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Button {
                        rightPanelContent = .addHost
                    } label: {
                        Label("Add Host", systemImage: "plus.circle.fill")
                            .help("Add New Host")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // 内容区域
                Group {
                    switch rightPanelContent {
                    case .empty:
                        if let config = selectedConfig {
                            HostDetailView(config: config)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("Select a host or add a new one")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    case .addHost:
                        AddHostView(configManager: configManager) {
                            rightPanelContent = .empty
                        }
                    case .editHost(let config):
                        EditHostView(configManager: configManager, config: config) {
                            rightPanelContent = .empty
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 400, maxWidth: .infinity)
        }
    }
}

struct AddHostView: View {
    @ObservedObject var configManager: SSHConfigManager
    let onDone: () -> Void
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var authType: SSHAuthType = .password
    @State private var password = ""
    @State private var privateKeyPath = ""
    
    var body: some View {
        Form {
            Section("Host Information") {
                TextField("Name", text: $name)
                TextField("Host", text: $host)
                TextField("Port", text: $port)
                    .textFieldStyle(.roundedBorder)
                TextField("Username", text: $username)
            }
            
            Section("Authentication") {
                Picker("Authentication Type", selection: $authType) {
                    Text("Password").tag(SSHAuthType.password)
                    Text("Private Key").tag(SSHAuthType.privateKey)
                }
                
                if authType == .password {
                    SecureField("Password", text: $password)
                } else {
                    TextField("Private Key Path", text: $privateKeyPath)
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    onDone()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Add") {
                    let config = SSHConfig(
                        name: name,
                        host: host,
                        port: Int(port) ?? 22,
                        username: username,
                        authType: authType,
                        password: authType == .password ? password : nil,
                        privateKeyPath: authType == .privateKey ? privateKeyPath : nil
                    )
                    configManager.addConfig(config)
                    onDone()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!isValid)
            }
        }
        .padding()
    }
    
    private var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty &&
        (Int(port) ?? 0) > 0 &&
        (authType == .password ? !password.isEmpty : !privateKeyPath.isEmpty)
    }
}

struct EditHostView: View {
    @ObservedObject var configManager: SSHConfigManager
    let config: SSHConfig
    let onDone: () -> Void
    
    @State private var name: String
    @State private var host: String
    @State private var port: String
    @State private var username: String
    @State private var authType: SSHAuthType
    @State private var password: String
    @State private var privateKeyPath: String
    
    init(configManager: SSHConfigManager, config: SSHConfig, onDone: @escaping () -> Void) {
        self.configManager = configManager
        self.config = config
        self.onDone = onDone
        
        _name = State(initialValue: config.name)
        _host = State(initialValue: config.host)
        _port = State(initialValue: String(config.port))
        _username = State(initialValue: config.username)
        _authType = State(initialValue: config.authType)
        _password = State(initialValue: config.password ?? "")
        _privateKeyPath = State(initialValue: config.privateKeyPath ?? "")
    }
    
    var body: some View {
        Form {
            Section("Host Information") {
                TextField("Name", text: $name)
                TextField("Host", text: $host)
                TextField("Port", text: $port)
                TextField("Username", text: $username)
            }
            
            Section("Authentication") {
                Picker("Authentication Type", selection: $authType) {
                    Text("Password").tag(SSHAuthType.password)
                    Text("Private Key").tag(SSHAuthType.privateKey)
                }
                
                if authType == .password {
                    SecureField("Password", text: $password)
                } else {
                    TextField("Private Key Path", text: $privateKeyPath)
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    onDone()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Save") {
                    var updatedConfig = config
                    updatedConfig.name = name
                    updatedConfig.host = host
                    updatedConfig.port = Int(port) ?? 22
                    updatedConfig.username = username
                    updatedConfig.authType = authType
                    updatedConfig.password = authType == .password ? password : nil
                    updatedConfig.privateKeyPath = authType == .privateKey ? privateKeyPath : nil
                    
                    configManager.updateConfig(updatedConfig)
                    onDone()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!isValid)
            }
        }
        .padding()
    }
    
    private var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty &&
        (Int(port) ?? 0) > 0 &&
        (authType == .password ? !password.isEmpty : !privateKeyPath.isEmpty)
    }
}

struct HostListView: View {
    @Binding var selectedConfig: SSHConfig?
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        List(selection: $selectedConfig) {
            ForEach(configManager.configs) { config in
                Text("\(config.username)@\(config.host):\(config.port)")
                    .tag(config)
            }
        }
    }
}

struct HostDetailView: View {
    let config: SSHConfig
    
    var body: some View {
        Form {
            Section("Host Information") {
                HStack {
                    Text("Name").foregroundColor(.secondary)
                    Spacer()
                    Text(config.name)
                }
                HStack {
                    Text("Host").foregroundColor(.secondary)
                    Spacer()
                    Text(config.host)
                }
                HStack {
                    Text("Port").foregroundColor(.secondary)
                    Spacer()
                    Text(String(config.port))
                }
                HStack {
                    Text("Username").foregroundColor(.secondary)
                    Spacer()
                    Text(config.username)
                }
                HStack {
                    Text("Auth Type").foregroundColor(.secondary)
                    Spacer()
                    Text(config.authType.rawValue.capitalized)
                }
                if config.authType == .privateKey {
                    HStack {
                        Text("Key File").foregroundColor(.secondary)
                        Spacer()
                        Text(config.privateKeyPath ?? "")
                    }
                }
            }
        }
        .padding()
    }
}
