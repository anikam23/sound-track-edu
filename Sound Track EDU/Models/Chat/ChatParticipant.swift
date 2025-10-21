import Foundation

/// Represents a participant in a peer-to-peer chat session
struct ChatParticipant: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let displayName: String
    let colorHex: String
    
    init(id: String, displayName: String, colorHex: String) {
        self.id = id
        self.displayName = displayName
        self.colorHex = colorHex
    }
    
    static func randomColor() -> String {
        let colors = ["FF6B6B", "4ECDC4", "45B7D1", "FFA07A", "98D8C8", "F7DC6F", "BB8FCE", "85C1E2"]
        return colors.randomElement() ?? "4ECDC4"
    }
    
    var isEmoji: Bool {
        return colorHex.unicodeScalars.count == 1 && 
               colorHex.unicodeScalars.first?.properties.isEmoji == true
    }
}
