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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(transcriptStore)
                .environmentObject(profileStore)
                .environmentObject(alertSyncService)
                .environmentObject(liveTranscriber)
                .onAppear {
                    // Request notification permissions on first launch
                    alertSyncService.requestNotificationPermissions()
                    
                    // Set up auto-start transcription callback
                    alertSyncService.onImportantAlert = { [weak liveTranscriber] in
                        Task {
                            await liveTranscriber?.start()
                        }
                    }
                }
        }
    }
}
