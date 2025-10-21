import SwiftUI

struct RosterPillsView: View {
    let participants: [ChatParticipant]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(participants) { participant in
                    ParticipantPill(participant: participant)
                }
            }
        }
    }
}

struct ParticipantPill: View {
    let participant: ChatParticipant
    
    var body: some View {
        HStack(spacing: 8) {
            if participant.isEmoji {
                Text(participant.colorHex)
                    .font(.caption)
            } else {
                Circle()
                    .fill(Color(hex: participant.colorHex))
                    .frame(width: 14, height: 14)
                    .shadow(color: Color(hex: participant.colorHex).opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            Text(participant.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    RosterPillsView(participants: [
        ChatParticipant(id: "1", displayName: "Alice", colorHex: "FF6B6B"),
        ChatParticipant(id: "2", displayName: "Bob", colorHex: "4ECDC4"),
        ChatParticipant(id: "3", displayName: "Charlie", colorHex: "45B7D1")
    ])
}
