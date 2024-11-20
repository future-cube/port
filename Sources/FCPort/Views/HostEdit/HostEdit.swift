import SwiftUI

struct HostEdit: View {
    var host: SSHConfigModel?
    let onAdd: (SSHConfigModel) -> Void
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var hostname: String
    @State private var port: String
    @State private var user: String
    @State private var authType: SSHAuthType
    @State private var password: String
    @State private var privateKeyPath: String
    
    init(
        host: SSHConfigModel? = nil,
        onAdd: @escaping (SSHConfigModel) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.host = host
        self.onAdd = onAdd
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
                            TextField("22", text: $port)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: port) { newValue in
                                    let filtered = newValue.filter { $0.isNumber }.prefix(5)
                                    port = String(filtered)
                                }
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
                        HStack {
                            Text("认证方式")
                                .frame(width: 80, alignment: .leading)
                            Picker("", selection: $authType) {
                                Text("密码").tag(SSHAuthType.password)
                                Text("私钥").tag(SSHAuthType.privateKey)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        if authType == .password {
                            HStack {
                                Text("密码")
                                    .frame(width: 80, alignment: .leading)
                                SecureField("请输入密码", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        } else {
                            HStack {
                                Text("私钥路径")
                                    .frame(width: 80, alignment: .leading)
                                TextField("请选择私钥文件", text: $privateKeyPath)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("选择") {
                                    // TODO: 添加文件选择功能
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding(.horizontal)
            
            // 按钮
            HStack(spacing: 20) {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button(host == nil ? "添加" : "保存") {
                    let config = SSHConfigModel(
                        id: host?.id ?? UUID(),
                        name: name,
                        host: hostname,
                        port: Int(port) ?? 22,
                        user: user,
                        authType: authType,
                        password: authType == .password ? password : nil,
                        privateKey: nil,
                        privateKeyPath: authType == .privateKey ? privateKeyPath : nil,
                        rules: host?.rules ?? []
                    )
                    onAdd(config)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding(.bottom)
            
            Spacer()
        }
        .frame(width: 400)
        .background(Color(.windowBackgroundColor))
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        !hostname.isEmpty &&
        !user.isEmpty &&
        (authType == .password ? !password.isEmpty : !privateKeyPath.isEmpty)
    }
}
