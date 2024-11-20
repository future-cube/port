import Foundation
import SwiftUI

struct PortMapping: Identifiable, Codable {
    var id = UUID()
    var name: String
    var host: String
    var username: String
    var ports: String
    var isEnabled: Bool
    
    var portRanges: [ClosedRange<Int>] {
        let components = ports.components(separatedBy: ",")
        return components.compactMap { component -> ClosedRange<Int>? in
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("-") {
                let parts = trimmed.split(separator: "-")
                if parts.count == 2,
                   let start = Int(parts[0]),
                   let end = Int(parts[1]) {
                    return start...end
                }
            } else if let port = Int(trimmed) {
                return port...port
            }
            return nil
        }
    }
}

@MainActor
class PortMappingManager: ObservableObject {
    @Published var mappings: [PortMapping] = []
    @Published var selectedMappingId: UUID?
    
    var selectedMapping: PortMapping? {
        guard let selectedId = selectedMappingId else { return nil }
        return mappings.first { $0.id == selectedId }
    }
    
    private let saveURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first?
        .appendingPathComponent("FCPort")
        .appendingPathComponent("mappings.json")
    
    init() {
        createDirectoryIfNeeded()
        loadMappings()
    }
    
    private func createDirectoryIfNeeded() {
        guard let saveURL = saveURL else { return }
        let directoryURL = saveURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
    
    func loadMappings() {
        guard let url = saveURL,
              let data = try? Data(contentsOf: url),
              let loadedMappings = try? JSONDecoder().decode([PortMapping].self, from: data) else {
            return
        }
        mappings = loadedMappings
    }
    
    func saveMappings() {
        guard let url = saveURL,
              let data = try? JSONEncoder().encode(mappings) else {
            return
        }
        try? data.write(to: url)
    }
    
    func addMapping(_ mapping: PortMapping) {
        mappings.append(mapping)
        saveMappings()
    }
    
    func removeMapping(at index: Int) {
        stopMapping(mappings[index])
        mappings.remove(at: index)
        saveMappings()
    }
    
    func toggleMapping(_ mapping: PortMapping) {
        if let index = mappings.firstIndex(where: { $0.id == mapping.id }) {
            var updatedMapping = mapping
            updatedMapping.isEnabled.toggle()
            mappings[index] = updatedMapping
            
            if updatedMapping.isEnabled {
                startMapping(updatedMapping)
            } else {
                stopMapping(updatedMapping)
            }
            saveMappings()
        }
    }
    
    private func startMapping(_ mapping: PortMapping) {
        Task {
            for range in mapping.portRanges {
                for port in range {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
                    process.arguments = [
                        "-N",
                        "-L", "\(port):\(mapping.host):\(port)",
                        "\(mapping.username)@\(mapping.host)"
                    ]
                    try? process.run()
                }
            }
        }
    }
    
    private func stopMapping(_ mapping: PortMapping) {
        Task {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            process.arguments = ["-f", "ssh.*\(mapping.host)"]
            try? process.run()
            process.waitUntilExit()
        }
    }
}
