# Clicky-in-BoringNotch (Monolith Merge) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a third “Clicky” tab in Boring Notch that renders Clicky’s UI and runs the full Clicky voice + overlay pipeline inside the Boring Notch app, avoiding macOS overlay conflicts between two separate apps.

**Architecture:** We add a new `NotchViews.clicky` route in Boring Notch, render a `ClickyNotchPage` that embeds Clicky’s `CompanionPanelView`, and run Clicky’s `CompanionManager` lifecycle from Boring Notch’s `AppDelegate`. We lower Clicky’s overlay window level (and optionally auto-hide it while the notch is open) to prevent hover/cursor conflicts with Boring Notch’s notch window.

**Tech Stack:** SwiftUI, AppKit (NSWindow/NSPanel levels), macOS permissions (Accessibility / Screen Recording / Microphone / ScreenCaptureKit), Xcode project wiring (`project.pbxproj`).

---

## Repository roots (local)

- Boring Notch: `boring.notch-main/`
- Clicky: `clicky-main/`

This plan assumes we are **merging Clicky Swift sources into**:
`boring.notch-main/boringNotch/Clicky/` (new folder).

---

## Task 1: Add “Clicky” to Boring Notch tab routing

**Files:**
- Modify: `boring.notch-main/boringNotch/enums/generic.swift`
- Modify: `boring.notch-main/boringNotch/components/Tabs/TabSelectionView.swift`
- Modify: `boring.notch-main/boringNotch/components/Tabs/TabButton.swift`
- Modify: `boring.notch-main/boringNotch/ContentView.swift`
- Create: `boring.notch-main/boringNotch/components/Tabs/TabIcon.swift` (new lightweight icon abstraction)
- Create: `boring.notch-main/boringNotch/components/Tabs/ClickyTriangleIcon.swift` (SwiftUI icon)

- [ ] **Step 1: Extend NotchViews**

In `boringNotch/enums/generic.swift`, add:

```swift
public enum NotchViews {
    case home
    case shelf
    case clicky
}
```

- [ ] **Step 2: Add a generic way to render tab icons**

Create `boringNotch/components/Tabs/TabIcon.swift`:

```swift
import SwiftUI

enum TabIcon {
    case sfSymbol(String)
    case custom(AnyView)
}

extension TabIcon {
    @ViewBuilder
    func render() -> some View {
        switch self {
        case .sfSymbol(let name):
            Image(systemName: name)
        case .custom(let view):
            view
        }
    }
}
```

- [ ] **Step 3: Implement Clicky’s triangle icon (SwiftUI)**

Create `boringNotch/components/Tabs/ClickyTriangleIcon.swift`:

```swift
import SwiftUI

/// Matches Clicky’s menu bar triangle: equilateral triangle rotated ~35°.
struct ClickyTriangleIcon: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let height = size * sqrt(3.0) / 2.0
            let cx = geo.size.width * 0.5
            let cy = geo.size.height * 0.5
            let angle = Angle(degrees: 35)

            Path { path in
                let top = CGPoint(x: cx, y: cy - height / 1.5)
                let bottomLeft = CGPoint(x: cx - size / 2, y: cy + height / 3)
                let bottomRight = CGPoint(x: cx + size / 2, y: cy + height / 3)
                path.move(to: top)
                path.addLine(to: bottomLeft)
                path.addLine(to: bottomRight)
                path.closeSubpath()
            }
            .rotation(angle, anchor: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
```

Notes:
- We keep the icon “templated” by inheriting foreground color from the tab.
- We use `GeometryReader` to size correctly inside the tab button.

- [ ] **Step 4: Update TabButton to accept TabIcon**

In `TabButton.swift`, change:
- `icon: String` → `icon: TabIcon`
- render with `icon.render()`.

Expected shape:

```swift
struct TabButton: View {
    let label: String
    let icon: TabIcon
    let selected: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            icon.render()
                .padding(.horizontal, 15)
                .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

- [ ] **Step 5: Add Clicky tab model**

In `TabSelectionView.swift`, update the `TabModel` icon type and add a third tab:

```swift
struct TabModel: Identifiable {
    let id = UUID()
    let label: String
    let icon: TabIcon
    let view: NotchViews
}

