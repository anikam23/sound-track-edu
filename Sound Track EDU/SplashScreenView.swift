import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject private var transcriptStore: TranscriptStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var alertSyncService: AlertSyncService
    @EnvironmentObject private var liveTranscriber: LiveTranscriber
    @EnvironmentObject private var hudManager: AlertHUDManager
    
    @State private var logoVisible = false
    @State private var titleVisible = false
    @State private var taglineVisible = false
    @State private var loadingVisible = false
    @State private var showMainApp = false
    @State private var loadingProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            if showMainApp {
                ContentView()
                    .environmentObject(transcriptStore)
                    .environmentObject(profileStore)
                    .environmentObject(alertSyncService)
                    .environmentObject(liveTranscriber)
                    .environmentObject(hudManager)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                splashContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Step 1: Logo appears with scale-in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) {
            logoVisible = true
        }
        
        // Step 2: Title fades in
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            titleVisible = true
        }
        
        // Step 3: Tagline fades in
        withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
            taglineVisible = true
        }
        
        // Step 4: Loading indicator appears
        withAnimation(.easeOut(duration: 0.6).delay(1.3)) {
            loadingVisible = true
        }
        
        // Animate loading progress
        withAnimation(.easeInOut(duration: 1.5).delay(1.5)) {
            loadingProgress = 1.0
        }
        
        // Auto-dismiss after 2.8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.7)) {
                showMainApp = true
            }
        }
    }
    
    private var splashContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with radial gradient spotlight
                RadialGradient(
                    gradient: Gradient(colors: [
                        brandAccent,           // Lighter green at center (#2F7B6A)
                        brandDarkGreen,        // Primary dark green (#1C5C4D)
                        brandDarkGreen         // Darker at edges
                    ]),
                    center: .center,
                    startRadius: 50,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.7
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // App Icon - Using actual app tile image
                    Image("SplashIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: min(geometry.size.width * 0.5, 220), height: min(geometry.size.width * 0.5, 220))
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .scaleEffect(logoVisible ? 1.0 : 0.85)
                        .opacity(logoVisible ? 1.0 : 0.0)
                    
                    Spacer().frame(height: geometry.size.height * 0.08)
                    
                    // Welcome Messages
                    VStack(spacing: 0) {
                        // Title split across two lines
                        VStack(spacing: 4) {
                            Text("Welcome To")
                                .font(.system(size: min(geometry.size.width * 0.065, 30), weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Sound Track EDU")
                                .font(.system(size: min(geometry.size.width * 0.065, 30), weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .multilineTextAlignment(.center)
                        .opacity(titleVisible ? 1.0 : 0.0)
                        
                        Spacer().frame(height: 28)
                        
                        // Tagline - larger and distinct color
                        Text("Bringing Every Voice Into the Conversation")
                            .font(.system(size: min(geometry.size.width * 0.052, 22), weight: .semibold, design: .rounded))
                            .foregroundColor(taglineColor)
                            .multilineTextAlignment(.center)
                            .opacity(taglineVisible ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Professional loading indicator
                    VStack(spacing: 24) {
                        // Circular progress indicator
                        ZStack {
                            Circle()
                                .stroke(brandAccent.opacity(0.3), lineWidth: 3)
                                .frame(width: 44, height: 44)
                            
                            Circle()
                                .trim(from: 0, to: loadingProgress)
                                .stroke(
                                    LinearGradient(
                                        colors: [brandAccent, brandAccent.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))
                        }
                        
                        // Loading dots
                        HStack(spacing: 12) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(brandAccent)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(loadingVisible ? 1.0 : 0.3)
                                    .animation(
                                        .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                        value: loadingVisible
                                    )
                            }
                        }
                    }
                    .opacity(loadingVisible ? 1.0 : 0.0)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom + 70, 90))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Brand Colors
    
    private var brandDarkGreen: Color {
        Color(red: 0x1C / 255.0, green: 0x5C / 255.0, blue: 0x4D / 255.0) // #1C5C4D
    }
    
    private var brandAccent: Color {
        Color(red: 0x2F / 255.0, green: 0x7B / 255.0, blue: 0x6A / 255.0) // #2F7B6A
    }
    
    private var lightGray: Color {
        Color(red: 0xE5 / 255.0, green: 0xE5 / 255.0, blue: 0xE5 / 255.0) // #E5E5E5
    }
    
    private var taglineColor: Color {
        // Softer mint/teal to complement white title and stand out
        Color(red: 0x90 / 255.0, green: 0xE5 / 255.0, blue: 0xD5 / 255.0) // #90E5D5
    }
}

#Preview {
    SplashScreenView()
}
