//
//  Sound_Track_EDUApp.swift
//  Sound Track EDU
//
//  Created by Anika M on 8/19/25.
//

import SwiftUI

@main
struct Sound_Track_EDUApp: App {
    @StateObject private var transcriptStore = TranscriptStore()
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var alertSyncService = AlertSyncService()
    @StateObject private var liveTranscriber = LiveTranscriber()
    @StateObject private var hudManager = AlertHUDManager()
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(transcriptStore)
                .environmentObject(profileStore)
                .environmentObject(alertSyncService)
                .environmentObject(liveTranscriber)
                .environmentObject(hudManager)
                .onAppear {
                    // Defer permission requests to avoid blocking UI
                    Task {
                        // Request notification permissions on first launch
                        await alertSyncService.requestNotificationPermissions()
                    }
                    
                    // Set up shared HUD manager to start transcription
                    hudManager.onStartTranscription = { [weak liveTranscriber] in
                        await liveTranscriber?.start()
                    }
                }
        }
    }
}
