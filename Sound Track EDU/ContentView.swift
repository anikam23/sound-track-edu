import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var alertSync: AlertSyncService
    @EnvironmentObject private var transcriber: LiveTranscriber
    @EnvironmentObject private var hudManager: AlertHUDManager
    
    var body: some View {
        TabView {
            LiveTabView()
                .tabItem { Label("Live", systemImage: "mic.fill") }

            ChatTabView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }

            TeacherModeView()
                .tabItem { Label("Alerts", systemImage: "bell.fill") }

            ReviewView()
                .tabItem { Label("Review", systemImage: "doc.text.magnifyingglass") }
        }
        .tint(Theme.accent)
        .background(Theme.beige.ignoresSafeArea())
        .alertBannerOverlay(hudManager)
        .onChange(of: alertSync.lastReceivedAlert) { _, newAlert in
            if let alert = newAlert {
                print("🎯 [ContentView] Alert received, processing at app level")
                let isTranscribing = transcriber.uiMode == .listening || transcriber.uiMode == .paused
                hudManager.showAlertWithTranscriptionPrompt(alert, isTranscribing: isTranscribing)
            }
        }
    }
}

#Preview { ContentView() }
