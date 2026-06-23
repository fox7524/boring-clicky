import XCTest
@testable import boringNotch

final class ClickyShellTests: XCTestCase {
    func testClickyTabIsRegistered() {
        XCTAssertTrue(
            tabs.contains { $0.view == .clicky && $0.label == "Clicky" }
        )
    }

    func testClickyPlaceholderViewExists() {
        _ = ClickyTabView()
    }
}
