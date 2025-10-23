import SwiftUI

/// Review tab – organized by Period/Subject with clean grouping
struct ReviewView: View {
    @EnvironmentObject private var store: TranscriptStore
    @EnvironmentObject private var alertSync: AlertSyncService
    @EnvironmentObject private var transcriber: LiveTranscriber
    @EnvironmentObject private var hudManager: AlertHUDManager
    @State private var query: String = ""
    @State private var showingSummary: TranscriptRecord?
    @State private var selectedSegment: ContentType = .transcripts
    
    enum ContentType: String, CaseIterable {
        case transcripts = "Transcripts"
        case chats = "Chats"
    }

    // Group transcript records by subject + period, then by date
    private var groupedRecords: [(String, [(String, [TranscriptRecord])])] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = q.isEmpty ? store.transcriptRecords : store.transcriptRecords.filter {
            $0.displayTitle.lowercased().contains(q)
            || String($0.period).contains(q)
            || $0.subject.lowercased().contains(q)
        }

        let subjectPeriodGroups = Dictionary(grouping: filtered) { r in
            let teacherText = r.teacher.isEmpty ? "" : " • \(r.teacher)"
            return "\(r.subject) • \(r.termDisplay) • Period \(r.period)\(teacherText)"
        }

        return subjectPeriodGroups
            .map { (subjectPeriod, records) in
                let df = DateFormatter()
                df.dateFormat = "MMM d, yyyy"
                let dateGroups = Dictionary(grouping: records) { df.string(from: $0.createdAt) }
                let sortedDateGroups = dateGroups.sorted { $0.key > $1.key }
                return (subjectPeriod, sortedDateGroups)
            }
            .sorted { $0.0 < $1.0 }
    }
    
    // Group chat sessions by subject + period + term, then by date
    private var groupedChats: [(String, [(String, [ChatSession])])] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = q.isEmpty ? store.chatSessions : store.chatSessions.filter {
            $0.title.lowercased().contains(q)
            || String($0.period).contains(q)
            || $0.subject.lowercased().contains(q)
            || $0.discussionTopic.lowercased().contains(q)
        }
        
        // Group by subject/period/term (matching transcript pattern)
        let subjectPeriodGroups = Dictionary(grouping: filtered) { session in
            let teacherText = session.teacher.isEmpty ? "" : " • \(session.teacher)"
            return "\(session.subject) • \(session.termDisplay) • Period \(session.period)\(teacherText)"
        }
        
        return subjectPeriodGroups
            .map { (subjectPeriod, sessions) in
                let df = DateFormatter()
                df.dateFormat = "MMM d, yyyy"
                let dateGroups = Dictionary(grouping: sessions) { df.string(from: $0.createdAt) }
                let sortedDateGroups = dateGroups.sorted { $0.key > $1.key }
                return (subjectPeriod, sortedDateGroups)
            }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Content", selection: $selectedSegment) {
                    ForEach(ContentType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Theme.beige)
                
                if selectedSegment == .transcripts {
                    transcriptsList
                } else {
                    chatsList
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationDestination(for: TranscriptRecord.self) { record in
                TranscriptDetailView(record: record)
            }
            .navigationDestination(for: ChatSession.self) { session in
                ChatDetailView(session: session)
            }
        }
        .tint(Theme.accent)
        .background(Theme.beige.ignoresSafeArea())
        .sheet(item: $showingSummary) { record in
            SummaryDetailView(record: record)
        }
    }
    
    private var transcriptsList: some View {
        List {
            ForEach(groupedRecords, id: \.0) { subjectPeriod, dateGroups in
                    Section {
                        ForEach(dateGroups, id: \.0) { dateString, records in
                            // Date chip (neutral, warm)
                            Text(dateString)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Theme.card) // uses your lighter airy option
                                )
                                .listRowBackground(Theme.beige)

                            // Card rows
                            ForEach(records.sorted { $0.createdAt > $1.createdAt }) { record in
                                NavigationLink(value: record) {
                                    TranscriptRowCard(record: record) {
                                        showingSummary = record
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Theme.beige)
                            }
                        }
                    } header: {
                        Text(subjectPeriod)
                            .textCase(nil)
                            .font(.headline)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.beige.ignoresSafeArea())
    }
    
    private var chatsList: some View {
        List {
            if groupedChats.isEmpty {
                Text("No saved chat sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .listRowBackground(Theme.beige)
            } else {
                ForEach(groupedChats, id: \.0) { subjectPeriod, dateGroups in
                    Section {
                        ForEach(dateGroups, id: \.0) { dateString, sessions in
                            // Date chip (neutral, warm) - matching transcriptsList
                            Text(dateString)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Theme.card) // uses your lighter airy option
                                )
                                .listRowBackground(Theme.beige)

                            // Card rows
                            ForEach(sessions.sorted { $0.createdAt > $1.createdAt }) { session in
                                NavigationLink(value: session) {
                                    ChatRowCard(session: session)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Theme.beige)
                            }
                        }
                    } header: {
                        Text(subjectPeriod)
                            .textCase(nil)
                            .font(.headline)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.beige.ignoresSafeArea())
    }
}

// MARK: - Transcript Row (time on top, transcript below)
// Uses Theme.card (your lighter airy value), plus very subtle border + shadow.
private struct TranscriptRowCard: View {
    let record: TranscriptRecord
    let onSummaryTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Left stack: time on its own line, transcript below (full width)
            VStack(alignment: .leading, spacing: 8) {
                Text(timeString)
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !record.text.isEmpty {
                    Text(record.text)
                        .font(.body)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(3)
                } else {
                    Text(record.title.isEmpty ? "Untitled" : record.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Summary indicator
            if record.summary?.isEmpty == false {
                Button(action: onSummaryTap) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.accent)
                        .font(.title3)
                        .padding(6)
                        .background(Theme.accent.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View AI summary")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1) // subtle pop
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.accent.opacity(0.05), lineWidth: 0.25) // hairline border
        )
        .padding(.vertical, 4)
    }

    private var timeString: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: record.createdAt)
    }
}

// MARK: - Chat Row Card
private struct ChatRowCard: View {
    let session: ChatSession
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left stack: time on its own line, content below (matching transcript layout)
            VStack(alignment: .leading, spacing: 8) {
                Text(timeString)
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                // Show discussion topic or title
                Text(session.discussionTopic.isEmpty ? (session.title.isEmpty ? "Untitled Chat" : session.title) : session.discussionTopic)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(2)
                
                // Show participant count and names
                HStack(spacing: 4) {
                    Text("\(session.roster.count) participant\(session.roster.count == 1 ? "" : "s"):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(participantNames)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 8)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.accent.opacity(0.05), lineWidth: 0.25)
        )
        .padding(.vertical, 4)
    }
    
    private var timeString: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: session.createdAt)
    }
    
    private var participantNames: String {
        session.roster.map { $0.displayName }.joined(separator: ", ")
    }
}

