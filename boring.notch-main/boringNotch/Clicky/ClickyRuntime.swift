import Foundation

/// Owns Clicky's runtime so we can start/stop it from Boring Notch.
/// This is the "bridge" between Boring Notch lifecycle and Clicky code.
@MainActor
final class ClickyRuntime {
    static let shared = ClickyRuntime()

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

