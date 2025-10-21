import Foundation

/// Represents a peer-to-peer chat session
struct ChatSession: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    var title: String
    var discussionTopic: String
    var subject: String
    var teacher: String
    var period: String
    var term: String
    var termNumber: String
    var roster: [ChatParticipant]
    var turns: [ChatTurn]
    var isOngoing: Bool
    var summary: String?  // AI-generated summary
    
    init(title: String, discussionTopic: String = "", subject: String = "", teacher: String = "", period: String = "", term: String = "Semester", termNumber: String = "1", roster: [ChatParticipant] = [], turns: [ChatTurn] = [], isOngoing: Bool = true) {
        self.id = UUID()
        self.createdAt = Date()
        self.title = title
        self.discussionTopic = discussionTopic
        self.subject = subject
        self.teacher = teacher
        self.period = period
        self.term = term
        self.termNumber = termNumber
        self.roster = roster
        self.turns = turns
        self.isOngoing = isOngoing
    }
    
    mutating func addParticipant(_ participant: ChatParticipant) {
        if !roster.contains(where: { $0.id == participant.id }) {
            roster.append(participant)
        }
    }
    
    mutating func addTurn(_ turn: ChatTurn) {
        turns.append(turn)
    }
    
    func getParticipant(by id: String) -> ChatParticipant? {
        return roster.first { $0.id == id }
    }
    
    var duration: TimeInterval {
        guard let firstTurn = turns.first?.startedAt,
              let lastTurn = turns.last?.endedAt else {
            return 0
        }
        return lastTurn.timeIntervalSince(firstTurn)
    }
    
    var termDisplay: String {
        switch term.lowercased() {
        case "semester":
            return "S\(termNumber)"
        case "trimester":
            return "T\(termNumber)"
        case "quarter":
            return "Q\(termNumber)"
        default:
            return "\(term) \(termNumber)"
        }
    }
    
    // Get chat content as text for AI summary generation
    var chatText: String {
        return turns.map { turn in
            "\(turn.displayName): \(turn.text)"
        }.joined(separator: "\n")
    }
}
