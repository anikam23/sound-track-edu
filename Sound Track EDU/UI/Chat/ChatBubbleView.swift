import SwiftUI

struct ChatBubbleView: View {
    let turn: ChatTurn
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 80)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 6) {
                HStack {
                    Text(turn.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(turn.startedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
                
                HStack(alignment: .bottom) {
                    if !isFromCurrentUser {
                        Circle()
                            .fill(Color(hex: turn.colorHex))
                            .frame(width: 10, height: 10)
                            .padding(.trailing, 6)
                    }
                    
                    Text(turn.text)
                        .font(.body)
                        .lineLimit(nil)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(bubbleBackground)
                        .foregroundColor(bubbleTextColor)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 80)
            }
        }
    }
    
    private var bubbleBackground: some View {
        Group {
            if isFromCurrentUser {
                // Current user gets a more vibrant but softer version of their color
                Color(hex: turn.colorHex).opacity(0.9)
            } else {
                // Others get a very subtle background with a soft border
                Color(hex: turn.colorHex).opacity(0.08)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(hex: turn.colorHex).opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    private var bubbleTextColor: Color {
        if isFromCurrentUser {
            return .white
        } else {
            // Use a slightly muted version of the participant's color for better readability
            return Color(hex: turn.colorHex).opacity(0.8)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatBubbleView(
            turn: ChatTurn(
                speakerId: "1",
                displayName: "Alice",
                colorHex: "FF6B6B",
                text: "Hello everyone!",
                startedAt: Date(),
                endedAt: Date()
            ),
            isFromCurrentUser: false
        )
        
        ChatBubbleView(
            turn: ChatTurn(
                speakerId: "2",
                displayName: "You",
                colorHex: "4ECDC4",
                text: "Hi Alice!",
                startedAt: Date(),
                endedAt: Date()
            ),
            isFromCurrentUser: true
        )
    }
    .padding()
}
