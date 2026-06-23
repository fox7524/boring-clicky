import Foundation

struct AIModelOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let provider: AIProvider
}
