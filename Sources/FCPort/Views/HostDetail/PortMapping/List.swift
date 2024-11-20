import SwiftUI

struct PortMappingList: View {
    let mappings: [PortMappingModel]
    let onToggle: (PortMappingModel) -> Void
    let onDelete: (PortMappingModel) -> Void
    
    var body: some View {
        ForEach(mappings) { mapping in
            HStack {
                VStack(alignment: .leading) {
                    Text(mapping.name)
                        .font(.headline)
                    Text("\(mapping.localPort) → \(mapping.remotePort)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusIndicator(isActive: mapping.isEnabled)
                    .onTapGesture {
                        onToggle(mapping)
                    }
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    onDelete(mapping)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}