let tabs = [
    TabModel(label: "Home", icon: .sfSymbol("house.fill"), view: .home),
    TabModel(label: "Shelf", icon: .sfSymbol("tray.fill"), view: .shelf),
    TabModel(
        label: "Clicky",
        icon: .custom(AnyView(ClickyTriangleIcon().frame(width: 14, height: 14))),
        view: .clicky
    ),
]
```

- [ ] **Step 6: Render ClickyNotchPage from ContentView**

In `ContentView.swift`, extend the existing switch:

```swift
switch coordinator.currentView {
case .home:
    NotchHomeView(albumArtNamespace: albumArtNamespace)
case .shelf:
    ShelfView()
case .clicky:
    ClickyNotchPage()
}
```

- [ ] **Step 7: Commit**

```bash
git add boringNotch/enums/generic.swift \
  boringNotch/components/Tabs/TabSelectionView.swift \
  boringNotch/components/Tabs/TabButton.swift \
  boringNotch/ContentView.swift \
  boringNotch/components/Tabs/TabIcon.swift \
  boringNotch/components/Tabs/ClickyTriangleIcon.swift
git commit -m "feat: add Clicky tab route and icon"
```

---

## Task 2: Add ClickyNotchPage + runtime wiring (start at app launch)

**Files:**
- Create: `boring.notch-main/boringNotch/Clicky/ClickyNotchPage.swift`
- Create: `boring.notch-main/boringNotch/Clicky/ClickyRuntime.swift`
- Modify: `boring.notch-main/boringNotch/boringNotchApp.swift` (start/stop)

- [ ] **Step 1: Create ClickyRuntime to own CompanionManager**

`boringNotch/Clicky/ClickyRuntime.swift`:

```swift
import Foundation

@MainActor
final class ClickyRuntime {
    static let shared = ClickyRuntime()

    // Clicky type will come from merged sources
    let companionManager = CompanionManager()

    private(set) var isStarted: Bool = false

    private init() {}

    func start() {
        guard !isStarted else { return }
        isStarted = true
        companionManager.start()
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        companionManager.stop()
    }
}
```

- [ ] **Step 2: Create ClickyNotchPage**

`boringNotch/Clicky/ClickyNotchPage.swift`:

```swift
import SwiftUI

