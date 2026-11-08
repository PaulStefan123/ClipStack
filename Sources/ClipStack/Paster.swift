import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Simulates ⌘V in the frontmost app. Requires Accessibility permission.
enum Paster {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that sends the user to
    /// System Settings › Privacy & Security › Accessibility.
    static func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private static var didPromptThisLaunch = false

    static func pasteIntoFrontApp() {
        guard isTrusted else {
            // The item is already on the clipboard, so ⌘V still works by hand.
            // Only nag once per launch instead of on every paste.
            if !didPromptThisLaunch {
                didPromptThisLaunch = true
                requestAccess()
            }
            return
        }
        let source = CGEventSource(stateID: .combinedSessionState)
        let key = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
    }
}
