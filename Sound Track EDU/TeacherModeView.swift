import SwiftUI

struct TeacherModeView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var alertService: AlertSyncService
    @EnvironmentObject var transcriber: LiveTranscriber
    @EnvironmentObject var hudManager: AlertHUDManager
    
    @State private var showTeacherSetup = false
    @State private var showTeacherMode = false
    @State private var showStudentMode = false
    
    @State private var teacherName: String = "Ms. Johnson"
    @State private var studentDisplayName: String = ""
    @State private var receiveAlerts: Bool = true
    @State private var autoStartOnImportant: Bool = false
    @State private var sendToAll: Bool = true
    @State private var selectedStudentId: String?
    @State private var optionalMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.beige.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 32) {
                        VStack(spacing: 8) {
                            Text("I am a...")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Choose your role to get started.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 16) {
                            Button {
                                showStudentMode = true
                            } label: {
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
                            .buttonStyle(.plain)
                            
                            Button {
                                showTeacherSetup = true
                            } label: {
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
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Alerts")
            .navigationDestination(isPresented: $showTeacherSetup) {
                TeacherSetupScreen(
                    teacherName: $teacherName,
                    showTeacherMode: $showTeacherMode
                )
                .environmentObject(alertService)
            }
            .navigationDestination(isPresented: $showTeacherMode) {
                TeacherModeScreen(
                    teacherName: teacherName,
                    sendToAll: $sendToAll,
                    selectedStudentId: $selectedStudentId,
                    optionalMessage: $optionalMessage
                )
                .environmentObject(alertService)
            }
            .navigationDestination(isPresented: $showStudentMode) {
                StudentModeScreen(
                    studentDisplayName: $studentDisplayName,
                    receiveAlerts: $receiveAlerts,
                    autoStartOnImportant: $autoStartOnImportant
                )
                .environmentObject(profileStore)
                .environmentObject(alertService)
            }
        }
        .onAppear {
            studentDisplayName = profileStore.profile.displayName
            receiveAlerts = profileStore.profile.receiveAlerts
            autoStartOnImportant = profileStore.profile.autoStartOnImportant
        }
    }
}

// MARK: - Teacher Setup Screen
struct TeacherSetupScreen: View {
    @EnvironmentObject var alertService: AlertSyncService
    @Binding var teacherName: String
    @Binding var showTeacherMode: Bool
    
    var body: some View {
        ZStack {
            Theme.beige.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Teacher Setup")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text("Enter your display name for students.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
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
                            if alertService.connectionStatus.contains("Teacher mode") {
                                alertService.stop()
                            } else {
                                alertService.startTeacher(roleName: teacherName)
                                showTeacherMode = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: alertService.connectionStatus.contains("Teacher mode") ? "stop.fill" : "person.wave.2.fill")
                                    .font(.title3)
                                Text(alertService.connectionStatus.contains("Teacher mode") ? "Stop Teacher Mode" : "Start Teacher Mode")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(teacherName.isEmpty)
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
        .navigationTitle("Teacher")
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnTap()
    }
}

// MARK: - Teacher Mode Screen
struct TeacherModeScreen: View {
    @EnvironmentObject var alertService: AlertSyncService
    let teacherName: String
    @Binding var sendToAll: Bool
    @Binding var selectedStudentId: String?
    @Binding var optionalMessage: String
    
    var body: some View {
        ZStack {
            Theme.beige.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status chip
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Send Alert Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Send Alerts")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Picker("", selection: $sendToAll) {
                                Text("All Students").tag(true)
                                Text("Specific Student").tag(false)
                            }
                            .pickerStyle(.segmented)
                            
                            if !sendToAll {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Select Student")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    
                                    Picker("Student", selection: $selectedStudentId) {
                                        ForEach(alertService.connectedStudents) { s in
                                            Text(s.name).tag(Optional(s.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Message (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
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
                            
                            VStack(spacing: 12) {
                                Button {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                    impactFeedback.impactOccurred()
                                    
                                    let alert = TeacherAlert(
                                        type: .importantNow,
                                        teacherDisplayName: teacherName,
                                        targetStudentId: sendToAll ? nil : selectedStudentId,
                                        targetStudentName: nil,
                                        message: optionalMessage.isEmpty ? nil : optionalMessage
                                    )
                                    alertService.send(alert, to: sendToAll ? nil : selectedStudentId)
                                    optionalMessage = ""
                                } label: {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
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
                                    optionalMessage = ""
                                } label: {
                                    HStack {
                                        Image(systemName: "person.wave.2.fill")
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
                        
                        // Connected Students Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Connected Students")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Text("\(alertService.connectedStudents.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Theme.accent))
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
                                            Text(student.name.prefix(1).uppercased())
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Circle().fill(Theme.accent))
                                            
                                            Text(student.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            
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
        .navigationTitle("Teacher Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    alertService.refreshConnections()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
    
    private var statusDot: Color {
        if alertService.connectionStatus.contains("connected") { return .green }
        if alertService.connectionStatus.contains("listening") { return .orange }
        return .gray
    }
}

// MARK: - Student Mode Screen
struct StudentModeScreen: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var alertService: AlertSyncService
    @Binding var studentDisplayName: String
    @Binding var receiveAlerts: Bool
    @Binding var autoStartOnImportant: Bool
    
    var body: some View {
        ZStack {
            Theme.beige.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status chip
                HStack {
                    Circle().fill(statusDot).frame(width: 8, height: 8)
                    Text(alertService.connectionStatus.contains("Student mode") ? "Listening for alerts" : alertService.connectionStatus)
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Student Setup Card
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Student Setup")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Text("Enter your display name for teachers.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Name")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
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
                                    .onChange(of: studentDisplayName) { _, new in
                                        profileStore.updateDisplayName(new)
                                    }
                            }
                            
                            Button {
                                if alertService.connectionStatus.contains("Student mode") {
                                    alertService.stop()
                                } else {
                                    alertService.startStudent(
                                        roleName: profileStore.profile.displayName,
                                        studentId: profileStore.profile.id
                                    )
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.and.waveform.fill")
                                        .font(.title3)
                                    Text(alertService.connectionStatus.contains("Student mode") ? "Stop Student Mode" : "Start Student Mode")
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
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Receive teacher alerts")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $receiveAlerts)
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Auto-start transcription on Important")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Student Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: receiveAlerts) { _, new in
            profileStore.updateReceiveAlerts(new)
        }
        .onChange(of: autoStartOnImportant) { _, new in
            profileStore.updateAutoStartOnImportant(new)
        }
        .dismissKeyboardOnTap()
    }
    
    private var statusDot: Color {
        if alertService.connectionStatus.contains("connected") { return .green }
        if alertService.connectionStatus.contains("listening") { return .orange }
        return .gray
    }
}
