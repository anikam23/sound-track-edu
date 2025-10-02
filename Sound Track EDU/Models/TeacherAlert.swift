import Foundation

/// Types of alerts that teachers can send to students
enum TeacherAlertType: String, Codable, CaseIterable {
    case importantNow    = "important_now"     // "Something important is being said"
    case calledByName    = "called_by_name"    // "<name>, look up!"
    
    var displayName: String {
        switch self {
        case .importantNow:
            return "Important Now"
        case .calledByName:
            return "Called by Name"
        }
    }
    
    var iconName: String {
        switch self {
        case .importantNow:
            return "sparkles"
        case .calledByName:
            return "person.wave.2"
        }
    }
}

/// Alert message sent from teacher to student(s)
struct TeacherAlert: Codable, Identifiable, Equatable {
    let id: UUID
    let type: TeacherAlertType
    let teacherDisplayName: String
    let targetStudentId: String?   // nil = broadcast to all listening students
    let targetStudentName: String?
    let message: String?           // optional extra text
    let createdAt: Date
    
    init(type: TeacherAlertType, teacherDisplayName: String, targetStudentId: String? = nil, targetStudentName: String? = nil, message: String? = nil) {
        self.id = UUID()
        self.type = type
        self.teacherDisplayName = teacherDisplayName
        self.targetStudentId = targetStudentId
        self.targetStudentName = targetStudentName
        self.message = message
        self.createdAt = Date()
    }
}