// MARK: - Chat Detail View
struct ChatDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TranscriptStore
    @StateObject private var aiService = AISummaryService()
    @State private var showingSummary = false

    let session: ChatSession
    
    // Get the current session from the store to ensure we have the latest data
    private var currentSession: ChatSession {
        store.chatSessions.first { $0.id == session.id } ?? session
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(currentSession.turns) { turn in
                    ChatBubbleView(
                        turn: turn,
                        isFromCurrentUser: false
                    )
                }
            }
            .padding()
        }
        .background(Theme.beige.ignoresSafeArea())
        .navigationTitle(currentSession.discussionTopic.isEmpty ? currentSession.title : currentSession.discussionTopic)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // AI Summary action
                if currentSession.summary?.isEmpty == false {
                    Button {
                        showingSummary = true
                    } label: {
                        Label("View Summary", systemImage: "sparkles")
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

                // Share as a temporary text file
                Button {
                    let url = ShareHelper.temporaryFile(for: currentSession)
                    ShareHelper.presentShareSheet(with: [url])
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                // Delete this chat session
                Button(role: .destructive) {
                    store.delete(chatSession: currentSession)
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingSummary) {
            ChatSummaryDetailView(session: currentSession)
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
            return
        }
        
        // Update the session with the new summary
        store.updateChatSummary(for: currentSession.id, summary: summary)
        
        // Show the summary
        showingSummary = true
    }
}

