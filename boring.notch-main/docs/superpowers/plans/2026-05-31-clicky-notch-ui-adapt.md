# Clicky Tab UI Adaptation (Boring Notch Host) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Clicky tab UI feel native inside Boring Notch by removing Clicky’s menu-bar-panel specific chrome (fixed width/background/shadow/close button/footer), making it responsive, and allowing scrolling within notch constraints.

**Architecture:** Add a lightweight “host surface” switch to `CompanionPanelView` so the same UI can render differently when embedded in Boring Notch vs shown as Clicky’s original panel. `ClickyNotchPage` uses the `.boringNotch` host surface.

**Tech Stack:** SwiftUI.

---

### Task 1: Add host surface to CompanionPanelView and remove panel-only chrome in notch mode

**Files:**
- Modify: `boring.notch-main/boringNotch/Clicky/CompanionPanelView.swift`
- Modify: `boring.notch-main/boringNotch/Clicky/ClickyNotchPage.swift`
- (Verify) `boring.notch-main/boringNotch/Clicky/MenuBarPanelManager.swift` keeps default behavior

- [ ] **Step 1: Add HostSurface enum and parameter**

Add:

```swift
enum ClickyHostSurface { case menuBarPanel, boringNotch }
```

and change:

```swift
struct CompanionPanelView: View {
  let hostSurface: ClickyHostSurface
  init(companionManager: CompanionManager, hostSurface: ClickyHostSurface = .menuBarPanel) { ... }
}
```

- [ ] **Step 2: Extract the core content (VStack) to `panelContent`**

So we can apply different wrappers and modifiers depending on host surface.

- [ ] **Step 3: For `.boringNotch`**

Apply these differences:
- Remove fixed `.frame(width: 320)`
- Remove `.background(panelBackground)` and shadows
- Wrap content with:

```swift
ScrollView { panelContent }
```

- Hide panel-only controls:
  - Header close “X”
  - Footer section (“Quit Clicky”, etc.)

- [ ] **Step 4: Update ClickyNotchPage**

```swift
CompanionPanelView(companionManager: ..., hostSurface: .boringNotch)
```

- [ ] **Step 5: Commit**

```bash
git add boring.notch-main/boringNotch/Clicky/CompanionPanelView.swift \
  boring.notch-main/boringNotch/Clicky/ClickyNotchPage.swift \
  boring.notch-main/docs/superpowers/plans/2026-05-31-clicky-notch-ui-adapt.md
git commit -m "feat: adapt Clicky panel for notch host"
```

