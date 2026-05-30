//
//  ClickyAnalytics.swift
//  Clicky (merged into boringNotch)
//
//  Centralized analytics wrapper.
//
//  NOTE: PostHog is treated as an optional dependency in boringNotch.
//  If PostHog is not linked, these calls compile and become no-ops.
//

import Foundation

#if canImport(PostHog)
import PostHog
#endif

enum ClickyAnalytics {

    private static var isEnabled: Bool {
        AppBundleConfiguration.boolValue(forKey: "CLICKY_ENABLE_ANALYTICS", default: false)
    }

    // MARK: - Setup

    static func configure() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        let config = PostHogConfig(
            apiKey: "phc_xcQPygmhTMzzYh8wNW92CCwoXmnzqyChAixh8zgpqC3C",
            host: "https://us.i.posthog.com"
        )
        PostHogSDK.shared.setup(config)
        #else
        // no-op
        #endif
    }

    // MARK: - App Lifecycle

    /// Fired once on every app launch in applicationDidFinishLaunching.
    static func trackAppOpened() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        PostHogSDK.shared.capture("app_opened", properties: [
            "app_version": version
        ])
        #else
        // no-op
        #endif
    }

    // MARK: - Onboarding

    /// User clicked the Start button to begin onboarding for the first time.
    static func trackOnboardingStarted() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("onboarding_started")
        #endif
    }

    /// User clicked "Watch Onboarding Again" from the panel footer.
    static func trackOnboardingReplayed() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("onboarding_replayed")
        #endif
    }

    /// The onboarding video finished playing to the end.
    static func trackOnboardingVideoCompleted() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("onboarding_video_completed")
        #endif
    }

    /// The 40s onboarding demo interaction where Clicky points at something.
    static func trackOnboardingDemoTriggered() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("onboarding_demo_triggered")
        #endif
    }

    // MARK: - Permissions

    /// All three permissions (accessibility, screen recording, mic) are granted.
    static func trackAllPermissionsGranted() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("all_permissions_granted")
        #endif
    }

    /// A single permission was granted. Called when polling detects a change.
    static func trackPermissionGranted(permission: String) {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("permission_granted", properties: [
            "permission": permission
        ])
        #endif
    }

    // MARK: - Voice Interaction

    /// User pressed the push-to-talk shortcut (control+option) to start talking.
    static func trackPushToTalkStarted() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("push_to_talk_started")
        #endif
    }

    /// User released the shortcut — transcript is being finalized.
    static func trackPushToTalkReleased() {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("push_to_talk_released")
        #endif
    }

    /// Transcription completed and the user's message is being sent to the AI.
    static func trackUserMessageSent(transcript: String) {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("user_message_sent", properties: [
            "transcript": transcript,
            "character_count": transcript.count
        ])
        #endif
    }

    /// Claude responded and the response is being spoken via TTS.
    static func trackAIResponseReceived(response: String) {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("ai_response_received", properties: [
            "response": response,
            "character_count": response.count
        ])
        #endif
    }

    /// Claude's response included a [POINT:x,y:label] coordinate tag,
    /// so the buddy is flying to point at a UI element.
    static func trackElementPointed(elementLabel: String?) {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("element_pointed", properties: [
            "element_label": elementLabel ?? "unknown"
        ])
        #endif
    }

    // MARK: - Errors

    /// An error occurred during the AI response pipeline.
    static func trackResponseError(error: String) {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("response_error", properties: [
            "error": error
        ])
        #endif
    }

    /// An error occurred during TTS playback.
    static func trackTTSError(error: String) {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.capture("tts_error", properties: [
            "error": error
        ])
        #endif
    }

    // MARK: - Identity

    static func identify(email: String) {
        guard isEnabled else { return }
        #if canImport(PostHog)
        PostHogSDK.shared.identify(email, userProperties: [
            "email": email
        ])
        #endif
    }
}
