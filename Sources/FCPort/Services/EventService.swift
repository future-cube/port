import Foundation
import Combine

enum AppEvent {
    case hostSelected(SSHConfigModel)
    case hostAdded(SSHConfigModel)
    case hostUpdated(SSHConfigModel)
    case hostDeleted(SSHConfigModel)
    case portMappingAdded(PortMappingModel)
    case portMappingUpdated(PortMappingModel)
    case portMappingDeleted(PortMappingModel)
}

class EventService: ObservableObject {
    static let shared = EventService()
    
    private let eventSubject = PassthroughSubject<AppEvent, Never>()
    var eventPublisher: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    func publish(_ event: AppEvent) {
        eventSubject.send(event)
    }
}
