import SwiftUI
import Combine

struct PortMapping: View {
    let host: SSHConfigModel
    @State private var ruleName = ""
    @State private var localPort = ""
    @State private var remotePort = ""
    @State private var isEnabled = true
    @State private var mappings: [PortMappingModel] = []
    @State private var cancellables = Set<AnyCancellable>()
    
    private func resetForm() {
        ruleName = ""
        localPort = ""
        remotePort = ""
        isEnabled = true
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 操作区域
            GroupBox {
                VStack(spacing: 16) {
                    // 端口映射列表标题
                    HStack {
                        Text("端口映射")
                            .font(.headline)
                        Spacer()
                    }
                    
                    // 添加端口映射表单
                    HStack(spacing: 16) {
                        TextField("规则名称", text: $ruleName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                        
                        TextField("本地端口", text: $localPort)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onChange(of: localPort) { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                localPort = filtered
                            }
                        
                        TextField("远程端口", text: $remotePort)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onChange(of: remotePort) { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                remotePort = filtered
                            }
                        
                        Toggle("启用", isOn: $isEnabled)
                            .toggleStyle(.switch)
                        
                        Button("添加") {
                            guard let localPortInt = Int(localPort),
                                  let remotePortInt = Int(remotePort) else { return }
                            
                            let mapping = PortMappingModel(
                                id: UUID(),
                                hostId: host.id,
                                name: ruleName,
                                localPort: localPortInt,
                                remotePort: remotePortInt,
                                isEnabled: isEnabled
                            )
                            
                            mappings.append(mapping)
                            EventService.shared.publish(.portMappingAdded(mapping))
                            resetForm()
                        }
                        .disabled(ruleName.isEmpty || localPort.isEmpty || remotePort.isEmpty)
                    }
                }
                .padding()
            }
            
            // 端口映射列表
            List {
                ForEach(mappings) { mapping in
                    HStack {
                        Text(mapping.name)
                            .frame(width: 120, alignment: .leading)
                        
                        Text("\(mapping.localPort)")
                            .frame(width: 80)
                        
                        Text("\(mapping.remotePort)")
                            .frame(width: 80)
                        
                        Toggle("", isOn: Binding(
                            get: { mapping.isEnabled },
                            set: { newValue in
                                if let index = mappings.firstIndex(where: { $0.id == mapping.id }) {
                                    var updatedMapping = mapping
                                    updatedMapping.isEnabled = newValue
                                    mappings[index] = updatedMapping
                                    EventService.shared.publish(.portMappingUpdated(updatedMapping))
                                }
                            }
                        ))
                        .toggleStyle(.switch)
                        
                        Spacer()
                        
                        Button(action: {
                            mappings.removeAll { $0.id == mapping.id }
                            EventService.shared.publish(.portMappingDeleted(mapping))
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
        .padding()
        .task {
            // 订阅主机选择事件，重置表单
            EventService.shared.eventPublisher
                .receive(on: DispatchQueue.main)
                .sink { event in
                    if case .hostSelected = event {
                        resetForm()
                    }
                }
                .store(in: &cancellables)
        }
    }
}
