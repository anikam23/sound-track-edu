# Live Transcription Prompt on Important Alerts

## ✅ Feature Implemented

**Requirement:** When a teacher sends an "Important Alert", ask the student if they would like to start Live transcription. Only prompt if transcription is not already running.

**Implementation:** Confirmation dialog that appears across all tabs when an important alert is received.

## 🎯 How It Works

### User Flow:

1. **Teacher sends "Important Alert"**
   - Teacher goes to Alerts tab → Teacher Mode
   - Sends "Important Alert" to student(s)

2. **Student receives alert**
   - **If Live transcription is NOT running:**
     - ✅ Alert dialog appears: "Start Live Transcription?"
     - Shows teacher name and optional message
     - Two buttons: "Yes" and "No"
   
   - **If Live transcription IS already running:**
     - ✅ Just shows the alert banner (no prompt)
     - Doesn't interrupt ongoing transcription

3. **Student response:**
   - **Selects "Yes":**
     - Live transcription starts automatically
     - Alert banner appears showing the alert details
     - Student can see transcription on Live tab
   
   - **Selects "No":**
     - Live transcription does NOT start
     - Alert banner appears showing the alert details
     - Student continues with current activity

### Works Across All Tabs:
- ✅ **Live tab** - Prompt appears, can start transcription
- ✅ **Chat tab** - Prompt appears, switches to Live tab when started
- ✅ **Review tab** - Prompt appears, switches to Live tab when started
- ✅ **Alerts tab** - Prompt appears, switches to Live tab when started

## 🔧 Technical Implementation

### 1. **Enhanced AlertHUDManager** (`UI/Alerts/AlertHUDManager.swift`)

Added transcription prompt support:

```swift
@Published var showTranscriptionPrompt = false
var onStartTranscription: (() async -> Void)?

func showAlertWithTranscriptionPrompt(_ alert: TeacherAlert, isTranscribing: Bool) {
    currentAlert = alert
    
    // Only show prompt for Important alerts when not already transcribing
    if alert.type == .importantNow && !isTranscribing {
        showTranscriptionPrompt = true
    } else {
        // Just show the banner for other alerts
        showAlert(alert)
    }
}

func acceptTranscription() {
    showTranscriptionPrompt = false
    Task { await onStartTranscription?() }
    if let alert = currentAlert { showAlert(alert) }
}

func declineTranscription() {
    showTranscriptionPrompt = false
    if let alert = currentAlert { showAlert(alert) }
}
```

### 2. **Alert Dialog UI** (`AlertBannerOverlay`)

Added SwiftUI `.alert()` modifier:

```swift
.alert("Start Live Transcription?", isPresented: $hudManager.showTranscriptionPrompt) {
    Button("Yes") {
        hudManager.acceptTranscription()
    }
    Button("No", role: .cancel) {
        hudManager.declineTranscription()
    }
} message: {
    Text("\(teacherName) sent an important alert.\n\n\(message)\n\nWould you like to start live transcription?")
}
```

### 3. **Shared LiveTranscriber** (`Sound_Track_EDUApp.swift`)

Made `LiveTranscriber` available as environment object:

```swift
@StateObject private var liveTranscriber = LiveTranscriber()

ContentView()
    .environmentObject(liveTranscriber)
```

### 4. **Updated All Tabs**

Each tab now:
- Receives `LiveTranscriber` as `@EnvironmentObject`
- Checks transcription state when alert arrives
- Sets up callback to start transcription
- Uses new `showAlertWithTranscriptionPrompt()` method

#### Example (LiveTabView):

```swift
@EnvironmentObject private var transcriber: LiveTranscriber

.onChange(of: alertSync.lastReceivedAlert) { _, newAlert in
    if let alert = newAlert {
        let isTranscribing = transcriber.uiMode == .listening || transcriber.uiMode == .paused
        hudManager.showAlertWithTranscriptionPrompt(alert, isTranscribing: isTranscribing)
    }
}
.onAppear {
    hudManager.onStartTranscription = { [weak transcriber] in
        await transcriber?.start()
    }
}
```

## 📊 Files Modified

### Core Alert System:
1. **`UI/Alerts/AlertHUDManager.swift`**
   - Added `showTranscriptionPrompt` published property
   - Added `onStartTranscription` callback
   - Added `showAlertWithTranscriptionPrompt()` method
   - Added `acceptTranscription()` and `declineTranscription()` methods
   - Added `.alert()` modifier to `AlertBannerOverlay`

