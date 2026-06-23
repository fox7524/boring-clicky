# BoringNotch + Clicky Merge Design

## Goal

Merge a safe MVP of Clicky into BoringNotch without destabilizing the existing notch app.

The merged result should:

- keep BoringNotch as the host app
- add a new `Clicky` tab beside the existing `Main` and `Shelf` tabs
- support direct use of user-supplied provider API keys
- avoid Clicky's current proxy/backend dependency
- avoid any pricing, credits, quota upsell, or limit messaging in the product UI
- keep the implementation isolated so existing BoringNotch behavior does not regress

## Non-Goals

The first version does not attempt to:

- merge Clicky's full menu bar app shell into BoringNotch
- reuse Clicky's onboarding, email capture, analytics, or cursor overlay
- ship voice mode, push-to-talk, screen capture, or pointing features
- support every possible AI vendor on day one
- build long-term conversation persistence

## Existing Code Context

### BoringNotch

Relevant BoringNotch integration points:

- `boring.notch-main/boringNotch/components/Tabs/TabSelectionView.swift`
- `boring.notch-main/boringNotch/components/Notch/BoringHeader.swift`
- `boring.notch-main/boringNotch/enums/generic.swift`
- `boring.notch-main/boringNotch/BoringViewCoordinator.swift`
- `boring.notch-main/boringNotch/ContentView.swift`

BoringNotch already has a small tab navigation model and a content switch based on `NotchViews`. This makes it a good host for a third isolated tab.

### Clicky

Relevant Clicky reference files:

- `clicky-main/leanring-buddy/CompanionManager.swift`
- `clicky-main/leanring-buddy/CompanionPanelView.swift`
- `clicky-main/leanring-buddy/ClaudeAPI.swift`
- `clicky-main/leanring-buddy/OpenAIAPI.swift`
- `clicky-main/worker/src/index.ts`

Clicky's current architecture is strongly coupled to:

- a separate menu bar app shell
- onboarding and email collection
- analytics
- voice interaction
- screenshot/context flow
- Cloudflare Worker proxy URLs

That architecture is not appropriate to import directly into BoringNotch for the agreed MVP.

## Chosen Product Direction

### Interaction Model

Use a hybrid-feeling integration with a true `Clicky` tab inside BoringNotch, but scope the first version to an MVP text chat experience. The tab is part of the notch UI, not a separate Clicky window or full Clicky runtime transplant.

### API Key Model

Use local-only API keys.

Requests go directly from the app to the selected provider using the user's own API key. There is no required backend proxy, no fallback worker, and no product-managed key path in v1.

### First-Version Feature Scope

The MVP `Clicky` tab includes:

- provider picker
- model picker
- secure API key entry and saved-key management
- prompt input
- response area
- inline loading and error states

The MVP does not include:

- voice input
- screenshots or multimodal context capture
- cursor overlay behavior
- onboarding flows
- pricing or subscription messaging

## Architecture

### High-Level Boundary

The implementation should follow this boundary:

`BoringNotch UI` -> `Clicky tab state/view model` -> `provider service layer` -> `direct provider API`

This separation keeps the feature additive and minimizes the risk of regressions in the existing notch lifecycle, window handling, and shelf behavior.

### Why Not Reuse `CompanionManager`

`CompanionManager` is not a good fit for the MVP merge because it currently owns unrelated responsibilities:

- permissions state
- overlay window control
- push-to-talk pipeline
- onboarding state
- proxy-based Claude access
- text-to-speech
- analytics

Importing that manager would pull Clicky's old assumptions into BoringNotch and increase the chance of product and lifecycle bugs.

### Recommended Module Shape Inside BoringNotch

Add a small, isolated feature area under the BoringNotch app target for Clicky-related code. Example structure:

- `boring.notch-main/boringNotch/components/Clicky/ClickyTabView.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyResponseView.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyComposerView.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyProviderPicker.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyModelPicker.swift`
- `boring.notch-main/boringNotch/components/Clicky/ClickyViewModel.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/AIProviderClient.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/AnthropicClient.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/OpenAIClient.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/GeminiClient.swift`
- `boring.notch-main/boringNotch/components/Clicky/Services/KeychainKeyStore.swift`
- `boring.notch-main/boringNotch/components/Clicky/Models/AIProvider.swift`
- `boring.notch-main/boringNotch/components/Clicky/Models/AIModelOption.swift`
- `boring.notch-main/boringNotch/components/Clicky/Models/ChatMessage.swift`

The exact file breakdown can vary, but the boundaries should remain the same.

## BoringNotch Integration Plan

### Navigation

Extend `NotchViews` with a new case:

- `clicky`

Update the tab list in `TabSelectionView.swift` to include a third tab labeled `Clicky`.

Update the content switch in `ContentView.swift` to render a dedicated `Clicky` view when `coordinator.currentView == .clicky`.

### Scope of BoringNotch Changes

BoringNotch changes should stay narrow:

- one new enum case
- one new tab entry
- one new switch branch in the notch content view
- optional small layout adjustments if the third tab needs spacing refinement

Avoid broad edits to:

- notch open/close lifecycle
- shelf behavior
- drag/drop handling
- media widgets
- settings unrelated to Clicky

## Settings And Secret Storage

### Storage Rules

Persist non-secret preferences in app settings:

- selected provider
- selected model per provider if desired

Persist provider API keys in macOS Keychain, not plain `UserDefaults`.

This split keeps secrets out of normal preference storage while still preserving a convenient UX.

### Supported Providers In MVP

