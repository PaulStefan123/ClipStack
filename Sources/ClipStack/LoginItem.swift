import Foundation
import ServiceManagement

/// "Open at Login" via the modern ServiceManagement API (macOS 13+).
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    static var needsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    /// Turns launch-at-login on the first time the app runs from an Applications
    /// folder (/Applications or ~/Applications), so a test run from the build
    /// folder doesn't register the wrong copy.
    static func enableOnFirstInstall() {
        let key = "didConfigureLoginItem"
        guard !UserDefaults.standard.bool(forKey: key),
              Bundle.main.bundlePath.contains("/Applications/") else { return }
        do {
            try setEnabled(true)
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            NSLog("ClipStack: could not enable launch at login: \(error)")
        }
    }
}
