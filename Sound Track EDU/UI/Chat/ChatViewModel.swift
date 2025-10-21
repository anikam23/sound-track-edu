import Foundation
import Combine
import AVFoundation
import Speech

@MainActor
class ChatViewModel: ObservableObject {
    @Published var isInRoom = false
    @Published var isHost = false
    @Published var joinCode = ""
    @Published var connectionStatus = "Disconnected"
    @Published var participants: [ChatParticipant] = []
    @Published var turns: [ChatTurn] = []
    @Published var partialText = ""
    @Published var audioLevel: Float = 0
    @Published var isRecording = false
    @Published var isLocked = false
    @Published var showingJoinCodeInput = false
    @Published var errorMessage: String?
    
    private let chatRoomService = ChatRoomService()
    private let recordingManager = ChatRecordingManager()
    private var transcriptStore: TranscriptStore?
    
    var currentSession: ChatSession?
    private var myParticipant: ChatParticipant?
    private var cancellables = Set<AnyCancellable>()
    
    var onNewMessage: (() -> Void)?
    
    var roomTitle: String {
        isHost ? "My Room" : "Chat Room"
    }
    
    var myParticipantId: String {
        myParticipant?.id ?? ""
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        chatRoomService.onTurnReceived = { [weak self] turn in
            self?.addTurn(turn)
        }
        
        chatRoomService.$peers
            .assign(to: &$participants)
        
        chatRoomService.$connectionStatus
            .assign(to: &$connectionStatus)
        
        chatRoomService.$joinCode
            .assign(to: &$joinCode)
        
        chatRoomService.$isHost
            .assign(to: &$isHost)
        
        recordingManager.$partialText
            .assign(to: &$partialText)
        
        recordingManager.$audioLevel
            .assign(to: &$audioLevel)
        
        recordingManager.$isRecording
            .assign(to: &$isRecording)
    }
    
    // MARK: - Room Management
    
    func startRoom(displayName: String, color: String) {
        print("[ChatViewModel] 🏠 Starting room")
        
        myParticipant = ChatParticipant(
            id: UUID().uuidString,
            displayName: displayName,
            colorHex: color
        )
        
        chatRoomService.startHost(myName: displayName, myColor: color)
        
        currentSession = ChatSession(
            title: "Chat Session",
            roster: [myParticipant!],
            turns: []
        )
        
        isInRoom = true
        showingJoinCodeInput = false
    }
    
    func joinRoom(displayName: String, color: String, joinCode: String?) {
        print("[ChatViewModel] 🚪 Joining room")
        print("[ChatViewModel] Name: \(displayName), Color: \(color), Join Code: \(joinCode ?? "none")")
        
        myParticipant = ChatParticipant(
            id: UUID().uuidString,
            displayName: displayName,
            colorHex: color
        )
        
        print("[ChatViewModel] Created participant with ID: \(myParticipant!.id)")
        
        chatRoomService.startParticipant(myName: displayName, myColor: color, optionalJoinCode: joinCode)
        
        currentSession = ChatSession(
            title: "Chat Session",
            roster: [myParticipant!],
            turns: []
        )
        
        isInRoom = true
        showingJoinCodeInput = false
        
        print("[ChatViewModel] ✅ Room joined, isInRoom: \(isInRoom)")
    }
    
    func leaveRoom() {
        print("[ChatViewModel] 👋 Leaving room")
        
        Task {
            if isRecording {
                _ = await recordingManager.stopRecording()
            }
        }
        
        chatRoomService.stop()
        
        currentSession = nil
        myParticipant = nil
        isInRoom = false
        turns.removeAll()
        participants.removeAll()
        partialText = ""
        isRecording = false
        isLocked = false
    }
    
    // MARK: - Recording
    
    func startRecording() async {
        guard !isRecording, myParticipant != nil else { return }
        
        print("[ChatViewModel] 🎤 Starting recording")
        
        await recordingManager.startRecording { [weak self] text in
            self?.partialText = text
        }
    }
    
    func stopRecording() async {
        guard isRecording, let participant = myParticipant else { return }
        
        print("[ChatViewModel] 🛑 Stopping recording")
        
        let result = await recordingManager.stopRecording()
        
        guard !result.finalText.isEmpty else {
            print("[ChatViewModel] ⚠️ Empty transcription")
            errorMessage = "Didn't catch that"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.errorMessage = nil
            }
            return
        }
        
        let turn = ChatTurn(
            speakerId: participant.id,
            displayName: participant.displayName,
            colorHex: participant.colorHex,
            text: result.finalText,
            startedAt: result.startTs,
            endedAt: result.endTs
        )
        
        chatRoomService.sendTurn(turn)
        isLocked = false
    }
    
    func toggleLock() {
        isLocked.toggle()
        print("[ChatViewModel] \(isLocked ? "🔒" : "🔓") Lock \(isLocked ? "engaged" : "released")")
    }
    
    // MARK: - Session Management
    
    func saveChat(discussionTopic: String, subject: String, teacher: String, period: String, term: String, termNumber: String, store: TranscriptStore) {
        guard var session = currentSession else { return }
        
        // Auto-generate title from discussion topic
        let autoTitle = discussionTopic.isEmpty ? "Chat Session" : discussionTopic
        
        print("[ChatViewModel] 💾 Saving chat: \(autoTitle)")
        
        session.title = autoTitle
        session.discussionTopic = discussionTopic
        session.subject = subject
        session.teacher = teacher
        session.period = period
        session.term = term
        session.termNumber = termNumber
        session.isOngoing = false
        
        store.add(chatSession: session)
    }
    
    func startDemo() {
        print("[ChatViewModel] 🎭 Starting demo")
        
        let demoParticipants = [
            ChatParticipant(id: "demo1", displayName: "Alice", colorHex: "FF6B6B"),
            ChatParticipant(id: "demo2", displayName: "Bob", colorHex: "4ECDC4"),
            ChatParticipant(id: "demo3", displayName: "Charlie", colorHex: "45B7D1")
        ]
        
        myParticipant = demoParticipants[0]
        participants = demoParticipants
        
        currentSession = ChatSession(
            title: "Demo Chat",
            roster: demoParticipants,
            turns: []
        )
        
        isInRoom = true
        isHost = true
        connectionStatus = "Demo Mode"
        joinCode = "DEMO"
        
        addDemoMessages()
    }
    
    private func addDemoMessages() {
        let messages = [
            ("Alice", "Hello everyone! How are you doing today?"),
            ("Bob", "I'm doing great! Thanks for asking."),
            ("Charlie", "Same here! Ready for our discussion?")
        ]
        
        for (index, (name, text)) in messages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 2) {
                guard let matchedParticipant = self.participants.first(where: { $0.displayName == name }) else { return }
                
                let turn = ChatTurn(
                    speakerId: matchedParticipant.id,
                    displayName: matchedParticipant.displayName,
                    colorHex: matchedParticipant.colorHex,
                    text: text,
                    startedAt: Date(),
                    endedAt: Date().addingTimeInterval(3)
                )
                self.addTurn(turn)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func addTurn(_ turn: ChatTurn) {
        turns.append(turn)
        
        if var session = currentSession {
            let participant = ChatParticipant(
                id: turn.speakerId,
                displayName: turn.displayName,
                colorHex: turn.colorHex
            )
            session.addParticipant(participant)
            session.addTurn(turn)
            currentSession = session
        }
        
        onNewMessage?()
    }
}
