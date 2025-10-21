import Foundation
import MultipeerConnectivity
import Combine
import UserNotifications
import UIKit
import AudioToolbox

/// A lightweight model for the teacher's UI list.
struct ConnectedStudent: Identifiable, Equatable {
    let id: String            // studentId
    let name: String          // student display name
    let peer: MCPeerID
}

/// Service for peer-to-peer alert messaging using MultipeerConnectivity.
@MainActor
class AlertSyncService: NSObject, ObservableObject {
    // Published state
    @Published var connectionStatus: String = "Disconnected"
    @Published var lastReceivedAlert: TeacherAlert?
    @Published var connectedStudents: [ConnectedStudent] = []

    // MPC
    private let serviceType = "stedu"
    private(set) var myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // We maintain a mapping of studentId <-> peer to target a single student
    private var studentIdToPeer: [String: MCPeerID] = [:]
    private var peerToStudentInfo: [MCPeerID: (id: String, name: String)] = [:]

    override init() {
        // Create a placeholder peer; we rebuild with the chosen display name in startTeacher/startStudent.
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
        updateConnectionStatus()
    }

    // MARK: Entry points (Teacher / Student)

    /// Start advertising & browsing as the **Teacher**. The teacher's visible name will be `roleName`.
    func startTeacher(roleName: String) {
        print("👨‍🏫 Starting teacher mode for: \(roleName)")
        print("👨‍🏫 Service type: \(serviceType)")
        print("👨‍🏫 My peer ID: \(myPeerID.displayName)")
        
        rebuildSession(withDisplayName: roleName)

        // Advertise as teacher
        let discoveryInfo = ["role": "teacher", "name": roleName]
        print("👨‍🏫 Discovery info: \(discoveryInfo)")
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        print("👨‍🏫 Starting advertiser...")
        advertiser?.startAdvertisingPeer()

        // Browse for students
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        print("👨‍🏫 Starting browser...")
        browser?.startBrowsingForPeers()

        updateConnectionStatus()
        print("👨‍🏫 ✅ Teacher mode started with status: \(connectionStatus)")
    }

    /// Start advertising as the **Student**. The student’s visible name will be `<displayName>-XXXX`.
    func startStudent(roleName: String, studentId: String) {
        print("🎓 Starting student mode for: \(roleName), ID: \(studentId)")
        let suffix = String(studentId.prefix(4)).uppercased()
        let visible = "\(roleName)-\(suffix)"
        print("🎓 Student visible name: \(visible)")
        rebuildSession(withDisplayName: visible)

        // Advertise as student with id + plain display name in discovery info
        let discoveryInfo = ["role": "student", "name": roleName, "studentId": studentId]
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        updateConnectionStatus()
    }

    /// Stop all networking.
    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        studentIdToPeer.removeAll()
        peerToStudentInfo.removeAll()
        connectedStudents.removeAll()
        updateConnectionStatus()
    }
    
    /// Force refresh student connections (useful when student changes name)
    func refreshConnections() {
        print("🔄 Refreshing student connections")
        if browser != nil {
            // Stop and restart browsing to discover updated student info
            browser?.stopBrowsingForPeers()
            browser?.startBrowsingForPeers()
            print("🔄 Restarted browsing for updated student connections")
        }
    }

    // MARK: Sending

    /// Send an alert. If `targetStudentId` is nil, broadcasts to all connected students.
    func send(_ alert: TeacherAlert, to targetStudentId: String?) {
        guard !session.connectedPeers.isEmpty else {
            print("❌ No connected peers to send alert to")
            return
        }

        print("📤 Sending alert: \(alert.type.displayName) to \(targetStudentId ?? "all")")
        print("📤 Connected peers: \(session.connectedPeers.map { $0.displayName })")
        print("📤 Student ID mapping: \(studentIdToPeer.keys)")

        do {
            let data = try JSONEncoder().encode(alert)
            if let id = targetStudentId, let target = studentIdToPeer[id] {
                print("📤 Sending to specific student: \(target.displayName)")
                try session.send(data, toPeers: [target], with: .reliable)
            } else {
                print("📤 Broadcasting to all peers")
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            }
            print("✅ Successfully sent alert: \(alert.type.displayName)")
        } catch {
            print("❌ Failed to send alert: \(error)")
        }
    }

    // MARK: Permissions

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print(granted ? "Notification permissions granted" : "Notification permissions denied")
            }
        }
    }

    // MARK: Internals

    private func rebuildSession(withDisplayName name: String) {
        print("🔄 Rebuilding session with display name: \(name)")
        
        // Tear down
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil

        // Reset mappings
        studentIdToPeer.removeAll()
        peerToStudentInfo.removeAll()
        connectedStudents.removeAll()

        // Recreate peer + session (peerID displayName is immutable)
        myPeerID = MCPeerID(displayName: name)
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        print("🔄 ✅ Session rebuilt successfully")
    }

    private func updateConnectionStatus() {
        if advertiser != nil && browser != nil {
            connectionStatus = connectedStudents.isEmpty
            ? "Teacher mode – listening for students"
            : "Teacher mode – \(connectedStudents.count) student(s) connected"
        } else if advertiser != nil {
            connectionStatus = "Student mode – listening for alerts"
        } else {
            connectionStatus = "Disconnected"
        }
    }

    private func handleReceivedAlert(_ alert: TeacherAlert) {
        lastReceivedAlert = alert
        triggerAlertFeedback(for: alert.type)
        scheduleBackgroundNotification(for: alert)
    }

    private func triggerAlertFeedback(for type: TeacherAlertType) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle = (type == .importantNow) ? .heavy : .medium
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        
        // Enhanced vibration pattern for better feedback
        if type == .importantNow {
            // Triple pulse for Important Now
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                generator.impactOccurred()
            }
        } else {
            // Double pulse for Call Student
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                generator.impactOccurred()
            }
        }
        
        let sound: SystemSoundID = (type == .importantNow) ? 1519 : 1520
        AudioServicesPlaySystemSound(sound)
        
        print("📳 Triggered \(style == .heavy ? "heavy" : "medium") haptic feedback with enhanced pattern")
    }

    private func scheduleBackgroundNotification(for alert: TeacherAlert) {
        guard UIApplication.shared.applicationState == .background else { return }
        let content = UNMutableNotificationContent()
        switch alert.type {
        case .importantNow:
            content.title = "Important Now"
            content.body = alert.message ?? "From \(alert.teacherDisplayName)"
        case .calledByName:
            content.title = "You were called"
            content.body = alert.message ?? "From \(alert.teacherDisplayName)"
        }
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "alertType": alert.type.rawValue,
            "teacherName": alert.teacherDisplayName,
            "alertId": alert.id.uuidString
        ]
        let req = UNNotificationRequest(identifier: alert.id.uuidString,
                                        content: content,
                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false))
        UNUserNotificationCenter.current().add(req) { if let e = $0 { print("Notif error: \(e)") } }
    }
}

