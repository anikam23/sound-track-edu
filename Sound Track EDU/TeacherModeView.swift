import SwiftUI

struct TeacherModeView: View {
    enum Role: String, CaseIterable, Identifiable {
        case teacher = "Teacher"
        case student = "Student"
        var id: String { rawValue }
    }
    
    enum ViewState {
        case roleSelection
        case teacherSetup
        case teacherMode
        case studentMode
    }

    @EnvironmentObject var profileStore: ProfileStore        // Student profile (id, displayName, toggles)
    @EnvironmentObject var alertService: AlertSyncService    // Alert service for peer-to-peer communication
    @StateObject private var hudManager = AlertHUDManager()  // Shared HUD manager for banners

    @State private var currentViewState: ViewState = .roleSelection
    @State private var selectedRole: Role = .teacher

    // Teacher UI state
    @State private var teacherName: String = "Ms. Johnson"
    @State private var sendToAll: Bool = true
    @State private var selectedStudentId: String?
    @State private var optionalMessage: String = ""

    // Student UI state
    @State private var studentDisplayName: String = ""
    @State private var receiveAlerts: Bool = true
    @State private var autoStartOnImportant: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Full screen background
                Theme.beige
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    switch currentViewState {
                    case .roleSelection:
                        roleSelectionView
                    case .teacherSetup:
                        teacherSetupView
                    case .teacherMode:
                        teacherModeView
                    case .studentMode:
                        studentModeView
                    }
                }
            }
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if currentViewState == .teacherSetup || currentViewState == .studentMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            currentViewState = .roleSelection
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline)
                                Text("Back")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(Theme.accent)
                        }
                    }
                } else if currentViewState == .teacherMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            print("🔄 Manual refresh requested")
                            alertService.refreshConnections()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline)
                                Text("Refresh")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(Theme.accent)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            currentViewState = .teacherSetup
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline)
                                Text("Back")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Seed student fields from profile
            studentDisplayName = profileStore.profile.displayName
            receiveAlerts = profileStore.profile.receiveAlerts
            autoStartOnImportant = profileStore.profile.autoStartOnImportant
        }
        .onChange(of: receiveAlerts) { _, new in
            profileStore.updateReceiveAlerts(new)
        }
        .onChange(of: autoStartOnImportant) { _, new in
            profileStore.updateAutoStartOnImportant(new)
        }
        .alertBannerOverlay(hudManager)
        .onChange(of: alertService.lastReceivedAlert) { _, newAlert in
            if let alert = newAlert {
                // Show alert banner on teacher device too
                print("📨 Teacher received alert: \(alert.type.displayName)")
                hudManager.showAlert(alert)
            }
        }
    }

    // MARK: Views
    
    private var roleSelectionView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("I am a...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Choose your role to get started.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        selectedRole = .student
                        currentViewState = .studentMode
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.title2)
                            Text("Student")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(maxWidth: 600)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                    }
                    .contentShape(Rectangle())
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: selectedRole)
                    
                    Button(action: {
                        selectedRole = .teacher
                        currentViewState = .teacherSetup
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.rectangle.badge.plus")
                                .font(.title2)
                            Text("Teacher")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(maxWidth: 600)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                    }
                    .contentShape(Rectangle())
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: selectedRole)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var teacherSetupView: some View {
        VStack(spacing: 0) {
            // Teacher setup interface
            ScrollView {
                VStack(spacing: 16) {
                    // Teacher Setup Card
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Teacher Setup")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text("Enter your display name for students.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            TextField("Enter your name", text: $teacherName)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Theme.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                                        )
                                )
                                .textInputAutocapitalization(.words)
                        }
                        
                        Button {
                            if isTeacherStarted {
                                print("👨‍🏫 Stopping teacher mode")
                                alertService.stop()
                            } else {
                                print("👨‍🏫 Starting teacher mode")
                                print("👨‍🏫 Teacher name: \(teacherName)")
                                alertService.startTeacher(roleName: teacherName)
                                currentViewState = .teacherMode
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isTeacherStarted ? "stop.fill" : "person.wave.2.fill")
                                    .font(.title3)
                                Text(isTeacherStarted ? "Stop Teacher Mode" : "Start Teacher Mode")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.card)
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }
    
    private var teacherModeView: some View {
        VStack(spacing: 0) {
            // Status chip at top
            HStack {
                Circle().fill(statusDot).frame(width: 8, height: 8)
                Text(alertService.connectionStatus.contains("Teacher mode") ? "Listening for students" : alertService.connectionStatus)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.card)
                    .overlay(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Teacher interface - takes up most of the space
            ScrollView {
                VStack(spacing: 16) {
                    teacherInterface
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }
    
    private var studentModeView: some View {
        VStack(spacing: 0) {
            // Status chip
            HStack {
                Circle().fill(statusDot).frame(width: 8, height: 8)
                Text(alertService.connectionStatus.contains("Student mode") ? "Listening for alerts" : (alertService.connectionStatus.contains("Teacher mode") ? "Listening for students" : alertService.connectionStatus))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.card)
                    .overlay(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Student interface - takes up most of the space
            ScrollView {
                VStack(spacing: 16) {
                    studentInterface
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: Interfaces

    private var teacherInterface: some View {
        VStack(spacing: 16) {
            // Send Alert Card (main focus)
            sendAlertCard
            
            // Connected Students Card
            connectedStudentsCard
        }
    }

    private var connectedStudentsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Connected Students")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(alertService.connectedStudents.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Theme.accent)
                    )
            }
            
            if alertService.connectedStudents.isEmpty {
                Text("No students connected yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(alertService.connectedStudents) { student in
                        HStack(spacing: 12) {
                            // Monogram avatar
                            Text(student.name.prefix(1).uppercased())
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Theme.accent)
                                )
                            
                            Text(student.name)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.beige)
                        )
                    }
                }
                .animation(.snappy, value: alertService.connectedStudents)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private var sendAlertCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Send Alerts")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Recipient selection
            VStack(alignment: .leading, spacing: 12) {
                Picker("", selection: $sendToAll) {
                    Text("All Students").tag(true)
                    Text("Specific Student").tag(false)
                }
                .pickerStyle(.segmented)
            }

            if !sendToAll {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Student")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Picker("Student", selection: $selectedStudentId) {
                        ForEach(alertService.connectedStudents) { s in
                            Text(s.name).tag(Optional(s.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Message field (optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("Message (Optional)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                TextField("Add a message...", text: $optionalMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minHeight: 80, alignment: .top)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                    )
            }

            // Alert buttons
            VStack(spacing: 12) {
                Button {
                    print("🚨 Important Now button tapped")
                    print("🚨 Teacher name: \(teacherName)")
                    print("🚨 Send to all: \(sendToAll)")
                    print("🚨 Selected student: \(selectedStudentId ?? "none")")
                    print("🚨 Message: \(optionalMessage.isEmpty ? "none" : optionalMessage)")
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    let alert = TeacherAlert(
                        type: .importantNow,
                        teacherDisplayName: teacherName,
                        targetStudentId: sendToAll ? nil : selectedStudentId,
                        targetStudentName: nil,
                        message: optionalMessage.isEmpty ? nil : optionalMessage
                    )
                    alertService.send(alert, to: sendToAll ? nil : selectedStudentId)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title3)
                        Text("Send Important Alert")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(alertService.connectedStudents.isEmpty)

                Button {
                    print("📞 Call Student button tapped")
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    let alert = TeacherAlert(
                        type: .calledByName,
                        teacherDisplayName: teacherName,
                        targetStudentId: sendToAll ? nil : selectedStudentId,
                        targetStudentName: nil,
                        message: optionalMessage.isEmpty ? nil : optionalMessage
                    )
                    alertService.send(alert, to: sendToAll ? nil : selectedStudentId)
                } label: {
                    HStack {
                        Image(systemName: "person.wave.2")
                            .font(.title3)
                        Text("Call Student")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(alertService.connectedStudents.isEmpty)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private var understatedControlsCard: some View {
        HStack(spacing: 16) {
            Button {
                print("👨‍🏫 Stopping teacher mode")
                alertService.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2.weight(.semibold))
                    .accessibilityLabel("Stop Teacher Mode")
            }
            .buttonStyle(Theme.BorderedCapsuleStyle())
            
            Button {
                print("🔄 Manual refresh requested")
                alertService.refreshConnections()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title2.weight(.semibold))
                    .accessibilityLabel("Refresh Connections")
            }
            .buttonStyle(Theme.BorderedCapsuleStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    private var studentControlsCard: some View {
        HStack(spacing: 16) {
            Button {
                print("🎓 Stopping student mode")
                alertService.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2.weight(.semibold))
                    .accessibilityLabel("Stop Student Mode")
            }
            .buttonStyle(Theme.BorderedCapsuleStyle())
            
            Button {
                currentViewState = .roleSelection
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .accessibilityLabel("Back to Role Selection")
            }
            .buttonStyle(Theme.BorderedCapsuleStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var alertSendingInterface: some View {
        VStack(spacing: 24) {
            Text("Send Alerts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Recipient selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Recipients")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Picker("", selection: $sendToAll) {
                    Text("All Students").tag(true)
                    Text("Specific Student").tag(false)
                }
                .pickerStyle(.segmented)
            }

            if !sendToAll {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Student")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Picker("Student", selection: $selectedStudentId) {
                        ForEach(alertService.connectedStudents) { s in
                            Text(s.name).tag(Optional(s.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Alert buttons
            VStack(spacing: 16) {
                Button {
                    print("🚨 Important Now button tapped")
                    print("🚨 Teacher name: \(teacherName)")
                    print("🚨 Send to all: \(sendToAll)")
                    print("🚨 Selected student: \(selectedStudentId ?? "none")")
                    print("🚨 Message: \(optionalMessage.isEmpty ? "none" : optionalMessage)")
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    let alert = TeacherAlert(
                        type: .importantNow,
                        teacherDisplayName: teacherName,
                        targetStudentId: sendToAll ? nil : selectedStudentId,
                        targetStudentName: nil,
                        message: optionalMessage.isEmpty ? nil : optionalMessage
                    )
                    alertService.send(alert, to: sendToAll ? nil : selectedStudentId)
                } label: {
                    Label("Send Important Alert", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .controlSize(.large)

                Button {
                    print("📞 Call Student button tapped")
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    let alert = TeacherAlert(
                        type: .calledByName,
                        teacherDisplayName: teacherName,
                        targetStudentId: sendToAll ? nil : selectedStudentId,
                        targetStudentName: nil,
                        message: optionalMessage.isEmpty ? nil : optionalMessage
                    )
                    alertService.send(alert, to: sendToAll ? nil : selectedStudentId)
                } label: {
                    Label("Call Student", systemImage: "person.wave.2")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .controlSize(.large)
            }
        }
    }


    private var studentInterface: some View {
        VStack(spacing: 16) {
            // Student Setup Card
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Student Setup")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Enter your display name for teachers.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    TextField("Enter your name", text: $studentDisplayName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .textInputAutocapitalization(.words)
                        .onSubmit {
                            hideKeyboard()
                        }
                        .onChange(of: studentDisplayName) { _, new in profileStore.updateDisplayName(new) }
                }
                
                Button {
                    print("🎓 Student button tapped")
                    print("🎓 Current status: \(alertService.connectionStatus)")
                    print("🎓 Is student started: \(isStudentStarted)")
                    if isStudentStarted {
                        print("🎓 Stopping student mode")
                        alertService.stop()
                    } else {
                        print("🎓 Starting student mode")
                        print("🎓 Profile display name: \(profileStore.profile.displayName)")
                        print("🎓 Profile ID: \(profileStore.profile.id)")
                        alertService.startStudent(roleName: profileStore.profile.displayName,
                                                  studentId: profileStore.profile.id)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.and.waveform.fill")
                            .font(.title3)
                        Text(isStudentStarted ? "Stop Student Mode" : "Start Student Mode")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            )

            // Alert Settings Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Alert Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Receive teacher alerts")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $receiveAlerts)
                            .labelsHidden()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-start transcription on Important")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Text("Automatically start recording when receiving important alerts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $autoStartOnImportant)
                            .labelsHidden()
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            )
        }
    }

    // MARK: Computed Properties
    
    private var isTeacherStarted: Bool {
        alertService.connectionStatus.contains("Teacher mode")
    }
    
    private var isStudentStarted: Bool {
        alertService.connectionStatus.contains("Student mode")
    }

    // MARK: Helpers

    private var statusDot: Color {
        if alertService.connectionStatus.contains("connected") { return .green }
        if alertService.connectionStatus.contains("listening") { return .orange }
        return .gray
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
