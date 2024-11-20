import Foundation

enum PortValidationError: Error, LocalizedError {
    case invalidFormat
    case portOutOfRange
    case invalidRange
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "端口格式无效。请使用单个端口(如8080)、多个端口(如8080,8090)或端口范围(如8080-8090)"
        case .portOutOfRange:
            return "端口必须在1-65535之间"
        case .invalidRange:
            return "端口范围无效。结束端口必须大于起始端口"
        }
    }
}

struct PortValidator {
    static func validate(_ portString: String) throws {
        // 移除所有空格
        let trimmed = portString.replacingOccurrences(of: " ", with: "")
        
        if trimmed.contains("-") {
            // 端口范围格式 (如 8080-8090)
            let parts = trimmed.split(separator: "-")
            guard parts.count == 2,
                  let start = Int(parts[0]),
                  let end = Int(parts[1])
            else {
                throw PortValidationError.invalidFormat
            }
            
            guard (1...65535).contains(start) && (1...65535).contains(end) else {
                throw PortValidationError.portOutOfRange
            }
            
            guard end > start else {
                throw PortValidationError.invalidRange
            }
        } else if trimmed.contains(",") {
            // 多个端口格式 (如 8080,8090)
            let ports = trimmed.split(separator: ",")
            guard !ports.isEmpty else {
                throw PortValidationError.invalidFormat
            }
            
            try ports.forEach { portStr in
                guard let port = Int(portStr) else {
                    throw PortValidationError.invalidFormat
                }
                guard (1...65535).contains(port) else {
                    throw PortValidationError.portOutOfRange
                }
            }
        } else {
            // 单个端口格式 (如 8080)
            guard let port = Int(trimmed) else {
                throw PortValidationError.invalidFormat
            }
            guard (1...65535).contains(port) else {
                throw PortValidationError.portOutOfRange
            }
        }
    }
}
