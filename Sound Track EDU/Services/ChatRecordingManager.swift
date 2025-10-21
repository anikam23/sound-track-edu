import Foundation
import AVFoundation
import Speech

/// Recording manager for chat with partial results support
@MainActor
class ChatRecordingManager: ObservableObject {
    @Published var isRecording = false
    @Published var partialText = ""
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String?
    
    var partialsHandler: ((String) -> Void)?
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.current.identifier))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var recordingStartTime: Date?
    private var levelTimer: Timer?
    
    // MARK: - Public API
    
    func startRecording(partialsHandler: @escaping (String) -> Void) async {
        guard !isRecording else { return }
        
        print("[ChatRecording] 🎤 Starting recording")
        
        guard await requestPermissions() else {
            errorMessage = "Microphone permission required"
            return
        }
        
        self.partialsHandler = partialsHandler
        recordingStartTime = Date()
        partialText = ""
        isRecording = true
        
        await startSpeechRecognition()
        startAudioLevelMonitoring()
    }
    
    func stopRecording() async -> (finalText: String, startTs: Date, endTs: Date) {
        print("[ChatRecording] 🛑 Stopping recording")
        
        let startTime = recordingStartTime ?? Date()
        let endTime = Date()
        let finalText = partialText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        stopSpeechRecognition()
        stopAudioLevelMonitoring()
        
        isRecording = false
        partialsHandler = nil
        
        return (finalText, startTime, endTime)
    }
    
    // MARK: - Private Methods
    
    private func requestPermissions() async -> Bool {
        let micPermission = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
            }
        }
        
        let speechPermission = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        return micPermission && speechPermission
    }
    
    private func startSpeechRecognition() async {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self?.partialText = text
                    self?.partialsHandler?(text)
                }
                
                if let error = error, self?.isRecording == true {
                    print("[ChatRecording] ⚠️ Recognition error: \(error)")
                }
            }
        }
    }
    
    private func stopSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    private func startAudioLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevel()
            }
        }
    }
    
    private func stopAudioLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }
    
    private func updateAudioLevel() {
        // Simple approximation based on recording state
        if isRecording {
            audioLevel = Float.random(in: 0.3...0.8)
        } else {
            audioLevel = 0
        }
    }
}
