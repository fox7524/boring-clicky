import SwiftUI

/// Icon abstraction for tabs. Home/Shelf use SF Symbols; Clicky uses a custom shape.
enum TabIcon {
    case sfSymbol(String)
    case custom(AnyView)
}

extension TabIcon {
    @ViewBuilder
    func render() -> some View {
        switch self {
        case .sfSymbol(let systemName):
            Image(systemName: systemName)
        case .custom(let view):
            view
        }
    }
}

