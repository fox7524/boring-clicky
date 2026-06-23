import Defaults
import XCTest
@testable import boringNotch

final class ClickyStorageTests: XCTestCase {
    func testClickyDefaultsKeysExposeExpectedDefaults() {
        XCTAssertEqual(Defaults[.clickySelectedProvider], .anthropic)
        XCTAssertEqual(Defaults[.clickySelectedAnthropicModel], "claude-sonnet-4-5")
        XCTAssertEqual(Defaults[.clickySelectedOpenAIModel], "gpt-4.1")
        XCTAssertEqual(Defaults[.clickySelectedGeminiModel], "gemini-2.5-pro")
    }

    func testKeychainKeyStoreRoundTripsProviderKey() throws {
        let store = KeychainKeyStore(
            service: "com.theboringteam.boringnotch.clicky.tests.\(UUID().uuidString)"
        )
        defer { store.removeKey(for: .anthropic) }

        XCTAssertNil(store.loadKey(for: .anthropic))

        try store.saveKey("anthropic-test-key", for: .anthropic)

        XCTAssertEqual(store.loadKey(for: .anthropic), "anthropic-test-key")
    }

    func testKeychainKeyStoreRemoveDeletesSavedKey() throws {
        let store = KeychainKeyStore(
            service: "com.theboringteam.boringnotch.clicky.tests.\(UUID().uuidString)"
        )
        defer { store.removeKey(for: .openAI) }

        try store.saveKey("openai-test-key", for: .openAI)
        XCTAssertEqual(store.loadKey(for: .openAI), "openai-test-key")

        store.removeKey(for: .openAI)

        XCTAssertNil(store.loadKey(for: .openAI))
    }
}
