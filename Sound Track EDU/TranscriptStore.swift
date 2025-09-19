import Foundation
import Combine

final class TranscriptStore: ObservableObject {
    @Published private(set) var records: [TranscriptRecord] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("transcripts.json")
    }()

    init() {
        load()
    }

    // MARK: - CRUD
    func add(record: TranscriptRecord) {
        records.insert(record, at: 0)
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
            records[idx] = record
            saveNow()
        }
    }
    
    func updateSummary(for recordId: UUID, summary: String) {
        if let idx = records.firstIndex(where: { $0.id == recordId }) {
            records[idx].summary = summary
            saveNow()
        }
    }

    // MARK: - Persistence
    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([TranscriptRecord].self, from: data) {
            records = decoded
        }
    }

    func saveNow() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
