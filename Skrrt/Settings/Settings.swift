import Observation
import SwiftUI

@MainActor
@Observable
final class Settings {
    @ObservationIgnored private let defaults = UserDefaults.standard

    var appearance: Appearance {
        get {
            access(keyPath: \.appearance)
            return Appearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
        }
        set {
            withMutation(keyPath: \.appearance) { defaults.set(newValue.rawValue, forKey: Key.appearance) }
        }
    }

    var userAgent: UserAgentMode {
        get {
            access(keyPath: \.userAgent)
            return UserAgentMode(rawValue: defaults.string(forKey: Key.userAgent) ?? "") ?? .safari
        }
        set {
            withMutation(keyPath: \.userAgent) { defaults.set(newValue.rawValue, forKey: Key.userAgent) }
        }
    }

    var blocksContent: Bool {
        get {
            access(keyPath: \.blocksContent)
            return defaults.object(forKey: Key.blocksContent) as? Bool ?? true
        }
        set {
            withMutation(keyPath: \.blocksContent) { defaults.set(newValue, forKey: Key.blocksContent) }
        }
    }

    var hidesAddresses: Bool {
        get {
            access(keyPath: \.hidesAddresses)
            return defaults.bool(forKey: Key.hidesAddresses)
        }
        set {
            withMutation(keyPath: \.hidesAddresses) { defaults.set(newValue, forKey: Key.hidesAddresses) }
        }
    }

    private enum Key {
        static let appearance = "settings.appearance"
        static let userAgent = "settings.userAgent"
        static let blocksContent = "settings.blocksContent"
        static let hidesAddresses = "settings.hidesAddresses"
    }
}
