import Foundation

/// Lightweight student profile stored locally on each device
struct StudentProfile: Codable, Equatable {
    var id: String              // stable UUID string saved in UserDefaults/Keychain
    var displayName: String
    var receiveAlerts: Bool
    var autoStartOnImportant: Bool  // if true, auto-start transcription when important alert arrives
    
    static func createDefault() -> StudentProfile {
        return StudentProfile(
            id: UUID().uuidString,
            displayName: "Student",
            receiveAlerts: true,
            autoStartOnImportant: false
        )
    }
}

