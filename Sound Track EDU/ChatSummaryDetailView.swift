import SwiftUI

struct ChatSummaryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TranscriptStore
    @StateObject private var aiService = AISummaryService()
    
    let session: ChatSession
    
    // Get the current session from the store to ensure we have the latest data
    private var currentSession: ChatSession {
        store.chatSessions.first { $0.id == session.id } ?? session
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(currentSession.discussionTopic.isEmpty ? currentSession.title : currentSession.discussionTopic)
                    .font(.title)
                    .bold()

                GroupBox("Summary") {
                    Text(currentSession.summary?.isEmpty == false
                         ? currentSession.summary!
                         : "No summary yet.\n\nTap **Generate Summary** to create one later.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Chat Messages") {
                    Text(currentSession.chatText.isEmpty ? "—" : currentSession.chatText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if currentSession.summary?.isEmpty == false {
                    Button("Done") {
                        dismiss()
                    }
                } else {
                    Button {
                        Task {
                            await generateSummary()
                        }
                    } label: {
                        if aiService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Label("Generate Summary", systemImage: "sparkles")
                        }
                    }
                    .disabled(aiService.isLoading)
                }
            }
        }
        .alert("Summary Error", isPresented: .constant(aiService.errorMessage != nil)) {
            Button("OK") {
                aiService.errorMessage = nil
            }
        } message: {
            Text(aiService.errorMessage ?? "")
        }
    }
    
    private func generateSummary() async {
        guard let summary = await aiService.generateSummary(
            for: currentSession.chatText,
            subject: currentSession.subject,
            period: currentSession.period
        ) else {
            print("Failed to generate summary")
            return
        }
        
        print("Generated summary: \(summary)")
        
        // Update the session with the new summary
        store.updateChatSummary(for: currentSession.id, summary: summary)
        
        print("Updated store with summary for session: \(currentSession.id)")
    }
}
