# BoringNotch Clicky MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a safe `Clicky` MVP tab to BoringNotch with local-only user API keys for Anthropic, OpenAI, and Gemini, without importing Clicky's proxy, onboarding, voice, or overlay stack.

**Architecture:** Keep BoringNotch as the only host app and add an isolated `Clicky` feature module under the existing app target. The notch UI only learns about one new tab and one new content branch; all provider logic, key storage, and chat state live behind a dedicated view model and provider client layer.

**Tech Stack:** SwiftUI, AppKit, Defaults, Security framework (Keychain), URLSession, Xcode macOS app target

---

## File Map

### Existing Files To Modify

- `boring.notch-main/boringNotch/enums/generic.swift`
  - Add `NotchViews.clicky`
- `boring.notch-main/boringNotch/components/Tabs/TabSelectionView.swift`
  - Add the `Clicky` tab entry
- `boring.notch-main/boringNotch/ContentView.swift`
  - Add a `switch` branch for `ClickyTabView()`
- `boring.notch-main/boringNotch/models/Constants.swift`
  - Add `Defaults` keys for selected provider and selected model values

### New Files To Create

- `boring.notch-main/boringNotch/components/Clicky/Models/AIProvider.swift`
- `boring.notch-main/boringNotch/components/Clicky/Models/AIModelOption.swift`
- `boring.notch-main/boringNotch/components/Clicky/Models/ChatMessage.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/AIProviderClient.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/AnthropicClient.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/OpenAIClient.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/GeminiClient.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/KeychainKeyStore.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/AIProviderClientFactory.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyViewModel.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyTabView.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyResponseView.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyComposerView.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyProviderPicker.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyModelPicker.swift`

### Optional Test Files If A Test Target Is Added

The current repo does not show an existing BoringNotch test target. If you add one in Xcode during implementation, use these files:

- `boring.notch-main/boringNotchTests/ClickyViewModelTests.swift`
- `boring.notch-main/boringNotchTests/AIProviderClientFactoryTests.swift`

If you do not add a test target, complete the manual verification steps in Task 6 and do not widen scope further.

## Task 1: Add The Clicky Navigation Shell

**Files:**
- Modify: `boring.notch-main/boringNotch/enums/generic.swift`
- Modify: `boring.notch-main/boringNotch/components/Tabs/TabSelectionView.swift`
- Modify: `boring.notch-main/boringNotch/ContentView.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/ClickyTabView.swift`

- [ ] **Step 1: Add the new notch view enum case**

Update `NotchViews` in `generic.swift`:

```swift
public enum NotchViews {
    case home
    case shelf
    case clicky
}
```

- [ ] **Step 2: Add the `Clicky` tab button**

Update the `tabs` array in `TabSelectionView.swift`:

```swift
let tabs = [
    TabModel(label: "Home", icon: "house.fill", view: .home),
    TabModel(label: "Shelf", icon: "tray.fill", view: .shelf),
    TabModel(label: "Clicky", icon: "message.fill", view: .clicky)
]
```

- [ ] **Step 3: Create a compile-safe placeholder tab view**

Create `ClickyTabView.swift`:

```swift
import SwiftUI

struct ClickyTabView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)

            Text("Clicky")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Text("Local-key chat UI goes here.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }
}
```

- [ ] **Step 4: Wire the new tab into `ContentView.swift`**

Update the notch content switch:

```swift
switch coordinator.currentView {
case .home:
    NotchHomeView(albumArtNamespace: albumArtNamespace)
case .shelf:
    ShelfView()
case .clicky:
    ClickyTabView()
}
```

- [ ] **Step 5: Add the new file to the Xcode app target if needed**

Run:

```bash
open boring.notch-main/boringNotch.xcodeproj
```

Expected:

- Xcode opens the project
- `ClickyTabView.swift` appears in the project navigator
- the file is included in the `boringNotch` target build phase if the project does not auto-pick it up

- [ ] **Step 6: Build in Xcode to confirm the navigation shell compiles**

