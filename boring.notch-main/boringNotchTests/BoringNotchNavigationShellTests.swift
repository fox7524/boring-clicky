import XCTest
@testable import boringNotch

final class BoringNotchNavigationShellTests: XCTestCase {
    func testTabsIncludeClickyShellEntry() {
        XCTAssertEqual(tabs.count, 3)
        XCTAssertEqual(tabs.map(\.label), ["Home", "Shelf", "Clicky"])
        XCTAssertEqual(tabs.map(\.icon), ["house.fill", "tray.fill", "message.fill"])
    }
}
