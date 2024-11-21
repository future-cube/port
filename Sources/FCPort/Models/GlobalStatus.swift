import SwiftUI

enum GlobalStatus {
    case running
    case stopped
    case partial
    
    var text: String {
        switch self {
        case .running:
            return "全部运行"
        case .stopped:
            return "全部停止"
        case .partial:
            return "部分运行"
        }
    }
    
    var icon: String {
        switch self {
        case .running:
            return "circle.fill"
        case .stopped:
            return "circle"
        case .partial:
            return "circle.lefthalf.filled"
        }
    }
    
    var color: Color {
        switch self {
        case .running:
            return .green
        case .stopped:
            return .red
        case .partial:
            return .orange
        }
    }
}
