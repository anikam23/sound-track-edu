# Shared AlertHUDManager Fix

## 🐛 The Real Problem

**Root Cause:** Each tab had its own `AlertHUDManager` instance, and when one alert was sent, **all 4 tabs tried to show the dialog simultaneously**, causing conflicts!

### What Was Happening:
1. Teacher sends ONE "Important Alert"
2. **All 4 tabs** receive the alert via `AlertSyncService`
3. Each tab's `AlertHUDManager` tries to show the dialog independently
4. **Alerts tab** shows dialog first (briefly) - conflicts with other tabs
5. User switches to **Review tab**
6. **Review tab's** AlertHUDManager shows the dialog (works because it's fresh)

This explained the weird behavior where:
- Dialog appeared briefly on Alerts tab (multiple managers fighting)
- Then appeared correctly on Review tab (that manager was "winning")

## ✅ The Solution: Shared AlertHUDManager

Just like we did with `LiveTranscriber`, we now create **ONE shared `AlertHUDManager`** at the app level that all tabs use.

### Changes Made:

#### 1. **Created Shared Manager** (`Sound_Track_EDUApp.swift`)
```swift
@StateObject private var hudManager = AlertHUDManager()

ContentView()
    .environmentObject(hudManager)  // Share with all tabs
    .onAppear {
        // Set up transcription callback ONCE
        hudManager.onStartTranscription = { [weak liveTranscriber] in
            await liveTranscriber?.start()
        }
    }
```

#### 2. **Updated All Tabs to Use Shared Manager**

**Before (each tab):**
```swift
@StateObject private var hudManager = AlertHUDManager()  // ❌ Each tab creates its own
```

**After (all tabs):**
```swift
@EnvironmentObject private var hudManager: AlertHUDManager  // ✅ All use the same one
```

**Updated Files:**
- `LiveTabView.swift`
- `UI/Chat/ChatTabView.swift`
- `ReviewView.swift`
- `TeacherModeView.swift`

#### 3. **Removed Duplicate Callbacks**

Since the callback is set up once at app level, removed it from individual tabs:

**Removed from all tabs:**
```swift
.onAppear {
    hudManager.onStartTranscription = { ... }  // ❌ No longer needed
}
```

## 🎯 How It Works Now

### Single Alert Flow:
1. ✅ Teacher sends ONE "Important Alert"
2. ✅ `AlertSyncService` publishes the alert ONCE
3. ✅ **All tabs** detect it via `onChange(of: alertSync.lastReceivedAlert)`
4. ✅ All tabs call the **SAME** `hudManager.showAlertWithTranscriptionPrompt()`
5. ✅ The shared manager handles it **once**, regardless of which tab you're on
6. ✅ Dialog appears and stays until user responds
7. ✅ No conflicts between multiple managers!

### Architecture:
```
App Level (Sound_Track_EDUApp)
├── AlertSyncService (shared)
├── LiveTranscriber (shared)
└── AlertHUDManager (shared) ← NEW!
    
Tab Views
├── LiveTabView    ─────┐
├── ChatTabView    ─────┼──→ All use the SAME AlertHUDManager
├── ReviewView     ─────┤
└── TeacherModeView ────┘
```

## 📊 Files Modified

### Core App:
1. **`Sound_Track_EDUApp.swift`**
   - Added `@StateObject private var hudManager = AlertHUDManager()`
   - Added `.environmentObject(hudManager)`
   - Set up callback once in `onAppear`

### Tab Views (all changed `@StateObject` to `@EnvironmentObject`):
2. **`LiveTabView.swift`**
   - Changed to use shared hudManager
   - Removed duplicate callback setup

3. **`UI/Chat/ChatTabView.swift`**
   - Changed to use shared hudManager
   - Removed duplicate callback setup

4. **`ReviewView.swift`**
   - Changed to use shared hudManager
   - Removed duplicate callback setup

5. **`TeacherModeView.swift`**
   - Changed to use shared hudManager
   - Removed duplicate callback setup

## ✨ Expected Behavior Now

### Test Scenario:
1. **Teacher sends "Important Alert"** (pressed ONCE)
2. **Student on Alerts tab:**
   - ✅ Dialog appears and stays until choice is made
   - ✅ No brief flash
   - ✅ User can read and select Yes/No

3. **Student switches to Review tab:**
   - ✅ NO second dialog appears
   - ✅ Same alert already handled by shared manager

4. **Teacher sends SECOND alert:**
   - ✅ Dialog appears correctly (doesn't matter which tab student is on)
   - ✅ Consistent behavior across all tabs

### Why This Works:
- ✅ **One manager** = One dialog at a time
- ✅ **Shared state** = No conflicts between tabs
- ✅ **Single callback** = Transcription starts correctly
- ✅ **Tab-agnostic** = Works the same on any tab

## 🧪 Testing Instructions

### Setup:
1. Device A (Teacher): Alerts → Teacher → Start Teacher Mode
2. Device B (Student): Alerts → Student → Start Student Mode

### Test 1: Alert on Alerts Tab
1. Device B: Stay on Alerts tab
2. Device A: Send "Important Alert" (press ONCE)
3. Device B: 
   - ✅ **Expected:** Dialog appears and STAYS visible
   - ✅ Select "No"
   - ✅ Banner appears after selection

### Test 2: Alert on Different Tab
1. Device B: Navigate to Chat tab
2. Device A: Send "Important Alert" (press ONCE)
3. Device B:
   - ✅ **Expected:** Dialog appears and STAYS visible
   - ✅ Select "Yes"
   - ✅ Transcription starts, banner appears

### Test 3: No Duplicate Dialogs
1. Device B: Stay on Review tab
2. Device A: Send "Important Alert" (press ONCE)
3. Device B: See dialog
4. Device B: Switch to Live tab (while dialog is showing)
5. ✅ **Expected:** Dialog stays, NO second dialog appears

### Test 4: Multiple Alerts
1. Device A: Send "Important Alert" #1
2. Device B: Respond to dialog
3. Device A: Send "Important Alert" #2
4. Device B: See dialog again
5. ✅ **Expected:** Each alert shows ONE dialog, works consistently

## 📈 Benefits

1. **No More Conflicts:** One manager = one dialog
2. **Consistent Behavior:** Same experience on all tabs
3. **Better Performance:** One state object instead of 4
4. **Cleaner Code:** Callback set up once, not per tab
5. **Predictable:** User always sees the dialog properly

## 🔍 Debug Output

Console will now show cleaner logs:
```
🔔 [AlertHUD] Received alert: Important Now, isTranscribing: false
🔔 [AlertHUD] Will show transcription prompt - NOT showing banner yet
🔔 [AlertHUD] Showing transcription prompt now
[User responds]
🔔 [AlertHUD] User accepted transcription
🔔 [AlertHUD] Now showing alert banner
```

No duplicate logs from multiple managers!

---

**Status:** ✅ Fixed - Using shared AlertHUDManager eliminates dialog conflicts!