### App Setup:
2. **`Sound_Track_EDUApp.swift`**
   - Removed old auto-start callback (replaced with confirmation dialog)
   - `LiveTranscriber` already shared via environment object

### Services:
3. **`Services/AlertSyncService.swift`**
   - Removed `onImportantAlert` callback property (no longer needed)
   - Removed callback invocation in `handleReceivedAlert()`

### Tab Views:
4. **`LiveTabView.swift`**
   - Changed to `@EnvironmentObject` for transcriber
   - Updated alert handler to check transcription state
   - Added transcription callback setup

5. **`UI/Chat/ChatTabView.swift`**
   - Added `@EnvironmentObject` for transcriber
   - Updated alert handler to check transcription state
   - Added transcription callback setup

6. **`ReviewView.swift`**
   - Added `@EnvironmentObject` for transcriber
   - Updated alert handler to check transcription state
   - Added transcription callback setup

7. **`TeacherModeView.swift`**
   - Added `@EnvironmentObject` for transcriber
   - Updated alert handler to check transcription state
   - Added transcription callback setup

## 🎨 Dialog Appearance

### Alert Dialog:
```
┌─────────────────────────────────────┐
│ Start Live Transcription?           │
├─────────────────────────────────────┤
│                                     │
│ Ms. Johnson sent an important       │
│ alert.                              │
│                                     │
│ Please pay attention to the next    │
│ section.                            │
│                                     │
│ Would you like to start live        │
│ transcription?                      │
│                                     │
│         ┌─────┐  ┌─────┐           │
│         │ No  │  │ Yes │           │
│         └─────┘  └─────┘           │
└─────────────────────────────────────┘
```

### Then Alert Banner (after choice):
```
┌─────────────────────────────────────┐
│ ⚠️ Important Now                    │
│ From: Ms. Johnson                   │
│ Please pay attention to the next    │
│ section.                            │
└─────────────────────────────────────┘
```

## 🧪 Testing Checklist

### Setup:
1. Device A (Teacher): Go to Alerts → Teacher → Start Teacher Mode
2. Device B (Student): Go to Alerts → Student → Start Student Mode

### Test 1: Prompt Appears on Important Alert
1. Device B: Navigate to Chat tab (transcription OFF)
2. Device A: Send "Important Alert"
3. ✅ **Expected:** Dialog appears on Device B asking about transcription

### Test 2: User Accepts Transcription
1. Device B: See dialog → Tap "Yes"
2. ✅ **Expected:** 
   - Live transcription starts
   - Alert banner appears
   - Can see transcription on Live tab

### Test 3: User Declines Transcription
1. Device B: Navigate to Review tab (transcription OFF)
2. Device A: Send another "Important Alert"
3. Device B: See dialog → Tap "No"
4. ✅ **Expected:**
   - Live transcription does NOT start
   - Alert banner appears
   - Still on Review tab

### Test 4: No Prompt When Already Transcribing
1. Device B: Go to Live tab → Start transcription manually
2. Device A: Send "Important Alert"
3. ✅ **Expected:**
   - NO dialog appears
   - Only alert banner shows
   - Transcription continues

### Test 5: No Prompt for Other Alert Types
1. Device B: Any tab (transcription OFF)
2. Device A: Send "Call Student" alert
3. ✅ **Expected:**
   - NO dialog appears
   - Only alert banner shows
   - Transcription does NOT start

## 🔒 Edge Cases Handled

1. **Already transcribing:** No prompt shown
2. **Other alert types:** No prompt shown (only for Important)
3. **Multiple alerts:** Each Important alert shows prompt if not transcribing
4. **Tab switching:** Prompt appears regardless of current tab
5. **User doesn't respond:** Dialog stays until user makes choice
6. **Callback cleanup:** Weak references prevent memory leaks

## ✨ Benefits

1. **User Choice:** Students decide when to start transcription
2. **Context Aware:** Only prompts when relevant (Important + not transcribing)
3. **Non-Intrusive:** Other alert types just show banner
4. **Universal:** Works on any tab the student is on
5. **Clear Communication:** Shows teacher name and message in prompt
6. **Immediate Action:** Transcription starts instantly on acceptance

## 🎯 Removed Old Behavior

**Before:**
- ❌ Transcription would auto-start immediately on Important alert
- ❌ No user choice
- ❌ Could interrupt user if they didn't want to transcribe

**Now:**
- ✅ Student is asked first
- ✅ Student chooses Yes or No
- ✅ Only starts if student agrees

---

**Status:** ✅ Complete - Students are now prompted to start transcription on Important alerts!

