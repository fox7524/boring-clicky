import SwiftUI

/// Hosts Clicky's panel UI inside the Boring Notch "Clicky" tab.
struct ClickyNotchPage: View {
    var body: some View {
        CompanionPanelView(companionManager: ClickyRuntime.shared.companionManager)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

