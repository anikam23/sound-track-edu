import Foundation
import MultipeerConnectivity

/// Service for peer-to-peer chat room using MultipeerConnectivity
@MainActor
class ChatRoomService: NSObject, ObservableObject {
    @Published var peers: [ChatParticipant] = []
    @Published var connectionStatus: String = "Disconnected"
    @Published var joinCode: String = ""
    @Published var isHost: Bool = false
    
    var onTurnReceived: ((ChatTurn) -> Void)?
    
    private let serviceType = "stedu-chat"
    private var myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private var myParticipant: ChatParticipant?
    private var participantMap: [MCPeerID: ChatParticipant] = [:]
    private var hasSentParticipantInfo = false
    
    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
        print("[ChatRoom] 🔧 ChatRoomService initialized")
        print("[ChatRoom] Device name: \(UIDevice.current.name)")
        print("[ChatRoom] Service type: \(serviceType)")
    }
    
    // MARK: - Room Management
    
    func startHost(myName: String, myColor: String) {
        print("[ChatRoom] 🏠 Starting host mode")
        print("[ChatRoom] Name: \(myName), Color: \(myColor)")
        
        joinCode = generateJoinCode()
        isHost = true
        
        myParticipant = ChatParticipant(id: myPeerID.displayName, displayName: myName, colorHex: myColor)
        
        rebuildSession(withDisplayName: myName)
        
        let discoveryInfo = [
            "role": "host",
            "joinCode": joinCode,
            "displayName": myName,
            "colorHex": myColor
        ]
        
        print("[ChatRoom] Join Code: \(joinCode)")
        print("[ChatRoom] Discovery Info: \(discoveryInfo)")
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        print("[ChatRoom] Starting advertiser for service type: \(serviceType)")
        advertiser?.startAdvertisingPeer()
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        print("[ChatRoom] Starting browser for service type: \(serviceType)")
        browser?.startBrowsingForPeers()
        
        if let participant = myParticipant {
            peers = [participant]
        }
        
        updateConnectionStatus()
        print("[ChatRoom] ✅ Host mode started, advertising with join code: \(joinCode)")
    }
    
    func startParticipant(myName: String, myColor: String, optionalJoinCode: String?) {
        print("[ChatRoom] 🚪 Starting participant mode")
        print("[ChatRoom] Name: \(myName), Color: \(myColor), Join Code: \(optionalJoinCode ?? "none")")
        
        isHost = false
        joinCode = optionalJoinCode ?? ""
        
        myParticipant = ChatParticipant(id: myPeerID.displayName, displayName: myName, colorHex: myColor)
        
        rebuildSession(withDisplayName: myName)
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        print("[ChatRoom] Starting browser for service type: \(serviceType)")
        browser?.startBrowsingForPeers()
        
        if let participant = myParticipant {
            peers = [participant]
        }
        
        updateConnectionStatus()
        print("[ChatRoom] ✅ Participant mode started, browsing for hosts...")
    }
    
    func stop() {
        print("[ChatRoom] 🛑 Stopping room")
        
        // Stop advertising and browsing
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        
        // Disconnect the session
        session.disconnect()
        
        // Clear all references
        advertiser = nil
        browser = nil
        peers.removeAll()
        participantMap.removeAll()
        myParticipant = nil
        joinCode = ""
        isHost = false
        hasSentParticipantInfo = false
        
        updateConnectionStatus()
        print("[ChatRoom] ✅ Room stopped completely")
    }
    
    // MARK: - Messaging
    
    func sendTurn(_ turn: ChatTurn) {
        print("[ChatRoom] 📤 Sending turn from \(turn.displayName)")
        
        do {
            let data = try JSONEncoder().encode(turn)
            
            if !session.connectedPeers.isEmpty {
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                print("[ChatRoom] ✅ Sent to \(session.connectedPeers.count) peer(s)")
            }
            
            // Also handle locally
            onTurnReceived?(turn)
            
        } catch {
            print("[ChatRoom] ❌ Failed to send turn: \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func generateJoinCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<4).map { _ in characters.randomElement()! })
    }
    
    private func rebuildSession(withDisplayName name: String) {
        // Stop current services
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        
        // Disconnect current session
        session.disconnect()
        
        // Clear references
        advertiser = nil
        browser = nil
        peers.removeAll()
        participantMap.removeAll()
        hasSentParticipantInfo = false
        
        // Create new session
        myPeerID = MCPeerID(displayName: name)
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        print("[ChatRoom] 🔄 Session rebuilt with display name: \(name)")
    }
    
    private func updateConnectionStatus() {
        if isHost {
            connectionStatus = peers.count <= 1 ? "Host - waiting for participants" : "Host - \(peers.count - 1) participant(s)"
        } else {
            connectionStatus = peers.count <= 1 ? "Connecting..." : "Connected to room"
        }
    }
}

// MARK: - MCSessionDelegate

extension ChatRoomService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                print("[ChatRoom] ✅ Connected to \(peerID.displayName)")
                if let participant = myParticipant {
                    sendParticipantInfo(participant, to: peerID)
                }
            case .connecting:
                print("[ChatRoom] 🔄 Connecting to \(peerID.displayName)")
            case .notConnected:
                print("[ChatRoom] ❌ Disconnected from \(peerID.displayName)")
                if let participant = participantMap.removeValue(forKey: peerID) {
                    peers.removeAll { $0.id == participant.id }
                    updateConnectionStatus()
                }
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            if let turn = try? JSONDecoder().decode(ChatTurn.self, from: data) {
                print("[ChatRoom] 📨 Received turn from \(turn.displayName)")
                onTurnReceived?(turn)
            } else if let participant = try? JSONDecoder().decode(ChatParticipant.self, from: data) {
                handleReceivedParticipantInfo(participant, from: peerID)
            }
        }
    }
    
    private func handleReceivedParticipantInfo(_ participant: ChatParticipant, from peerID: MCPeerID) {
        print("[ChatRoom] 👤 Received participant info: \(participant.displayName)")
        
        participantMap[peerID] = participant
        
        if !peers.contains(where: { $0.id == participant.id }) {
            peers.append(participant)
            updateConnectionStatus()
            
            // Only send our participant info once to prevent infinite loop
            if let myParticipant = myParticipant, !hasSentParticipantInfo {
                sendParticipantInfo(myParticipant, to: peerID)
                hasSentParticipantInfo = true
            }
        }
    }
    
    private func sendParticipantInfo(_ participant: ChatParticipant, to peerID: MCPeerID) {
        do {
            let data = try JSONEncoder().encode(participant)
            try session.send(data, toPeers: [peerID], with: .reliable)
            print("[ChatRoom] 📤 Sent participant info to \(peerID.displayName)")
        } catch {
            print("[ChatRoom] ❌ Failed to send participant info: \(error)")
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension ChatRoomService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[ChatRoom] 📨 Received invitation from \(peerID.displayName)")
        Task { @MainActor in
            print("[ChatRoom] ✅ Accepting invitation")
            invitationHandler(true, self.session)
        }
    }
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[ChatRoom] ❌ Advertiser failed to start: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension ChatRoomService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("[ChatRoom] 🔍 Found peer: \(peerID.displayName)")
        print("[ChatRoom] Discovery info: \(String(describing: info))")
        
        Task { @MainActor in
            print("[ChatRoom] isHost: \(self.isHost), myJoinCode: \(self.joinCode)")
            
            if !self.isHost {
                // Participant looking for host
                if let peerRole = info?["role"], peerRole == "host" {
                    if let peerJoinCode = info?["joinCode"] {
                        print("[ChatRoom] Found host with join code: \(peerJoinCode)")
                        
                        if self.joinCode.isEmpty || peerJoinCode == self.joinCode {
                            print("[ChatRoom] 🚪 Join code matches! Inviting to host")
                            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 30)
                        } else {
                            print("[ChatRoom] ❌ Join code mismatch. Expected: \(self.joinCode), got: \(peerJoinCode)")
                        }
                    } else {
                        print("[ChatRoom] ⚠️ Host found but no join code in discovery info")
                    }
                } else {
                    print("[ChatRoom] ⚠️ Peer is not a host")
                }
            } else {
                // Host accepting participants
                print("[ChatRoom] 🏠 Inviting participant to room")
                browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 30)
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("[ChatRoom] 👋 Lost peer: \(peerID.displayName)")
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("[ChatRoom] ❌ Browser failed to start: \(error.localizedDescription)")
    }
}
