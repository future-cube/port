import SwiftUI

@main
struct FCPortApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to FCPort!")
                .font(.title)
                .padding()
            Text("This is a basic macOS application")
                .padding()
        }
        .frame(width: 400, height: 300)
    }
}
