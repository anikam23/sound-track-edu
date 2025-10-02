import SwiftUI

/// Banner view that displays teacher alerts with appropriate styling
struct AlertBannerView: View {
    let alert: TeacherAlert
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Alert icon
            Image(systemName: alert.type.iconName)
                .font(.title2)
                .foregroundStyle(alert.type == .importantNow ? Theme.accent : .orange)
                .frame(width: 28, height: 28)
            
            // Alert content
            VStack(alignment: .leading, spacing: 4) {
                Text(alertTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let message = alert.message, !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text("From \(alert.teacherDisplayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .scaleEffect(1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .scaleEffect(1.0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        )
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeOut(duration: 0.3), value: alert)
    }
    
    private var alertTitle: String {
        switch alert.type {
        case .importantNow:
            return "Important Now"
        case .calledByName:
            if alert.targetStudentName != nil {
                return "You were called"
            } else {
                return "Called by Name"
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AlertBannerView(
            alert: TeacherAlert(
                type: .importantNow,
                teacherDisplayName: "Ms. Johnson",
                message: "Please pay attention to the board"
            ),
            onDismiss: {}
        )
        
        AlertBannerView(
            alert: TeacherAlert(
                type: .calledByName,
                teacherDisplayName: "Mr. Smith",
                targetStudentName: "Anika",
                message: "Can you answer question 3?"
            ),
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

