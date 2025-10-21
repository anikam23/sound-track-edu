import SwiftUI
import Combine

/// Manages the display and dismissal of alert banners
@MainActor
class AlertHUDManager: ObservableObject {
    @Published var currentAlert: TeacherAlert?
    @Published var isShowingBanner = false
    @Published var showTranscriptionPrompt = false {
        didSet {
            print("🔔 [AlertHUD] showTranscriptionPrompt changed: \(oldValue) → \(showTranscriptionPrompt)")
        }
    }
    
    private var dismissTimer: Timer?
    private var isProcessingAlert = false
    private var lastAlertId: UUID?
    var onStartTranscription: (() async -> Void)?
    
    /// Show an alert banner for a specified duration
    func showAlert(_ alert: TeacherAlert, duration: TimeInterval = 4.0) {
        currentAlert = alert
        isShowingBanner = true
        
        // Auto-dismiss after duration
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task { @MainActor in
                self.dismissBanner()
            }
        }
    }
    
    /// Show alert and optionally prompt for transcription
    func showAlertWithTranscriptionPrompt(_ alert: TeacherAlert, isTranscribing: Bool) {
        print("🔔 [AlertHUD] Received alert: \(alert.type.displayName), ID: \(alert.id), isTranscribing: \(isTranscribing)")
        
        // Prevent duplicate processing of the same alert from multiple tabs
        if lastAlertId == alert.id {
            print("🔔 [AlertHUD] ⚠️ Already processing this alert ID, ignoring duplicate call")
            return
        }
        
        // Prevent overlapping calls
        if isProcessingAlert {
            print("🔔 [AlertHUD] ⚠️ Already processing an alert, ignoring new call")
            return
        }
        
        isProcessingAlert = true
        lastAlertId = alert.id
        
        print("🔔 [AlertHUD] ✅ Processing alert (first call for this ID)")
        
        // Clear any existing timers and banners first
        dismissTimer?.invalidate()
        dismissTimer = nil
        isShowingBanner = false
        
        // Store the alert but DON'T show banner yet if we're going to prompt
        currentAlert = alert
        
        // Only show prompt for Important alerts when not already transcribing
        if alert.type == .importantNow && !isTranscribing {
            print("🔔 [AlertHUD] Will show transcription prompt - NOT showing banner yet")
            print("🔔 [AlertHUD] Current showTranscriptionPrompt state: \(showTranscriptionPrompt)")
            
            // Don't reset to false - just set to true directly
            // The duplicate guards above prevent multiple calls
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🔔 [AlertHUD] Setting showTranscriptionPrompt = true now")
                self.showTranscriptionPrompt = true
                print("🔔 [AlertHUD] Dialog should now be visible")
                // Mark as no longer processing after showing prompt
                self.isProcessingAlert = false
            }
        } else {
            print("🔔 [AlertHUD] Showing banner only (type: \(alert.type.displayName), transcribing: \(isTranscribing))")
            // Just show the banner for other alerts
            isShowingBanner = true
            
            // Auto-dismiss after duration
            dismissTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                Task { @MainActor in
                    self.dismissBanner()
                }
            }
            isProcessingAlert = false
        }
    }
    
    /// User accepted transcription prompt
    func acceptTranscription() {
        print("🔔 [AlertHUD] User accepted transcription")
        showTranscriptionPrompt = false
        isProcessingAlert = false  // Reset processing flag
        
        // Start transcription
        Task {
            await onStartTranscription?()
        }
        
        // Wait a moment before showing banner to ensure dialog is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("🔔 [AlertHUD] Now showing alert banner")
            if let alert = self.currentAlert {
                self.showAlert(alert)
            }
        }
    }
    
    /// User declined transcription prompt
    func declineTranscription() {
        print("🔔 [AlertHUD] User declined transcription")
        showTranscriptionPrompt = false
        isProcessingAlert = false  // Reset processing flag
        
        // Wait a moment before showing banner to ensure dialog is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("🔔 [AlertHUD] Now showing alert banner")
            if let alert = self.currentAlert {
                self.showAlert(alert)
            }
        }
    }
    
    /// Manually dismiss the current banner
    func dismissBanner() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        withAnimation(.easeOut(duration: 0.3)) {
            isShowingBanner = false
        }
        
        // Clear alert after animation (but don't clear if we're about to show a prompt)
        if !showTranscriptionPrompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.currentAlert = nil
            }
        }
    }
    
    /// Test method to show a sample banner
    func showTestBanner() {
        let testAlert = TeacherAlert(
            type: .importantNow,
            teacherDisplayName: "Test Teacher",
            message: "This is a test alert banner"
        )
        showAlert(testAlert)
    }
}

/// View modifier that overlays alert banners on any view
struct AlertBannerOverlay: ViewModifier {
    @ObservedObject var hudManager: AlertHUDManager
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if hudManager.isShowingBanner, let alert = hudManager.currentAlert {
                AlertBannerView(alert: alert) {
                    hudManager.dismissBanner()
                }
                .zIndex(1000)
            }
        }
        .alert("Start Live Transcription?", isPresented: $hudManager.showTranscriptionPrompt) {
            Button("Yes") {
                hudManager.acceptTranscription()
            }
            Button("No", role: .cancel) {
                hudManager.declineTranscription()
            }
        } message: {
            if let alert = hudManager.currentAlert {
                Text("\(alert.teacherDisplayName) sent an important alert.\(alert.message.map { "\n\n\($0)" } ?? "")\n\nWould you like to start live transcription?")
            }
        }
    }
}

extension View {
    /// Add alert banner overlay to any view
    func alertBannerOverlay(_ hudManager: AlertHUDManager) -> some View {
        self.modifier(AlertBannerOverlay(hudManager: hudManager))
    }
}