Run this verification in Xcode, not the terminal:

```text
Build the boringNotch scheme with Cmd+B
```

Expected:

- the scheme builds
- the only visible product change is a third `Clicky` tab

- [ ] **Step 7: Commit the navigation shell**

```bash
git add boring.notch-main/boringNotch/enums/generic.swift \
  boring.notch-main/boringNotch/components/Tabs/TabSelectionView.swift \
  boring.notch-main/boringNotch/ContentView.swift \
  boring.notch-main/boringNotch/components/Clicky/ClickyTabView.swift
git commit -m "feat: add Clicky notch tab shell"
```

## Task 2: Add Provider Models And Secret Storage

**Files:**
- Create: `boring.notch-main/boringNotch/components/Clicky/Models/AIProvider.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/Models/AIModelOption.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/Models/ChatMessage.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/Services/KeychainKeyStore.swift`
- Modify: `boring.notch-main/boringNotch/models/Constants.swift`

- [ ] **Step 1: Define provider and model metadata types**

Create `AIProvider.swift`:

```swift
import Foundation
import Defaults

enum AIProvider: String, CaseIterable, Identifiable, Defaults.Serializable {
    case anthropic
    case openAI
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic:
            return "Anthropic"
        case .openAI:
            return "OpenAI"
        case .gemini:
            return "Gemini"
        }
    }
}
```

Create `AIModelOption.swift`:

```swift
import Foundation

struct AIModelOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let provider: AIProvider
}
```

Create `ChatMessage.swift`:

```swift
import Foundation

struct ChatMessage: Identifiable, Hashable {
    enum Role {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    let text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}
```

- [ ] **Step 2: Add persisted non-secret preferences to `Defaults`**

Append these keys in `Constants.swift`:

```swift
extension Defaults.Keys {
    static let clickySelectedProvider = Key<AIProvider>(
        "clickySelectedProvider",
        default: .anthropic
    )

    static let clickySelectedAnthropicModel = Key<String>(
        "clickySelectedAnthropicModel",
        default: "claude-sonnet-4-5"
    )

    static let clickySelectedOpenAIModel = Key<String>(
        "clickySelectedOpenAIModel",
        default: "gpt-4.1"
    )

    static let clickySelectedGeminiModel = Key<String>(
        "clickySelectedGeminiModel",
        default: "gemini-2.5-pro"
    )
}
```

- [ ] **Step 3: Implement a minimal Keychain wrapper**

Create `KeychainKeyStore.swift`:

```swift
import Foundation
import Security

struct KeychainKeyStore {
    private let service = "com.theboringteam.boringnotch.clicky"

    func saveKey(_ apiKey: String, for provider: AIProvider) throws {
        let encodedValue = Data(apiKey.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]

        SecItemDelete(query as CFDictionary)

        var insertQuery = query
        insertQuery[kSecValueData as String] = encodedValue

        let status = SecItemAdd(insertQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    func loadKey(for provider: AIProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }

        return apiKey
    }

    func removeKey(for provider: AIProvider) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]

        SecItemDelete(query as CFDictionary)
    }
}
```

- [ ] **Step 4: Build in Xcode and check diagnostics**

Run:

```text
Build the boringNotch scheme with Cmd+B
```

Expected:

- the new models and key store compile cleanly
- no security or `Defaults.Serializable` issues appear in edited files

- [ ] **Step 5: Commit the storage layer**

```bash
git add boring.notch-main/boringNotch/models/Constants.swift \
  boring.notch-main/boringNotch/components/Clicky/Models/AIProvider.swift \
  boring.notch-main/boringNotch/components/Clicky/Models/AIModelOption.swift \
  boring.notch-main/boringNotch/components/Clicky/Models/ChatMessage.swift \
  boring.notch-main/boringNotch/components/Clicky/Services/KeychainKeyStore.swift
git commit -m "feat: add Clicky provider models and key storage"
```

## Task 3: Implement Direct Provider Clients

