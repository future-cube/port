import SwiftUI

enum MappingStatus {
    case normal
    case partial
    case error
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .partial: return .yellow
        case .error: return .red
        }
    }
}

struct StatusIndicatorView: View {
    var status: MappingStatus
    var size: CGFloat = 12
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
            .shadow(color: status.color.opacity(0.5), radius: 2)
    }
}
