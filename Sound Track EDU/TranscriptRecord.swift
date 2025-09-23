import Foundation

struct TranscriptRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    var title: String
    var text: String
    var period: String
    var subject: String
    var teacher: String
    var term: String  // Semester, Trimester, Quarter
    var termNumber: String  // 1, 2, 3, or 4
    var summary: String?  // reserved for later when we add GPT summaries

    // Niceties for display / filenames
    var displayTitle: String {
        title.isEmpty ? dateString : title
    }

    var dateString: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: createdAt)
    }
    
    var termDisplay: String {
        switch term.lowercased() {
        case "semester":
            return "Sem \(termNumber)"
        case "trimester":
            return "Tri \(termNumber)"
        case "quarter":
            return "Q\(termNumber)"
        default:
            return "\(term) \(termNumber)"
        }
    }
}
