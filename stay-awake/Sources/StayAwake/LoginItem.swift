import Foundation
import ServiceManagement

/// "Open at Login", backed by the modern SMAppService login-item API.
/// The entry shows up under System Settings > General > Login Items & Extensions.
enum LoginItem {
    static var status: SMAppService.Status { SMAppService.mainApp.status }

    static var statusText: String {
        switch status {
        case .enabled: return "enabled"
        case .requiresApproval: return "needs approval in System Settings > General > Login Items"
        case .notRegistered: return "off"
        case .notFound: return "not found"
        @unknown default: return "unknown"
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    /// Registers once, the first time the app runs from an Applications folder
    /// (never from the build directory, which would pin the login item there).
    static func registerOnFirstLaunch() {
        guard !Preferences.didSetUpLoginItem,
              Bundle.main.bundlePath.contains("/Applications/")
        else { return }
        do {
            try setEnabled(true)
            Preferences.didSetUpLoginItem = true
        } catch {
            NSLog("StayAwake: could not register login item: %@", error.localizedDescription)
        }
    }
}
