# Chat Connection Troubleshooting

## ✅ **CRITICAL FIX APPLIED**

**The main issue was found and fixed!** The Info.plist had the wrong service type:
- ❌ **Was**: `_stedu._tcp` 
- ✅ **Now**: `_stedu-chat._tcp` (matches the app code)

Also added required `NSLocalNetworkUsageDescription`.

## Enhanced Logging Added

The chat service now includes detailed logging for debugging connection issues. Look for these log prefixes:

- `[ChatRoom]` - All MultipeerConnectivity activity
- `[ChatViewModel]` - Room joining/leaving activity

## Expected Log Flow

### Phone 1 (Host - "A"):
```
[ChatViewModel] 🏠 Starting room
[ChatViewModel] Name: A, Color: FF6B6B
[ChatRoom] 🏠 Starting host mode
[ChatRoom] Name: A, Color: FF6B6B
[ChatRoom] Join Code: XXXX
[ChatRoom] Discovery Info: ["role": "host", "joinCode": "XXXX", ...]
[ChatRoom] Starting advertiser for service type: stedu-chat
[ChatRoom] Starting browser for service type: stedu-chat
[ChatRoom] ✅ Host mode started, advertising with join code: XXXX
```

### Phone 2 (Participant - "Manasi"):
```
[ChatViewModel] 🚪 Joining room
[ChatViewModel] Name: Manasi, Color: 4ECDC4, Join Code: XXXX
[ChatViewModel] Created participant with ID: ...
[ChatRoom] 🚪 Starting participant mode
[ChatRoom] Name: Manasi, Color: 4ECDC4, Join Code: XXXX
[ChatRoom] Starting browser for service type: stedu-chat
[ChatRoom] ✅ Participant mode started, browsing for hosts...
[ChatRoom] 🔍 Found peer: A
[ChatRoom] Discovery info: ["role": "host", "joinCode": "XXXX", ...]
[ChatRoom] isHost: false, myJoinCode: XXXX
[ChatRoom] Found host with join code: XXXX
[ChatRoom] 🚪 Join code matches! Inviting to host
[ChatRoom] ✅ Connected to A
```

## If No Logs Appear

If you see NO `[ChatRoom]` logs at all on phone 2 after pressing "Join", check:

### 1. Required Info.plist Keys

Add these to `Sound-Track-EDU-Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses the local network to connect with other devices for classroom chat.</string>

<key>NSBonjourServices</key>
<array>
    <string>_stedu-chat._tcp</string>
</array>
```

### 2. Network Requirements

- Both devices must be on the **same Wi-Fi network** OR have **Bluetooth enabled**
- MultipeerConnectivity works over:
  - Wi-Fi Direct (same network)
  - Bluetooth LE (within range)
  - Infrastructure Wi-Fi (same subnet)

### 3. Device Requirements

- **Not in airplane mode**
- **Wi-Fi enabled** (even if not connected to network)
- **Bluetooth enabled** (recommended)
- **iOS 13+**

### 4. Xcode Build Settings

Ensure the app has the entitlement:
- **Bonjour services**: `_stedu-chat._tcp`

## Testing Steps

1. **Phone 1 (Host)**:
   - Open Chat tab
   - Enter name "A"
   - Select a color
   - Tap "Start Room"
   - **Note the join code** (e.g., "K7LM")
   - Watch for "Host mode started" logs

2. **Phone 2 (Participant)**:
   - Open Chat tab
   - Enter name "Manasi"
   - Select a color  
   - Tap "Join Room"
   - **Enter the exact join code** from Phone 1
   - Tap "Join"
   - Watch for "Found peer" logs

3. **Expected Behavior**:
   - Phone 2 should show "Connected to room" within 5-10 seconds
   - Phone 1 should show "1 participant(s)" connected
   - Both should show both participants in the roster pills

## Alternative: Test Without Join Code

On Phone 2, leave the join code field **empty** and just tap "Join". This will connect to any host on the network.

## Still Not Working?

If you see the logs but no connection:
- Check firewall settings (disable temporarily)
- Restart both devices
- Make sure both apps are in foreground
- Try toggling Wi-Fi/Bluetooth off and on

## Demo Mode

To test UI without two devices:
1. Set Xcode scheme environment variable: `SHOW_DEMO=true`
2. Restart app
3. Tap the "Demo" button in the lobby
4. See 3 fake messages appear with 2-second delays

