import SwiftUI

struct HostEdit: View {
    var host: SSHConfigModel?
    let onSave: (SSHConfigModel) -> Void
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var hostname: String
    @State private var port: String
    @State private var user: String
    @State private var authType: SSHAuthType
    @State private var password: String
    @State private var privateKeyPath: String
    @State private var showingPrivateKeyPicker = false
    
    init(
        host: SSHConfigModel? = nil,
        onSave: @escaping (SSHConfigModel) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.host = host
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: host?.name ?? "")
        _hostname = State(initialValue: host?.host ?? "")
        _port = State(initialValue: String(host?.port ?? 22))
        _user = State(initialValue: host?.user ?? "")
        _authType = State(initialValue: host?.authType ?? .password)
        _password = State(initialValue: host?.password ?? "")
        _privateKeyPath = State(initialValue: host?.privateKeyPath ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(host == nil ? "添加主机" : "编辑主机")
                .font(.title)
                .padding(.top)
            
            VStack(spacing: 16) {
                // 基本信息
                GroupBox("基本信息") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("名称")
                                .frame(width: 80, alignment: .leading)
                            TextField("请输入主机名称", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("主机地址")
                                .frame(width: 80, alignment: .leading)
                            TextField("请输入主机地址", text: $hostname)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("端口")
                                .frame(width: 80, alignment: .leading)
                            TextField("请输入端口号", text: $port)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("用户名")
                                .frame(width: 80, alignment: .leading)
                            TextField("请输入用户名", text: $user)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding()
                }
                
                // 认证信息
                GroupBox("认证信息") {
                    VStack(spacing: 12) {
                        Picker("认证方式", selection: $authType) {
                            Text("密码").tag(SSHAuthType.password)
                            Text("密钥").tag(SSHAuthType.privateKey)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if authType == .password {
                            HStack {
                                Text("密码")
                                    .frame(width: 80, alignment: .leading)
                                SecureField("请输入密码", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        } else {
                            HStack {
                                Text("密钥路径")
                                    .frame(width: 80, alignment: .leading)
                                TextField("请选择密钥文件", text: $privateKeyPath)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("选择") {
                                    showingPrivateKeyPicker = true
                                }
                            }
                            .fileImporter(
                                isPresented: $showingPrivateKeyPicker,
                                allowedContentTypes: [.item],
                                allowsMultipleSelection: false
                            ) { result in
                                switch result {
                                case .success(let files):
                                    if let selectedFile = files.first {
                                        privateKeyPath = selectedFile.path
                                    }
                                case .failure(let error):
                                    print("Error selecting file: \(error)")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // 操作按钮
            HStack {
                Button("取消", action: onCancel)
                    .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("保存") {
                    let newHost = SSHConfigModel(
                        id: host?.id ?? UUID(),
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        host: hostname.trimmingCharacters(in: .whitespacesAndNewlines),
                        port: Int(port.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 22,
                        user: user.trimmingCharacters(in: .whitespacesAndNewlines),
                        authType: authType,
                        password: password,
                        privateKeyPath: privateKeyPath.trimmingCharacters(in: .whitespacesAndNewlines),
                        rules: host?.rules ?? []
                    )
                    onSave(newHost)
                }
                .keyboardShortcut(.return)
                .disabled(!isValid)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 400)
    }
    
    private var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHostname = hostname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUser = user.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPort = port.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty,
              !trimmedHostname.isEmpty,
              !trimmedUser.isEmpty,
              !trimmedPort.isEmpty,
              let portNumber = Int(trimmedPort),
              portNumber > 0,
              portNumber <= 65535
        else {
            return false
        }
        
        if authType == .privateKey {
            return !privateKeyPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        return true
    }
}
