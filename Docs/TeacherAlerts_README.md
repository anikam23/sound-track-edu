# Teacher Alerts Feature

## Overview

The Teacher Alerts feature enables teachers to broadcast important messages to students' devices on the same local network using MultipeerConnectivity (MPC). This creates a classroom communication system without requiring internet connectivity or external servers.

## Features

- **Peer-to-peer communication** using MultipeerConnectivity
- **Two alert types**: Important Now and Called by Name
- **Visual banners** with haptic feedback and system sounds
- **Background notifications** when app is not active
- **Auto-start transcription** option for important alerts
- **Privacy-focused** - no data leaves the local network

## Setup Instructions

### 1. Xcode Project Configuration

#### Add Info.plist Entry
Add the following key to your `Info.plist` file:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Allows nearby devices to send classroom alerts over the local network.</string>
```

#### Enable Capabilities
No additional capabilities are required. MultipeerConnectivity works without special entitlements.

### 2. Manual Setup Steps

1. **Open your project in Xcode**
2. **Navigate to Info.plist**:
   - Right-click on your project → Open As → Source Code
   - Add the NSLocalNetworkUsageDescription key as shown above
3. **Build and run** on your target devices

## Testing Instructions

### Prerequisites
- Two iOS devices on the same Wi-Fi network, OR
- One device + iOS Simulator on the same network
- Both devices should have the app installed

### Step-by-Step Testing

#### 1. Setup Teacher Device
1. Open the app on Device A
2. Navigate to the **Teacher** tab
3. Select **Teacher** role from the segmented control
4. Enter your teacher name (e.g., "Ms. Johnson")
5. Wait for connection status to show "Teacher mode - listening for students"

#### 2. Setup Student Device
1. Open the app on Device B
2. Navigate to the **Teacher** tab
3. Select **Student** role from the segmented control
4. Enter student name (e.g., "Anika")
5. Enable "Receive teacher alerts" toggle
6. Optionally enable "Auto-start transcription on important alerts"
7. Wait for connection status to show "Student mode - listening for alerts"

#### 3. Verify Connection
1. On teacher device, you should see "1 student(s) connected" in the status
2. The connected student should appear in the "Connected Students" list

#### 4. Test Important Now Alert
1. On teacher device, ensure "All Students" is selected
2. Optionally add a message like "Please pay attention to the board"
3. Tap **"Send Important Now"** button
4. Student device should show:
   - Banner with sparkles icon and "Important Now" title
   - Haptic feedback (heavy)
   - System sound
   - If auto-start enabled, Live transcription should begin

#### 5. Test Call Student Alert
1. On teacher device, select "Specific Student"
2. Enter student name (e.g., "Anika")
3. Add message like "Can you answer question 3?"
4. Tap **"Call Student"** button
5. Student device should show:
   - Banner with person.wave.2 icon and "You were called" title
   - Haptic feedback (medium)
   - System sound

#### 6. Test Background Notifications
1. Background the student app (home button/swipe up)
2. On teacher device, send an "Important Now" alert
3. Student should receive a local notification
4. Tap notification to return to app

#### 7. Test Banner Display
1. On student device, tap **"Test Banner"** button
2. Verify banner appears with proper styling and dismisses after 4 seconds

## Troubleshooting

### Common Issues

#### "No connected peers"
- Ensure both devices are on the same Wi-Fi network
- Check that both devices have Bluetooth enabled
- Restart the app on both devices
- Try switching roles and back

#### "Failed to start advertising"
- Check that the device has Bluetooth and Wi-Fi enabled
- Ensure the app has Local Network permission (iOS 14+)
- Try restarting the device

#### Banners not appearing
- Check that the student has "Receive teacher alerts" enabled
- Verify the app is in foreground
- Test with the "Test Banner" button first

#### Notifications not working
- Check notification permissions in Settings > Sound Track EDU > Notifications
- Ensure the app was backgrounded when alert was sent
- Test with device notifications enabled

### Debug Information

The app logs connection status and alert sending/receiving to the console. Check Xcode console for:
- Connection state changes
- Alert sending confirmations
- Error messages

## Architecture

### Key Components

1. **TeacherAlert.swift** - Alert data models
2. **StudentProfile.swift** - Student profile model
3. **ProfileStore.swift** - Local profile persistence
4. **AlertSyncService.swift** - MultipeerConnectivity wrapper
5. **AlertBannerView.swift** - Banner UI component
6. **AlertHUDManager.swift** - Banner management
7. **TeacherModeView.swift** - Teacher/Student interface

### Data Flow

1. Teacher creates alert in `TeacherModeView`
2. `AlertSyncService` encodes and sends via MPC
3. Student device receives via MPC delegate
4. `AlertHUDManager` displays banner with feedback
5. Background notifications scheduled if app backgrounded

### Security Notes

- All communication is local network only
- No personal data is transmitted
- MPC uses encryption for peer-to-peer communication
- No internet connectivity required

## Future Enhancements

Potential improvements for future versions:
- Alert history/logging
- Custom alert sounds
- Group targeting by subject/period
- Teacher dashboard with student status
- Offline alert queuing