// MARK: - MCSessionDelegate
extension AlertSyncService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                print("Connected to \(peerID.displayName)")
            case .connecting:
                print("Connecting to \(peerID.displayName)")
            case .notConnected:
                print("Disconnected from \(peerID.displayName)")
                // Remove from our maps if we had student info for this peer
                if let info = self.peerToStudentInfo.removeValue(forKey: peerID) {
                    self.studentIdToPeer.removeValue(forKey: info.id)
                }
                self.connectedStudents = self.peerToStudentInfo.map { ConnectedStudent(id: $0.value.id, name: $0.value.name, peer: $0.key) }
            @unknown default:
                break
            }
            self.updateConnectionStatus()
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("📨 Received data from \(peerID.displayName), size: \(data.count) bytes")
        Task { @MainActor in
            do {
                let alert = try JSONDecoder().decode(TeacherAlert.self, from: data)
                print("📨 Successfully decoded alert: \(alert.type.displayName) from \(alert.teacherDisplayName)")
                print("📨 Alert message: \(alert.message ?? "none")")
                self.handleReceivedAlert(alert)
            } catch {
                print("❌ Failed to decode received alert: \(error)")
                print("❌ Raw data: \(String(data: data, encoding: .utf8) ?? "invalid UTF-8")")
            }
        }
    }

    // Unused for this feature:
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension AlertSyncService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Accept all invites for this classroom use-case
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension AlertSyncService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName), role: \(info?["role"] ?? "unknown")")

        // We only invite students (teacher devices will ignore our invites)
        if info?["role"] == "student",
           let studentId = info?["studentId"], !studentId.isEmpty {
            let name = info?["name"] ?? peerID.displayName
            
            // Handle student connections (including name changes)
            Task { @MainActor in
                // Check if this student ID is already connected with a different peer
                if let existingPeer = self.studentIdToPeer[studentId], existingPeer != peerID {
                    print("📡 Student \(studentId) reconnected with new name: \(name)")
                    // Remove old peer connection
                    if let oldInfo = self.peerToStudentInfo.removeValue(forKey: existingPeer) {
                        print("📡 Removed old connection for \(oldInfo.name)")
                    }
                }
                
                // Only add if not already connected with this exact peer
                if self.studentIdToPeer[studentId] != peerID {
                    print("📡 Inviting student: \(name) (ID: \(studentId))")
                    self.studentIdToPeer[studentId] = peerID
                    self.peerToStudentInfo[peerID] = (id: studentId, name: name)
                    self.connectedStudents = self.peerToStudentInfo.map { ConnectedStudent(id: $0.value.id, name: $0.value.name, peer: $0.key) }
                    self.updateConnectionStatus()
                    
                    // Send invitation
                    browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 30)
                } else {
                    print("📡 Student \(name) already connected with this peer, skipping invitation")
                }
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
        Task { @MainActor in
            if let info = self.peerToStudentInfo.removeValue(forKey: peerID) {
                self.studentIdToPeer.removeValue(forKey: info.id)
                self.connectedStudents = self.peerToStudentInfo.map { ConnectedStudent(id: $0.value.id, name: $0.value.name, peer: $0.key) }
                self.updateConnectionStatus()
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error)")
    }
}