**Files:**
- Create: `boring.notch-main/boringNotch/components/Clicky/Services/AIProviderClient.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/Services/AnthropicClient.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/Services/OpenAIClient.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/Services/GeminiClient.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/Services/AIProviderClientFactory.swift`

- [ ] **Step 1: Define the provider client contract**

Create `AIProviderClient.swift`:

```swift
import Foundation

enum AIProviderClientError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidResponse
    case networkFailure(String)
    case providerFailure(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an API key before sending a prompt."
        case .invalidResponse:
            return "The provider returned an invalid response."
        case .networkFailure(let message):
            return message
        case .providerFailure(let message):
            return message
        }
    }
}

protocol AIProviderClient {
    var provider: AIProvider { get }
    var supportedModels: [AIModelOption] { get }
    func sendMessage(_ prompt: String, modelID: String, apiKey: String) async throws -> String
}
```

- [ ] **Step 2: Implement the Anthropic text client**

Create `AnthropicClient.swift`:

```swift
import Foundation

struct AnthropicClient: AIProviderClient {
    let provider: AIProvider = .anthropic

    let supportedModels: [AIModelOption] = [
        AIModelOption(id: "claude-sonnet-4-5", displayName: "Claude Sonnet 4.5", provider: .anthropic),
        AIModelOption(id: "claude-opus-4-1", displayName: "Claude Opus 4.1", provider: .anthropic)
    ]

    func sendMessage(_ prompt: String, modelID: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Anthropic request failed."
            throw AIProviderClientError.providerFailure(message)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = json?["content"] as? [[String: Any]]
        let text = content?.first?["text"] as? String

        guard let text else {
            throw AIProviderClientError.invalidResponse
        }

        return text
    }
}
```

- [ ] **Step 3: Implement the OpenAI text client**

Create `OpenAIClient.swift`:

```swift
import Foundation

struct OpenAIClient: AIProviderClient {
    let provider: AIProvider = .openAI

    let supportedModels: [AIModelOption] = [
        AIModelOption(id: "gpt-4.1", displayName: "GPT-4.1", provider: .openAI),
        AIModelOption(id: "gpt-4o", displayName: "GPT-4o", provider: .openAI)
    ]

    func sendMessage(_ prompt: String, modelID: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": modelID,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "OpenAI request failed."
            throw AIProviderClientError.providerFailure(message)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let text = message?["content"] as? String

        guard let text else {
            throw AIProviderClientError.invalidResponse
        }

        return text
    }
}
```

- [ ] **Step 4: Implement the Gemini text client and factory**

Create `GeminiClient.swift`:

```swift
import Foundation

struct GeminiClient: AIProviderClient {
    let provider: AIProvider = .gemini

    let supportedModels: [AIModelOption] = [
        AIModelOption(id: "gemini-2.5-pro", displayName: "Gemini 2.5 Pro", provider: .gemini),
        AIModelOption(id: "gemini-2.5-flash", displayName: "Gemini 2.5 Flash", provider: .gemini)
    ]

    func sendMessage(_ prompt: String, modelID: String, apiKey: String) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelID):generateContent?key=\(apiKey)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Gemini request failed."
            throw AIProviderClientError.providerFailure(message)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        let text = parts?.first?["text"] as? String

        guard let text else {
            throw AIProviderClientError.invalidResponse
        }

        return text
    }
}
```

Create `AIProviderClientFactory.swift`:

```swift
import Foundation

struct AIProviderClientFactory {
    func makeClient(for provider: AIProvider) -> AIProviderClient {
        switch provider {
        case .anthropic:
            return AnthropicClient()
        case .openAI:
            return OpenAIClient()
        case .gemini:
            return GeminiClient()
        }
    }
}
```

- [ ] **Step 5: Build in Xcode and verify provider code compiles**

Run:

```text
Build the boringNotch scheme with Cmd+B
```

Expected:

- the app target compiles
- no references to Clicky's worker or standalone app manager exist in the new code

- [ ] **Step 6: Commit the direct provider layer**

