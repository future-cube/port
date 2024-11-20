import Foundation
import Combine

// 主机相关事件
enum HostEvent {
    case selected(SSHConfigModel)  // 选中主机
    case created(SSHConfigModel)   // 创建主机
    case updated(SSHConfigModel)   // 更新主机
    case deleted(UUID)            // 删除主机
}

// 规则相关事件
enum RuleEvent {
    case created(PortMapping, UUID)   // 创建规则，参数：规则和主机ID
    case updated(PortMapping, UUID)   // 更新规则，参数：规则和主机ID
    case deleted(UUID, UUID)         // 删除规则，参数：规则ID和主机ID
    case cleared(UUID)               // 清空规则，参数：主机ID
}

// 应用事件
enum AppEvent {
    case host(HostEvent)    // 主机相关事件
    case rule(RuleEvent)    // 规则相关事件
}

// 事件服务
class EventService: ObservableObject {
    static let shared = EventService()
    
    private let eventSubject = PassthroughSubject<AppEvent, Never>()
    var eventPublisher: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    // 主机事件发布器
    var hostEventPublisher: AnyPublisher<HostEvent, Never> {
        eventPublisher.compactMap { event in
            if case .host(let hostEvent) = event {
                return hostEvent
            }
            return nil
        }.eraseToAnyPublisher()
    }
    
    // 规则事件发布器
    var ruleEventPublisher: AnyPublisher<RuleEvent, Never> {
        eventPublisher.compactMap { event in
            if case .rule(let ruleEvent) = event {
                return ruleEvent
            }
            return nil
        }.eraseToAnyPublisher()
    }
    
    private init() {}
    
    // 发布事件
    func publish(_ event: AppEvent) {
        eventSubject.send(event)
    }
    
    // 发布主机事件
    func publishHostEvent(_ event: HostEvent) {
        publish(.host(event))
    }
    
    // 发布规则事件
    func publishRuleEvent(_ event: RuleEvent) {
        publish(.rule(event))
    }
}