Support these providers first:

- Anthropic
- OpenAI
- Google Gemini

This satisfies the user's stated need for user-owned API keys while keeping the initial implementation bounded. The provider abstraction should make future providers additive rather than disruptive.

### Product Copy Rules

The tab UI should make the ownership model explicit:

- requests use the user's own API key
- requests are sent directly to the selected provider

The tab UI must not introduce:

- upgrade prompts
- credits messaging
- subscription copy
- paywall language
- artificial usage limit UI

If a provider returns a billing or quota error, show it as a plain API error message rather than as product upsell.

## Provider Service Layer

### Contract

Define a common client contract that the tab view model uses regardless of provider.

Suggested responsibilities:

- validate provider configuration
- submit a text prompt
- optionally stream text if the provider supports it
- normalize provider errors into a small UI-friendly set
- expose available models for the selected provider

### MVP Request Type

The MVP is text chat only.

Do not start by reusing Clicky's image-analysis request shape, because Clicky's current `ClaudeAPI` and `OpenAIAPI` code is optimized around screenshot plus prompt payloads. That is useful as reference, but it is the wrong starting contract for the agreed product scope.

Instead:

- Anthropic client should call Anthropic's direct text API with the user's key
- OpenAI client should call OpenAI's direct chat API with the user's key
- Gemini client should call Google's Gemini API with the user's key

### Error Normalization

Normalize errors into a few categories:

- missing API key
- invalid API key
- network failure
- provider quota or billing failure
- malformed response
- unsupported model selection

The raw provider message can still be shown in a detail area if helpful, but the UI state should not depend on provider-specific parsing everywhere.

## UI Design

### Layout

The `Clicky` tab should feel like part of BoringNotch rather than a transplanted second app.

Recommended notch-friendly layout:

- top controls row with provider picker and model picker
- compact key status row below it
- central response/history region
- bottom composer row with prompt input and send action

### Key Management UX

If no key exists for the selected provider:

- show a secure input field
- show a clear save action

If a key exists:

- show a compact saved state such as `API key saved`
- allow replace
- allow remove

Avoid noisy onboarding or marketing copy in this tab.

### Conversation Scope

For v1, keep conversation state session-local and in memory.

This means:

- messages stay available while the app is running
- no long-term transcript persistence is required
- no cross-device or multi-session sync exists

This is the right trade-off for a safe first merge.

## Data Flow

### Send Flow

1. User opens the `Clicky` tab.
2. User selects a provider.
3. UI loads the model list for that provider.
4. UI checks whether a saved key exists for that provider.
5. User enters or replaces an API key if needed.
6. User types a prompt and sends it.
7. View model validates provider, model, and key availability.
8. The provider client sends the request directly to the provider API.
9. The UI updates loading state and progressively renders streamed text when supported.
10. The final response is appended to the in-memory conversation state.

### Tab Switching Behavior

Switching between `Main`, `Shelf`, and `Clicky` should only affect the rendered notch content. It should not change BoringNotch's core window or coordinator behavior beyond the selected tab value.

## Failure Handling

### Expected Errors

Handle these cases explicitly:

- no API key saved for selected provider
- invalid API key
- no network connectivity
- provider-side rate or quota rejection
- unsupported model
- cancellation while a request is in flight

### UI Rules

Errors should:

- appear inline inside the `Clicky` tab
- be actionable when possible
- stay local to the feature
- never trigger unrelated notch state changes

Do not convert provider billing failures into app-owned pricing UI. The app should report what the provider said and stop there.

## Testing Strategy

### Automated Tests

Add focused tests where they reduce regression risk:

- provider selection changes model options correctly
- missing-key validation blocks send
- view model transitions through idle/loading/success/error states correctly
- provider error mapping produces the expected user-facing state

Avoid broad or low-value tests that merely restate the UI.

### Manual Verification

Verify:

- existing `Home` behavior still works
- existing `Shelf` behavior still works
- the new `Clicky` tab appears and switches correctly
- keys save and reload correctly
- direct API requests succeed with user-owned keys
- provider errors show as plain errors without upgrade or quota-marketing UI

## Risks And Mitigations

### Risk: Over-importing Clicky

If the implementation starts pulling in Clicky's full runtime, complexity and regression risk will increase quickly.

Mitigation:

- keep the merge text-chat-only
- reuse only targeted provider/client ideas
- keep the new feature behind its own view model and services

### Risk: Secret Storage Mistakes

Storing keys in plain preferences would create avoidable security and cleanup issues.

Mitigation:

- use Keychain for provider keys
- keep provider/model selection in normal app settings

### Risk: Provider API Drift

Provider request shapes and models can drift over time.

Mitigation:

- isolate provider-specific logic behind separate clients
- keep the UI contract provider-agnostic

## Implementation Boundaries

The first implementation pass should not:

- touch Clicky's worker
- merge Clicky's standalone app target into BoringNotch
- add voice/cursor/screenshot features
- build a new backend
- refactor unrelated BoringNotch systems

If future work expands the feature, it should happen as separate scoped iterations after the MVP text tab is stable.

## Success Criteria

This design is successful when:

- BoringNotch still behaves normally for existing users
- a third `Clicky` tab exists in the notch UI
- the tab supports direct user-owned API keys
- the tab can send prompts to at least Anthropic, OpenAI, and Gemini
- no backend worker is required
- no pricing or artificial limit UI appears in local-key mode
- the new feature remains isolated enough that future Clicky work does not force large-scale BoringNotch refactors
