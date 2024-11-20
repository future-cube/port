import SwiftUI

struct EmptyState: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "info.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

