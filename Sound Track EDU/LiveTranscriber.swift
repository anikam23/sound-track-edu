import Foundation
import AVFoundation
import Speech

/// Drives live speech → text with Start / Pause / Resume / End.
@MainActor
final class LiveTranscriber: ObservableObject {

    // MARK: Published UI state
    @Published var text: String = ""
    @Published var status: String = "Idle"
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false

    /// Simple UI mode used by the view for button titles/colors.
    enum UIMode { case idle, listening, paused, stopped }
    var uiMode: UIMode {
        if isRecording { return isPaused ? .paused : .listening }
        return status == "Stopped" ? .stopped : .idle
    }

    // Keep the cumulative text from all previous segments.
    private var baseText: String = ""

    // MARK: Speech engine
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.current.identifier))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: Permissions
    func requestPermissions() async -> Bool {
        let micOK: Bool = await withCheckedContinuation { cont in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
            }
        }

        let speechOK: Bool = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { auth in
                cont.resume(returning: auth == .authorized)
            }
        }

        return micOK && speechOK
    }

    // MARK: State machine
    func start() async {
        guard !isRecording else { return }
        if !(await requestPermissions()) {
            status = "Permissions required"
            return
        }
        // Starting a *new* session (fresh transcript)
        baseText = ""
        text = ""
        isPaused = false
        isRecording = true
        status = "Listening…"
        startRecognition()
    }

    func pause() {
        guard isRecording && !isPaused else { return }
   
        // Preserve everything heard so far before stopping the engine
        baseText = text
        isPaused = true
        status = "Paused"

        stopRecognition()
    }

    func resume() {
        guard isRecording && isPaused else { return }
        status = "Listening…"
        isPaused = false
        startRecognition()
    }

    /// Stop engines, clear flags. Does **not** clear text.
    func stop() {
        guard isRecording else { return }
        baseText = text
        stopRecognition()
        isRecording = false
        isPaused = false
        status = "Stopped"
    }

    /// Helper for callers that used earlier name.
    func end() { stop() }

    func resetAll() {
        stopRecognition()
        text = ""
        baseText = ""
        isRecording = false
        isPaused = false
        status = "Idle"
    }

    // MARK: Recognition wiring
    private func startRecognition() {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        // Install input tap
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
            status = "Audio error"
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self else { return }

            if let result = result {
                // Text for the *current* recognition run only:
                let currentRun = result.bestTranscription.formattedString
                let combined = (self.baseText.isEmpty ? "" : self.baseText + "\n") + currentRun

                // Avoid redundant assigns; helps prevent flicker and accidental dupes.
                if self.text != combined {
                    self.text = combined
                }
                // NOTE: Do NOT mutate `baseText` here. We fold it only on pause/stop.
            }

            if let error = error {
                // Only surface errors during active listening; ignore expected cancels on pause/stop.
                if self.isRecording && !self.isPaused {
                    self.status = "Recognition error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func stopRecognition() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        recognitionTask?.cancel()
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
