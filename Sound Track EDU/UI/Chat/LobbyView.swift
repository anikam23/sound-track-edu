import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var displayName = ""
    @State private var selectedColor = ChatParticipant.randomColor()
    @State private var joinCodeInput = ""
    
    private let availableColors = ["FF6B6B", "4ECDC4", "45B7D1", "FFA07A", "98D8C8", "F7DC6F", "BB8FCE", "85C1E2"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacer for balance
                    Spacer(minLength: 20)
                    
                    // Header Section
                    VStack(spacing: 8) {
                        Text("Start a room or join an existing one")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)
                    
                    // Your Info Card
                    VStack(spacing: 24) {
                        Text("Your Info")
                            .font(.title2.bold())
                            .foregroundStyle(Theme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 20) {
                            // Display Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Theme.primaryText)
                                
                                TextField("Enter your name", text: $displayName)
                                    .font(.body)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            // Color Picker Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Color")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Theme.primaryText)
                                
                                LazyHGrid(rows: Array(repeating: GridItem(.fixed(50), spacing: 12), count: 2), spacing: 12) {
                                    ForEach(availableColors, id: \.self) { color in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                selectedColor = color
                                            }
                                        } label: {
                                            Circle()
                                                .fill(Color(hex: color))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedColor == color ? Theme.accent : Color.clear, lineWidth: 3)
                                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColor)
                                                )
                                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .frame(height: 112) // 2 rows of 50pt + 12pt spacing
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Start Room Button
                        Button {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                viewModel.startRoom(displayName: displayName, color: selectedColor)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "house.fill")
                                    .font(.title3)
                                Text("Start Room")
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accent)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: Theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(displayName.isEmpty)
                        .opacity(displayName.isEmpty ? 0.6 : 1.0)
                        .scaleEffect(displayName.isEmpty ? 0.98 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: displayName.isEmpty)
                        
                        // Join Room Button or Join Code Input
                        if !viewModel.showingJoinCodeInput {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    print("[LobbyView] 📝 Showing join code input")
                                    viewModel.showingJoinCodeInput = true
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "door.left.hand.open")
                                        .font(.title3)
                                    Text("Join Room")
                                        .font(.headline.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .stroke(Theme.accent, lineWidth: 2)
                                )
                                .foregroundColor(Theme.accent)
                            }
                            .disabled(displayName.isEmpty)
                            .opacity(displayName.isEmpty ? 0.6 : 1.0)
                            .scaleEffect(displayName.isEmpty ? 0.98 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: displayName.isEmpty)
                        } else {
                            VStack(spacing: 16) {
                                TextField("ENTER JOIN CODE", text: $joinCodeInput)
                                    .font(.body)
                                    .textCase(.uppercase)
                                    .autocorrectionDisabled()
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                
                                HStack(spacing: 12) {
                                    Button("Cancel") {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            print("[LobbyView] ❌ Cancel join")
                                            viewModel.showingJoinCodeInput = false
                                            joinCodeInput = ""
                                        }
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button("Join Now") {
                                        print("[LobbyView] 🚪 Attempting to join room with code: \(joinCodeInput)")
                                        viewModel.joinRoom(
                                            displayName: displayName,
                                            color: selectedColor,
                                            joinCode: joinCodeInput.isEmpty ? nil : joinCodeInput
                                        )
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Theme.accent)
                                    .clipShape(Capsule())
                                    .shadow(color: Theme.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                            ))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Demo button (hidden by default)
                    if ProcessInfo.processInfo.environment["SHOW_DEMO"] == "true" {
                        Button("Demo") {
                            viewModel.startDemo()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 24)
                    }
                    
                    // Bottom spacer for balance
                    Spacer(minLength: 20)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Theme.beige, Theme.beige.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .dismissKeyboardOnTap()
    }
}

#Preview {
    LobbyView()
        .environmentObject(ChatViewModel())
}
