import Foundation
import SwiftUI

struct PortMappingModel: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let localPort: Int
    let remotePort: Int
    var isEnabled: Bool
    
    init(id: UUID = UUID(), name: String, localPort: Int, remotePort: Int, isEnabled: Bool = false) {
        self.id = id
        self.name = name
        self.localPort = localPort
        self.remotePort = remotePort
        self.isEnabled = isEnabled
    }
}

@MainActor
class PortMappingManager: ObservableObject {
    @Published var mappings: [PortMappingModel] = []
    @Published var selectedMappingId: UUID?
    
    var selectedMapping: PortMappingModel? {
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
              let loadedMappings = try? JSONDecoder().decode([PortMappingModel].self, from: data) else {
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
    
    func addMapping(_ mapping: PortMappingModel) {
        mappings.append(mapping)
        saveMappings()
    }
    
    func removeMapping(at index: Int) {
        stopMapping(mappings[index])
        mappings.remove(at: index)
        saveMappings()
    }
    
    func toggleMapping(_ mapping: PortMappingModel) {
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
    
    private func startMapping(_ mapping: PortMappingModel) {
        Task {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            process.arguments = [
                "-N",
                "-L", "\(mapping.localPort):localhost:\(mapping.remotePort)",
                "localhost"
            ]
            try? process.run()
        }
    }
    
    private func stopMapping(_ mapping: PortMappingModel) {
        Task {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            process.arguments = ["-f", "ssh.*localhost"]
            try? process.run()
            process.waitUntilExit()
        }
    }
}
