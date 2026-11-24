import SwiftUI

enum Language: String, CaseIterable, Identifiable {
    case russian
    case english
    case system

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .russian: "Русский"
        case .english: "English"
        case .system: "System"
        }
    }

    var locale: Locale {
        switch self {
        case .russian: Locale(identifier: "ru")
        case .english: Locale(identifier: "en")
        case .system: .autoupdatingCurrent
        }
    }
}