```bash
git add boring.notch-main/boringNotch/components/Clicky/Services/AIProviderClient.swift \
  boring.notch-main/boringNotch/components/Clicky/Services/AnthropicClient.swift \
  boring.notch-main/boringNotch/components/Clicky/Services/OpenAIClient.swift \
  boring.notch-main/boringNotch/components/Clicky/Services/GeminiClient.swift \
  boring.notch-main/boringNotch/components/Clicky/Services/AIProviderClientFactory.swift
git commit -m "feat: add direct Clicky provider clients"
```

## Task 4: Build The Clicky View Model

**Files:**
- Create: `boring.notch-main/boringNotch/components/Clicky/ClickyViewModel.swift`

- [ ] **Step 1: Create the view model state surface**

Create `ClickyViewModel.swift`:

```swift
import Defaults
import Foundation

@MainActor
final class ClickyViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var draftPrompt: String = ""
    @Published var isSending = false
    @Published var apiKeyInput = ""
    @Published var errorMessage: String?

    @Default(.clickySelectedProvider) var selectedProvider
    @Default(.clickySelectedAnthropicModel) private var anthropicModel
    @Default(.clickySelectedOpenAIModel) private var openAIModel
    @Default(.clickySelectedGeminiModel) private var geminiModel

    private let keyStore = KeychainKeyStore()
    private let clientFactory = AIProviderClientFactory()

    var availableModels: [AIModelOption] {
        clientFactory.makeClient(for: selectedProvider).supportedModels
    }

    var selectedModelID: String {
        get {
            switch selectedProvider {
            case .anthropic:
                return anthropicModel
            case .openAI:
                return openAIModel
            case .gemini:
                return geminiModel
            }
        }
        set {
            switch selectedProvider {
            case .anthropic:
                anthropicModel = newValue
            case .openAI:
                openAIModel = newValue
            case .gemini:
                geminiModel = newValue
            }
        }
    }
}
```

- [ ] **Step 2: Add key-management helpers**

Extend `ClickyViewModel.swift` with:

```swift
extension ClickyViewModel {
    var hasSavedKey: Bool {
        keyStore.loadKey(for: selectedProvider)?.isEmpty == false
    }

    func reloadKeyState() {
        apiKeyInput = ""
        errorMessage = nil
    }

    func saveAPIKey() {
        let trimmedAPIKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAPIKey.isEmpty else {
            errorMessage = "Enter an API key before saving."
            return
        }

        do {
            try keyStore.saveKey(trimmedAPIKey, for: selectedProvider)
            apiKeyInput = ""
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save API key."
        }
    }

    func removeAPIKey() {
        keyStore.removeKey(for: selectedProvider)
        apiKeyInput = ""
        errorMessage = nil
    }
}
```

- [ ] **Step 3: Add send-message behavior**

Extend `ClickyViewModel.swift` with:

```swift
extension ClickyViewModel {
    func sendCurrentPrompt() async {
        let trimmedPrompt = draftPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        guard let apiKey = keyStore.loadKey(for: selectedProvider), !apiKey.isEmpty else {
            errorMessage = "Add an API key before sending a prompt."
            return
        }

        let promptToSend = trimmedPrompt
        draftPrompt = ""
        errorMessage = nil
        isSending = true
        messages.append(ChatMessage(role: .user, text: promptToSend))

        do {
            let client = clientFactory.makeClient(for: selectedProvider)
            let responseText = try await client.sendMessage(
                promptToSend,
                modelID: selectedModelID,
                apiKey: apiKey
            )
            messages.append(ChatMessage(role: .assistant, text: responseText))
        } catch let error as AIProviderClientError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }
}
```

- [ ] **Step 4: Build in Xcode and manually inspect state transitions**

Run:

```text
Build the boringNotch scheme with Cmd+B
```

Expected:

- `ClickyViewModel` compiles
- selected provider changes the available model list
- saving or removing a key does not affect non-Clicky app settings

