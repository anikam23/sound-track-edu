import SwiftUI
import Combine

/// Manages the display and dismissal of alert banners
@MainActor
class AlertHUDManager: ObservableObject {
    @Published var currentAlert: TeacherAlert?
    @Published var isShowingBanner = false
    
    private var dismissTimer: Timer?
    
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
    
    /// Manually dismiss the current banner
    func dismissBanner() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        withAnimation(.easeOut(duration: 0.3)) {
            isShowingBanner = false
        }
        
        // Clear alert after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentAlert = nil
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
    }
}

extension View {
    /// Add alert banner overlay to any view
    func alertBannerOverlay(_ hudManager: AlertHUDManager) -> some View {
        self.modifier(AlertBannerOverlay(hudManager: hudManager))
    }
}
