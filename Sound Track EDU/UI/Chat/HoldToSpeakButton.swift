import SwiftUI

struct HoldToSpeakButton: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var isPressed = false
    
    private let buttonSize: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isRecording {
                recordingIndicator
            }
            
            // Only show partial text when actively recording
            if !viewModel.partialText.isEmpty && viewModel.isRecording {
                partialTextView
            }
            
            ZStack {
                Circle()
                    .fill(buttonBackground)
                    .frame(width: buttonSize, height: buttonSize)
                    .scaleEffect(isPressed ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                    .shadow(color: buttonBackground.opacity(0.3), radius: 8, x: 0, y: 4)
                
                if viewModel.isRecording {
                    if viewModel.isLocked {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 36, height: 36)
                            .scaleEffect(recordingAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingAnimation)
                    }
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed {
                            startRecording()
                            isPressed = true
                        }
                        
                        if value.translation.height < -50 && !viewModel.isLocked {
                            viewModel.toggleLock()
                        }
                    }
                    .onEnded { _ in
                        if !viewModel.isLocked {
                            stopRecording()
                        }
                        isPressed = false
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if viewModel.isLocked {
                            stopRecording()
                        }
                    }
            )
            
            Text(buttonLabel)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
    
    private var recordingIndicator: some View {
        HStack(spacing: 12) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(audioLevelColor(index))
                        .frame(width: 4, height: CGFloat(10 + index * 5))
                        .scaleEffect(viewModel.audioLevel > Float(index) / 5 ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)
                }
            }
            
            Text("You're speaking...")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
        )
    }
    
    private var partialTextView: some View {
        Text(viewModel.partialText)
            .font(.body)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity * 0.85)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemGray6).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            )
    }
    
    private var buttonBackground: Color {
        if viewModel.isRecording {
            return viewModel.isLocked ? Color.red : Theme.accent
        } else {
            return Theme.accent
        }
    }
    
    private var buttonLabel: String {
        if viewModel.isLocked {
            return "Tap to End"
        } else if viewModel.isRecording {
            return "Recording..."
        } else {
            return "Hold to Speak"
        }
    }
    
    private var recordingAnimation: Bool {
        viewModel.isRecording
    }
    
    private func audioLevelColor(_ index: Int) -> Color {
        let threshold = Float(index) / 5
        return viewModel.audioLevel > threshold ? Theme.accent : Color(.systemGray4)
    }
    
    private func startRecording() {
        Task {
            await viewModel.startRecording()
        }
    }
    
    private func stopRecording() {
        Task {
            await viewModel.stopRecording()
        }
    }
}

#Preview {
    HoldToSpeakButton()
        .environmentObject(ChatViewModel())
}