- [ ] **Step 5: Commit the view model**

```bash
git add boring.notch-main/boringNotch/components/Clicky/ClickyViewModel.swift
git commit -m "feat: add Clicky chat view model"
```

## Task 5: Build The Clicky Tab UI

**Files:**
- Modify: `boring.notch-main/boringNotch/components/Clicky/ClickyTabView.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/ClickyResponseView.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/ClickyComposerView.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/ClickyProviderPicker.swift`
- Create: `boring.notch-main/boringNotch/components/Clicky/ClickyModelPicker.swift`

- [ ] **Step 1: Create the response list view**

Create `ClickyResponseView.swift`:

```swift
import SwiftUI

struct ClickyResponseView: View {
    let messages: [ChatMessage]
    let errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(messages) { message in
                    Text(message.text)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(message.role == .user ? .white : .gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white.opacity(message.role == .user ? 0.10 : 0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}
```

- [ ] **Step 2: Create the provider and model pickers**

Create `ClickyProviderPicker.swift`:

```swift
import SwiftUI

struct ClickyProviderPicker: View {
    @Binding var selectedProvider: AIProvider

    var body: some View {
        Picker("Provider", selection: $selectedProvider) {
            ForEach(AIProvider.allCases) { provider in
                Text(provider.displayName).tag(provider)
            }
        }
        .pickerStyle(.menu)
    }
}
```

Create `ClickyModelPicker.swift`:

```swift
import SwiftUI

struct ClickyModelPicker: View {
    let models: [AIModelOption]
    @Binding var selectedModelID: String

    var body: some View {
        Picker("Model", selection: $selectedModelID) {
            ForEach(models) { model in
                Text(model.displayName).tag(model.id)
            }
        }
        .pickerStyle(.menu)
    }
}
```

- [ ] **Step 3: Create the composer**

Create `ClickyComposerView.swift`:

```swift
import SwiftUI

struct ClickyComposerView: View {
    @Binding var prompt: String
    let isSending: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Ask Clicky something...", text: $prompt, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: onSend) {
                Image(systemName: isSending ? "hourglass" : "paperplane.fill")
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isSending)
        }
    }
}
```

- [ ] **Step 4: Replace the placeholder tab with the real composed view**

Update `ClickyTabView.swift`:

```swift
import SwiftUI

struct ClickyTabView: View {
    @StateObject private var viewModel = ClickyViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ClickyProviderPicker(selectedProvider: $viewModel.selectedProvider)
                ClickyModelPicker(
                    models: viewModel.availableModels,
                    selectedModelID: Binding(
                        get: { viewModel.selectedModelID },
                        set: { viewModel.selectedModelID = $0 }
                    )
                )
            }

            if viewModel.hasSavedKey {
                HStack {
                    Text("API key saved")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.gray)

                    Spacer()

                    Button("Replace / Remove") {
                        viewModel.removeAPIKey()
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 8) {
                    SecureField("Paste your API key", text: $viewModel.apiKeyInput)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button("Save") {
                        viewModel.saveAPIKey()
                    }
                    .buttonStyle(.plain)
                }
            }

            ClickyResponseView(
                messages: viewModel.messages,
                errorMessage: viewModel.errorMessage
            )

            ClickyComposerView(
                prompt: $viewModel.draftPrompt,
                isSending: viewModel.isSending
            ) {
                Task {
                    await viewModel.sendCurrentPrompt()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: viewModel.selectedProvider) { _ in
            viewModel.reloadKeyState()
        }
    }
}
```

- [ ] **Step 5: Build in Xcode and check the notch layout manually**

Run:

```text
Build and run the boringNotch scheme in Xcode with Cmd+R
```

Expected:

- `Clicky` renders inside the notch open state
- provider picker, model picker, key UI, message area, and composer all appear
- switching away from `Clicky` leaves `Home` and `Shelf` behavior unchanged

- [ ] **Step 6: Commit the tab UI**

