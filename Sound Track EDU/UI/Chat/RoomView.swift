import SwiftUI

struct RoomView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            roomHeader
            chatMessages
            HoldToSpeakButton()
                .environmentObject(viewModel)
        }
        .background(Theme.beige.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Leave") {
                    viewModel.leaveRoom()
                }
                .foregroundColor(.red)
            }
        }
        .dismissKeyboardOnTap()
    }
    
    private var roomHeader: some View {
        VStack(spacing: 16) {
            // Main header content
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.roomTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.connectionStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.isHost {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Join Code")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(viewModel.joinCode)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.accent)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.accent.opacity(0.1))
                    )
                }
            }
            
            // Participant section with subtle divider
            if !viewModel.participants.isEmpty {
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 0.5)
                    
                    RosterPillsView(participants: viewModel.participants)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var chatMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.turns.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.turns) { turn in
                            ChatBubbleView(
                                turn: turn,
                                isFromCurrentUser: turn.isFromCurrentUser(myId: viewModel.myParticipantId)
                            )
                            .id(turn.id)
                        }
                    }
                    
                    // Bottom spacer for better visual balance
                    Color.clear
                        .frame(height: 20)
                        .id("bottom")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: viewModel.turns.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onAppear {
                viewModel.onNewMessage = {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No messages yet")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Hold the button below to start the conversation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
}

#Preview {
    RoomView()
        .environmentObject(ChatViewModel())
}
