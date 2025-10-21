import Foundation
import Combine

// MARK: - Unified Record Type

enum RecordType: String, Codable {
    case transcript
    case chat
}

struct UnifiedRecord: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var title: String
    let type: RecordType
    
    // Transcript fields
    var transcriptRecord: TranscriptRecord?
    
    // Chat fields
    var chatSession: ChatSession?
    
    var displayTitle: String {
        title.isEmpty ? dateString : title
    }
    
    var dateString: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: createdAt)
    }
}

// MARK: - Transcript Store

final class TranscriptStore: ObservableObject {
    @Published private(set) var records: [UnifiedRecord] = []
    @Published var isLoading: Bool = true

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("unified_records.json")
    }()

    init() {
        // Load data asynchronously to avoid blocking app startup
        Task {
            await loadAsync()
        }
    }

    // MARK: - Transcript CRUD
    func add(record: TranscriptRecord) {
        let unified = UnifiedRecord(
            id: record.id,
            createdAt: record.createdAt,
            title: record.title,
            type: .transcript,
            transcriptRecord: record,
            chatSession: nil
        )
        records.insert(unified, at: 0)
        saveNow()
    }

    func delete(_ record: TranscriptRecord) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records.remove(at: idx)
            saveNow()
        }
    }

    func replace(_ record: TranscriptRecord) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx].transcriptRecord = record
            records[idx].title = record.title
            saveNow()
        }
    }
    
    func updateSummary(for recordId: UUID, summary: String) {
        if let idx = records.firstIndex(where: { $0.id == recordId }) {
            records[idx].transcriptRecord?.summary = summary
            saveNow()
        }
    }
    
    // MARK: - Chat CRUD
    func add(chatSession: ChatSession) {
        let unified = UnifiedRecord(
            id: chatSession.id,
            createdAt: chatSession.createdAt,
            title: chatSession.title,
            type: .chat,
            transcriptRecord: nil,
            chatSession: chatSession
        )
        records.insert(unified, at: 0)
        saveNow()
    }
    
    func delete(chatSession: ChatSession) {
        if let idx = records.firstIndex(where: { $0.id == chatSession.id }) {
            records.remove(at: idx)
            saveNow()
        }
    }
    
    func updateChatSummary(for sessionId: UUID, summary: String) {
        if let idx = records.firstIndex(where: { $0.id == sessionId }) {
            records[idx].chatSession?.summary = summary
            saveNow()
        }
    }
    
    // MARK: - Filtered Access
    var transcriptRecords: [TranscriptRecord] {
        return records.compactMap { $0.transcriptRecord }
    }
    
    var chatSessions: [ChatSession] {
        return records.compactMap { $0.chatSession }
    }

    // MARK: - Persistence
    
    @MainActor
    private func loadAsync() async {
        // Perform file I/O on background thread
        let loadedRecords = await Task.detached(priority: .userInitiated) { [fileURL] in
            // Try to load unified records
            if let data = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode([UnifiedRecord].self, from: data) {
                return decoded
            }
            
            // Attempt migration from old format
            let oldFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("transcripts.json")
            
            if let data = try? Data(contentsOf: oldFileURL),
               let oldRecords = try? JSONDecoder().decode([TranscriptRecord].self, from: data) {
                return oldRecords.map { record in
                    UnifiedRecord(
                        id: record.id,
                        createdAt: record.createdAt,
                        title: record.title,
                        type: .transcript,
                        transcriptRecord: record,
                        chatSession: nil
                    )
                }
            }
            
            return []
        }.value
        
        // Update UI on main thread
        self.records = loadedRecords
        self.isLoading = false
        
        // Save migrated data if needed
        if !loadedRecords.isEmpty && (try? Data(contentsOf: fileURL)) == nil {
            saveNow()
        }
    }

    func saveNow() {
        // Perform save asynchronously to avoid blocking UI
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            let recordsToSave = await MainActor.run { self.records }
            guard let data = try? JSONEncoder().encode(recordsToSave) else { return }
            try? data.write(to: await MainActor.run { self.fileURL }, options: [.atomic])
        }
    }
}