```bash
git add boring.notch-main/boringNotch/components/Clicky/ClickyTabView.swift \
  boring.notch-main/boringNotch/components/Clicky/ClickyResponseView.swift \
  boring.notch-main/boringNotch/components/Clicky/ClickyComposerView.swift \
  boring.notch-main/boringNotch/components/Clicky/ClickyProviderPicker.swift \
  boring.notch-main/boringNotch/components/Clicky/ClickyModelPicker.swift
git commit -m "feat: add Clicky notch chat interface"
```

## Task 6: Verify Direct-Key Behavior And Finish

**Files:**
- Modify as needed: `boring.notch-main/boringNotch/components/Clicky/ClickyViewModel.swift`
- Modify as needed: `boring.notch-main/boringNotch/components/Clicky/Services/*.swift`
- Optional Test: `boring.notch-main/boringNotchTests/*.swift`

- [ ] **Step 1: Manually verify saved-key behavior**

Run this in the app:

```text
Open Clicky -> choose Anthropic -> save a test key -> relaunch the app -> return to Clicky
```

Expected:

- the key does not display in plain text
- the UI shows a saved-key state after relaunch
- the rest of BoringNotch behaves exactly as before

- [ ] **Step 2: Manually verify plain provider error handling**

Run this in the app:

```text
Save an intentionally invalid key and send a short prompt like "hello"
```

Expected:

- the request fails inside the `Clicky` tab
- the UI shows a plain provider error
- no pricing, credits, paywall, or upgrade messaging appears

- [ ] **Step 3: Manually verify a successful direct request with a real key**

Run this in the app:

```text
Save a valid provider key and send "reply with exactly the word ok"
```

Expected:

- the provider responds directly
- the result appears in the response area
- no proxy configuration is required

- [ ] **Step 4: If you added a test target, add focused view-model tests**

Create `ClickyViewModelTests.swift`:

```swift
import XCTest
@testable import boringNotch

final class ClickyViewModelTests: XCTestCase {
    @MainActor
    func testMissingKeyBlocksSend() async {
        let viewModel = ClickyViewModel()
        viewModel.selectedProvider = .anthropic
        viewModel.draftPrompt = "hello"
        viewModel.removeAPIKey()

        await viewModel.sendCurrentPrompt()

        XCTAssertEqual(viewModel.errorMessage, "Add an API key before sending a prompt.")
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
}
```

Create `AIProviderClientFactoryTests.swift`:

```swift
import XCTest
@testable import boringNotch

final class AIProviderClientFactoryTests: XCTestCase {
    func testFactoryReturnsAnthropicClient() {
        let client = AIProviderClientFactory().makeClient(for: .anthropic)
        XCTAssertEqual(client.provider, .anthropic)
    }
}
```

- [ ] **Step 5: Final diagnostics and final commit**

Run:

```bash
git status --short
```

Expected:

- only intentional Clicky MVP files are modified

Then, after final review, commit:

```bash
git add boring.notch-main/boringNotch/enums/generic.swift \
  boring.notch-main/boringNotch/components/Tabs/TabSelectionView.swift \
  boring.notch-main/boringNotch/ContentView.swift \
  boring.notch-main/boringNotch/models/Constants.swift \
  boring.notch-main/boringNotch/components/Clicky
git commit -m "feat: add local-key Clicky tab to BoringNotch"
```

## Self-Review Checklist

- Spec coverage:
  - `Clicky` tab added to BoringNotch navigation: Tasks 1 and 5
  - local-only user API keys: Tasks 2, 4, and 6
  - direct provider access for Anthropic, OpenAI, Gemini: Task 3
  - no proxy, onboarding, voice, overlay, or pricing UI merge: Tasks 3, 5, and 6
  - isolated implementation boundary: Tasks 2 through 5
- Placeholder scan:
  - no `TODO`, `TBD`, or vague “handle later” steps remain
- Type consistency:
  - `AIProvider`, `AIModelOption`, `ChatMessage`, `ClickyViewModel`, and `AIProviderClientFactory` names stay consistent across all tasks
