import SwiftUI

struct ChatTabView: View {
    @EnvironmentObject private var store: TranscriptStore
    @EnvironmentObject private var alertSync: AlertSyncService
    @EnvironmentObject private var transcriber: LiveTranscriber
    @EnvironmentObject private var hudManager: AlertHUDManager
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSaveSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isInRoom {
                    RoomView()
                        .environmentObject(viewModel)
                } else {
                    LobbyView()
                        .environmentObject(viewModel)
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.isInRoom {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            showingSaveSheet = true
                        }
                        .disabled(viewModel.turns.isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveChatSheet { discussionTopic, subject, teacher, period, term, termNumber in
                viewModel.saveChat(discussionTopic: discussionTopic, subject: subject, teacher: teacher, period: period, term: term, termNumber: termNumber, store: store)
                showingSaveSheet = false
            }
            .presentationDetents([.medium])
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ChatTabView()
        .environmentObject(TranscriptStore())
}
