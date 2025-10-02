import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LiveTabView()
                .tabItem { Label("Live", systemImage: "mic.fill") }

            ReviewView()
                .tabItem { Label("Review", systemImage: "doc.text.magnifyingglass") }

            TeacherModeView()
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
        }
        .tint(Theme.accent)
        .background(Theme.beige.ignoresSafeArea())
    }
}

#Preview { ContentView() }
