import Foundation

/// Represents a single turn/message in a chat session
struct ChatTurn: Codable, Identifiable, Hashable {
    let id: UUID
    let speakerId: String
    let displayName: String
    let colorHex: String
    let text: String
    let startedAt: Date
    let endedAt: Date
    
    init(speakerId: String, displayName: String, colorHex: String, text: String, startedAt: Date, endedAt: Date) {
        self.id = UUID()
        self.speakerId = speakerId
        self.displayName = displayName
        self.colorHex = colorHex
        self.text = text
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
    
    var duration: TimeInterval {
        return endedAt.timeIntervalSince(startedAt)
    }
    
    func isFromCurrentUser(myId: String) -> Bool {
        return speakerId == myId
    }
}
