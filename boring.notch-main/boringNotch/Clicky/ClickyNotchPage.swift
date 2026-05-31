import SwiftUI

/// Hosts Clicky's panel UI inside the Boring Notch "Clicky" tab.
struct ClickyNotchPage: View {
    @EnvironmentObject private var vm: BoringViewModel
    @State private var isHoverLockActive: Bool = false

    var body: some View {
        CompanionPanelView(
            companionManager: ClickyRuntime.shared.companionManager,
            hostSurface: .boringNotch,
            onContentHeightChange: { contentHeight in
                updatePreferredNotchHeight(from: contentHeight)
            }
        )
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .onAppear {
                // Allow text inputs (email) to become focused while on the Clicky tab.
                BoringNotchSkyLightWindow.allowKeyWindow = true
            }
            .onDisappear {
                BoringNotchSkyLightWindow.allowKeyWindow = false

                // If we leave the Clicky tab while open, reset to default notch size.
                if vm.notchState == .open {
                    vm.applyOpenNotchSizeForCurrentView()
                }

                // Safety: ensure we don't leave the notch "pinned".
                if isHoverLockActive {
                    isHoverLockActive = false
                    SharingStateManager.shared.endInteraction()
                }
            }
            .onHover { hovering in
                // Keep the notch from auto-closing while the user is interacting
                // with Clicky (scrolling, typing, clicking).
                if hovering, !isHoverLockActive {
                    isHoverLockActive = true
                    SharingStateManager.shared.beginInteraction()
                } else if !hovering, isHoverLockActive {
                    isHoverLockActive = false
                    SharingStateManager.shared.endInteraction()
                }
            }
    }

    private func updatePreferredNotchHeight(from contentHeight: CGFloat) {
        guard contentHeight > 0 else { return }

        let screen = vm.screenUUID.flatMap { NSScreen.screen(withUUID: $0) } ?? NSScreen.main
        let screenHeight = screen?.visibleFrame.height ?? screen?.frame.height ?? 900

        let minHeight = openNotchSize.height
        // While permissions/onboarding are incomplete, the panel is taller, so allow more height
        // to reduce scrolling. Once fully set up, keep the cap tighter to preserve "notch-ness".
        let maxHeightFraction: CGFloat = ClickyRuntime.shared.companionManager.allPermissionsGranted ? 0.5 : 0.7
        let maxHeight = screenHeight * maxHeightFraction

        // Small padding so the bottom content doesn't sit on the edge.
        let padded = contentHeight + 8
        let clamped = min(maxHeight, max(minHeight, padded))

        // Save for future opens and apply immediately if we're already open.
        if vm.clickyPreferredOpenHeight != clamped {
            vm.clickyPreferredOpenHeight = clamped
            if vm.notchState == .open {
                vm.applyOpenNotchSizeForCurrentView()
            }
        }
    }
}
