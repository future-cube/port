import SwiftUI

struct HostEdit: View {
    @Environment(\.dismiss) var dismiss
    var host: SSHConfigModel?
    let onAdd: (SSHConfigModel) -> Void
    
    @State private var name: String
    @State private var hostname: String
    @State private var port: String
    @State private var username: String
    @State private var authType: SSHAuthType
    @State private var password: String
    @State private var privateKeyPath: String
    
    init(host: SSHConfigModel? = nil, onAdd: @escaping (SSHConfigModel) -> Void) {
        self.host = host
        self.onAdd = onAdd
        _name = State(initialValue: host?.name ?? "")
        _hostname = State(initialValue: host?.host ?? "")
        _port = State(initialValue: String(host?.port ?? 22))
        _username = State(initialValue: host?.username ?? "")
        _authType = State(initialValue: host?.authType ?? .password)
        _password = State(initialValue: host?.password ?? "")
        _privateKeyPath = State(initialValue: host?.privateKeyPath ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("名称", text: $name)
                    TextField("主机地址", text: $hostname)
                    TextField("端口", text: $port)
                        .onChange(of: port) { newValue in
                            let filtered = newValue.filter { $0.isNumber }.prefix(5)
                            port = String(filtered)
                        }
                }
                
                Section {
                    TextField("用户名", text: $username)
                    
                    Picker("认证方式", selection: $authType) {
                        Text("密码").tag(SSHAuthType.password)
                        Text("私钥").tag(SSHAuthType.privateKey)
                    }
                    
                    if authType == .password {
                        SecureField("密码", text: $password)
                    } else {
                        TextField("私钥路径", text: $privateKeyPath)
                    }
                }
            }
            .navigationTitle(host == nil ? "添加主机" : "编辑主机")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(host == nil ? "添加" : "保存") {
                        let config = SSHConfigModel(
                            id: host?.id ?? UUID(),
                            name: name,
                            host: hostname,
                            port: Int(port) ?? 22,
                            username: username,
                            authType: authType,
                            password: authType == .password ? password : nil,
                            privateKeyPath: authType == .privateKey ? privateKeyPath : nil
                        )
                        onAdd(config)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .padding()
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        !hostname.isEmpty &&
        !username.isEmpty &&
        (authType == .password ? !password.isEmpty : !privateKeyPath.isEmpty)
    }
}
