import SwiftUI

struct ContentView: View {
    @StateObject private var store = TranscriptStore()

    var body: some View {
        TabView {
            LiveTabView()
                .tabItem { Label("Live", systemImage: "mic.fill") }

            ReviewView()
                .tabItem { Label("Review", systemImage: "doc.text.magnifyingglass") }

            TeacherModeView() // your existing file
                .tabItem { Label("Teacher", systemImage: "graduationcap.fill") }
        }
        .tint(Theme.accent)
        .background(Theme.beige.ignoresSafeArea())
        .environmentObject(store)
    }
}

#Preview { ContentView() }