struct ClickyNotchPage: View {
    var body: some View {
        // Clicky’s existing panel UI, but hosted inside the notch.
        CompanionPanelView(companionManager: ClickyRuntime.shared.companionManager)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
```

- [ ] **Step 3: Start Clicky at app launch, stop at terminate**

In `boringNotchApp.swift`:
- inside `applicationDidFinishLaunching`, call `ClickyRuntime.shared.start()`
- inside `applicationWillTerminate`, call `ClickyRuntime.shared.stop()`

Keep this on `@MainActor` to match Clicky’s runtime assumptions.

- [ ] **Step 4: Commit**

```bash
git add boringNotch/boringNotchApp.swift boringNotch/Clicky/ClickyRuntime.swift boringNotch/Clicky/ClickyNotchPage.swift
git commit -m "feat: embed Clicky panel and start Clicky runtime at launch"
```

---

## Task 3: Merge Clicky Swift sources into Boring Notch target

**Files:**
- Create folder: `boring.notch-main/boringNotch/Clicky/ClickySources/` (or similar)
- Copy from Clicky: `clicky-main/leanring-buddy/*.swift`
- Copy from Clicky: selected resources used at runtime (audio, images) if referenced by `Bundle.main.url(forResource:)`
- Modify: `boring.notch-main/boringNotch.xcodeproj/project.pbxproj`

- [ ] **Step 1: Copy Clicky sources into Boring Notch**

Copy (at minimum) these Clicky files (and any dependencies they reference):
- `CompanionManager.swift`
- `CompanionPanelView.swift`
- `OverlayWindow.swift` (contains overlay + window manager)
- `BuddyDictationManager.swift` and transcription providers it uses
- `ClaudeAPI.swift`, `OpenAIAPI.swift` (if referenced), `ElevenLabsTTSClient.swift`
- `WindowPositionManager.swift`, `GlobalPushToTalkShortcutMonitor.swift`
- `DesignSystem.swift` (DS), plus any other files referenced by panel/overlay
- `AppBundleConfiguration.swift` (we will reuse)
- `ClickyAnalytics.swift` (and any analytics deps, if still desired)

**Rule:** keep original file names to avoid massive refactor churn.

- [ ] **Step 2: Add Clicky sources to boringNotch target in project.pbxproj**

Edit `boringNotch.xcodeproj/project.pbxproj`:
- Create PBXFileReference entries for each copied file
- Add them to the boringNotch PBXSourcesBuildPhase
- Add any required package dependencies / frameworks if Clicky code imports them

If Clicky uses SwiftPM packages that Boring Notch doesn’t already have, add them to:
- `Package.resolved` (workspace) and pbxproj package references

- [ ] **Step 3: Add Clicky runtime resources**

If these are referenced by filename at runtime, they must be added to Copy Bundle Resources:
- `ff.mp3` (onboarding music)
- any other `Bundle.main.url(forResource:)` resources used by Clicky

Otherwise, remove/guard those features behind optionality.

- [ ] **Step 4: Commit**

```bash
git add boringNotch/Clicky
git add boringNotch.xcodeproj/project.pbxproj
git commit -m "chore: merge Clicky sources into Boring Notch target"
```

---

## Task 4: Fix overlay window conflict (window levels + notch-open behavior)

**Files:**
- Modify (merged file): `boringNotch/Clicky/.../OverlayWindow.swift` (or wherever it lands)
- Modify: `boring.notch-main/boringNotch/ContentView.swift` (optional: notch-open hook)

- [ ] **Step 1: Lower Clicky overlay window level**

In Clicky’s `OverlayWindow` init, change:

```swift
self.level = .screenSaver
```

to something lower than Boring Notch (`.mainMenu + 3`), e.g.:

```swift
self.level = .mainMenu + 2
```

- [ ] **Step 2 (optional but recommended): hide overlay while notch is open**

Add an `onChange` in Boring Notch `ContentView` for `vm.notchState` that calls:
- `ClickyRuntime.shared.companionManager.overlayWindowManager.hideOverlay()` when open
- `...showOverlay(...)` when closed (only if Clicky wants it enabled)

If Clicky already tracks `isOverlayVisible` and `isClickyCursorEnabled`, respect those flags.

- [ ] **Step 3: Commit**

```bash
git add boringNotch/Clicky
git add boringNotch/ContentView.swift
git commit -m "fix: prevent Clicky overlay from conflicting with notch window"
```

---

## Task 5: Make Clicky worker URL configurable via Info.plist

**Files:**
- Modify (merged file): `CompanionManager.swift`
- Modify: `boring.notch-main/boringNotch/Info.plist`

- [ ] **Step 1: Add a Boring Notch Info.plist key**

Add:
- `CLICKY_WORKER_BASE_URL` (String)

Example value:
`https://your-worker-name.your-subdomain.workers.dev`

- [ ] **Step 2: Read config via AppBundleConfiguration**

Replace hard-coded:

```swift
private static let workerBaseURL = "https://your-worker-name.your-subdomain.workers.dev"
```

with:

```swift
private static let workerBaseURL: String = {
    AppBundleConfiguration.stringValue(forKey: "CLICKY_WORKER_BASE_URL")
        ?? "https://your-worker-name.your-subdomain.workers.dev"
}()
```

- [ ] **Step 3: Commit**

```bash
git add boringNotch/Info.plist boringNotch/Clicky
git commit -m "feat: make Clicky worker base URL configurable"
```

---

## Task 6: Manual verification checklist (Xcode)

Since CI/build tooling for macOS apps is usually done in Xcode, verify locally:

- [ ] Open `boring.notch-main/boringNotch.xcodeproj` in Xcode
- [ ] Build `boringNotch` target (⌘B)
- [ ] Run (⌘R) and confirm:
  - Notch opens normally; Home/Shelf still work
  - New Clicky tab appears and renders Clicky panel UI
  - Permissions prompts work (mic, accessibility, screen recording)
  - Clicky overlay no longer blocks notch hover/open behavior
- [ ] If sandbox blocks ScreenCaptureKit or global shortcuts:
  - Add missing entitlements to `boringNotch/boringNotch.entitlements`
  - Rebuild and retry

