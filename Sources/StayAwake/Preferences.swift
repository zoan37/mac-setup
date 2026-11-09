import Foundation

let bundleID = Bundle.main.bundleIdentifier ?? "com.zoan.StayAwake"

/// The Mac equivalent of Omarchy's `~/.local/state/omarchy/indicators/stay-awake` file.
enum Preferences {
    private static let defaults = UserDefaults.standard

    /// First launch defaults to ON: the whole point is not having to remember.
    static func registerDefaults() {
        defaults.register(defaults: ["stayAwake": true])
    }

    /// The last on/off choice. Re-applied on every launch, so it survives reboots.
    static var stayAwake: Bool {
        get { defaults.bool(forKey: "stayAwake") }
        set { defaults.set(newValue, forKey: "stayAwake") }
    }

    /// Set once the app has registered itself as a login item, so that turning
    /// "Open at Login" off later is respected instead of being re-enabled.
    static var didSetUpLoginItem: Bool {
        get { defaults.bool(forKey: "didSetUpLoginItem") }
        set { defaults.set(newValue, forKey: "didSetUpLoginItem") }
    }
}
