import SwiftUI

struct LiveTabView: View {
    @EnvironmentObject private var store: TranscriptStore
    @EnvironmentObject private var alertSync: AlertSyncService
    @EnvironmentObject private var transcriber: LiveTranscriber
    @EnvironmentObject private var hudManager: AlertHUDManager

    @State private var showSaveSheet = false
    @State private var followLatest = true
    @State private var jumpToken = false
    private let bottomID = "LIVE_BOTTOM_ANCHOR"

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 10) {
                    transcriptScroller
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Floating “jump to latest” button (only when user scrolled up)
                if !followLatest {
                    Button {
                        withAnimation(.easeOut) { jumpToken.toggle() }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(.secondary.opacity(0.2), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 72)      // sits above the bottom controls
                    .accessibilityLabel("Scroll to latest")
                    .onChange(of: jumpToken) {
                        followLatest = true
                    }
                }
            }
            .background(Theme.beige.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { controlsBar }
            .sheet(isPresented: $showSaveSheet) {
                SaveTranscriptSheet(
                    titleDefault: defaultSuggestedTitle()
                ) { title, subject, teacher, period, term, termNumber in
                    let record = TranscriptRecord(
                        id: UUID(),
                        createdAt: Date(),
                        title: title,
                        text: transcriber.text,
                        period: period,
                        subject: subject,
                        teacher: teacher,
                        term: term,
                        termNumber: termNumber
                    )
                    store.add(record: record)
                    transcriber.resetAll()
                }
                .presentationDetents([.medium])
            }
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.large)
        }
        .tint(Theme.accent)
        .task { _ = await transcriber.requestPermissions() }
    }

    // MARK: - Transcript / Empty state

    private var transcriptScroller: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Welcome panel — only when there’s nothing yet and we’re in Idle/Stopped.
                    if transcriber.text.isEmpty && (transcriber.uiMode == .idle || transcriber.uiMode == .stopped) {
                        emptyState
                            .padding(.top, 24)
                    }

                    // Transcript bubble (shows “…waiting…” if empty; keeps layout stable)
                    Text(transcriber.text.isEmpty ? "…waiting…" : transcriber.text)
                        .font(.title3)
                        .foregroundStyle(Theme.primaryText)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                        .id(bottomID)
                }
                .padding(.vertical, 6)
            }
            // Let ScrollView do its own thing; we only observe the drag to disable auto-follow.
            .simultaneousGesture(
                DragGesture(minimumDistance: 1).onChanged { value in
                    if abs(value.translation.height) > 0 {
                        followLatest = false
                    }
                }
            )
            // New text: auto-scroll only when following.
            .onChange(of: transcriber.text) {
                if followLatest {
                    withAnimation(.easeOut) { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
            }
            // Jump button tapped.
            .onChange(of: jumpToken) {
                withAnimation(.easeOut) { proxy.scrollTo(bottomID, anchor: .bottom) }
            }
        }
    }

    /// Friendly “ready” panel (no placeholder chips).
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            Text("Ready to transcribe?")
                .font(.title2).bold()
                .foregroundStyle(Theme.primaryText)
            Text("Tap Start and I’ll caption what I hear in real time.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom controls (icon-only)

    private var controlsBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle().fill(statusDotColor).frame(width: 8, height: 8)
                Text(transcriber.status)
                    .font(.subheadline)
                    .foregroundStyle(Theme.primaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.accent.opacity(0.12), in: Capsule())

            Spacer(minLength: 4)

            Button { Task { await tappedPrimary() } } label: {
                Image(systemName: primaryButtonIcon)
                    .font(.title2.weight(.semibold))
                    .accessibilityLabel(primaryButtonA11yLabel)
            }
            .buttonStyle(Theme.FilledButtonStyle())

            Button { endSessionTapped() } label: {
                Image(systemName: "stop.fill")
                    .font(.title2.weight(.semibold))
                    .accessibilityLabel("End")
            }
            .buttonStyle(Theme.BorderedCapsuleStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func tappedPrimary() async {
        switch transcriber.uiMode {
        case .idle, .stopped: await transcriber.start()
        case .listening:      transcriber.pause()
        case .paused:         transcriber.resume()
        }
    }

    private func endSessionTapped() {
        transcriber.stop()
        showSaveSheet = true
    }

    // MARK: - Helpers

    private func defaultSuggestedTitle() -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: Date())
    }

    private var statusDotColor: Color {
        switch transcriber.uiMode {
        case .listening: return .green
        case .paused:    return .orange
        case .idle, .stopped: return .gray
        }
    }

    private var primaryButtonIcon: String {
        switch transcriber.uiMode {
        case .idle, .stopped: return "play.fill"
        case .listening:      return "pause.fill"
        case .paused:         return "play.fill"
        }
    }

    private var primaryButtonA11yLabel: String {
        switch transcriber.uiMode {
        case .idle, .stopped: return "Start"
        case .listening:      return "Pause"
        case .paused:         return "Resume"
        }
    }
}
