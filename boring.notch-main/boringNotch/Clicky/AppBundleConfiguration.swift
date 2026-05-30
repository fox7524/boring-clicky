//
//  AppBundleConfiguration.swift
//  leanring-buddy
//
//  Shared helper for reading runtime configuration from the built app bundle.
//

import Foundation

enum AppBundleConfiguration {
    static func stringValue(forKey key: String) -> String? {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedValue.isEmpty,
               !(trimmedValue.hasPrefix("$(") && trimmedValue.hasSuffix(")")) {
                return trimmedValue
            }
        }

        guard let resourceInfoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let resourceInfo = NSDictionary(contentsOfFile: resourceInfoPath),
              let value = resourceInfo[key] as? String else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }
        guard !(trimmedValue.hasPrefix("$(") && trimmedValue.hasSuffix(")")) else { return nil }
        return trimmedValue
    }

    static func boolValue(forKey key: String, default defaultValue: Bool) -> Bool {
        if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? Bool {
            return raw
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let v = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if v == "true" || v == "1" || v == "yes" { return true }
            if v == "false" || v == "0" || v == "no" { return false }
        }

        guard let resourceInfoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let resourceInfo = NSDictionary(contentsOfFile: resourceInfoPath),
              let raw = resourceInfo[key] else {
            return defaultValue
        }

        if let v = raw as? Bool { return v }
        if let v = raw as? String {
            let s = v.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if s == "true" || s == "1" || s == "yes" { return true }
            if s == "false" || s == "0" || s == "no" { return false }
        }

        return defaultValue
    }
}
