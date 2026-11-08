import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    /// Tries to register a new global shortcut; false if another app owns it.
    var applyShortcut: (Shortcut) -> Bool
    /// Pauses the global shortcut while a new one is being typed.
    var setRecording: (Bool) -> Void

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginMessage: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("Open clipboard") {
                    ShortcutRecorder(shortcut: settings.shortcut, onRecord: applyShortcut, setRecording: setRecording)
                }
                if settings.shortcut != .default {
                    HStack {
                        Spacer()
                        Button("Reset to \(Shortcut.default.displayString)") { _ = applyShortcut(.default) }
                            .buttonStyle(.link)
                    }
                }
            } header: {
                Text("Keyboard Shortcut")
            } footer: {
                Text("Click the shortcut, then press the new key combination. It must include ⌘, ⌥ or ⌃. Press Esc to cancel.")
                    .settingsFootnote()
            }

            Section {
                Toggle("Open ClipStack at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { setLaunchAtLogin($0) }
                ))
                if let loginMessage {
                    Text(loginMessage).settingsFootnote()
                }
            } header: {
                Text("Startup")
            }

            Section {
                Picker("Keep copies for", selection: $settings.retention) {
                    ForEach(Retention.allCases) { Text($0.title).tag($0) }
                }
            } header: {
                Text("History")
            } footer: {
                Text("Older copies are removed automatically. ClipStack never keeps more than the \(ClipboardStore.maxItems) latest copies.")
                    .settingsFootnote()
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { refreshLoginState() }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItem.setEnabled(enabled)
            refreshLoginState()
        } catch {
            refreshLoginState()
            loginMessage = "Couldn't change this: \(error.localizedDescription)"
        }
    }

    private func refreshLoginState() {
        launchAtLogin = LoginItem.isEnabled
        loginMessage = LoginItem.needsApproval
            ? "Allow ClipStack in System Settings › General › Login Items."
            : nil
    }
}

private struct ShortcutRecorder: View {
    let shortcut: Shortcut
    let onRecord: (Shortcut) -> Bool
    let setRecording: (Bool) -> Void

    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var error: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Button {
                isRecording ? stop() : start()
            } label: {
                Text(isRecording ? "Type shortcut…" : shortcut.displayString)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .frame(minWidth: 110)
            }
            .controlSize(.large)
            .tint(isRecording ? .accentColor : nil)
            .buttonStyle(.bordered)

            if let error {
                Text(error).font(.system(size: 11)).foregroundStyle(.red)
            }
        }
        .onDisappear { if isRecording { stop() } }
    }

    private func start() {
        error = nil
        isRecording = true
        setRecording(true)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if Int(event.keyCode) == 53 { // Esc
                stop()
                return nil
            }
            guard let new = Shortcut(event: event) else {
                error = "Include ⌘, ⌥ or ⌃ in the shortcut."
                return nil
            }
            if !onRecord(new) {
                error = "\(new.displayString) is already used by another app."
            }
            stop()
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
        setRecording(false)
    }
}

private extension Text {
    func settingsFootnote() -> some View {
        font(.system(size: 11)).foregroundStyle(.secondary)
    }
}

final class SettingsWindowController {
    private var window: NSWindow?

    func show(makeView: () -> SettingsView) {
        if window == nil {
            let host = NSHostingController(rootView: makeView())
            let window = NSWindow(contentViewController: host)
            window.title = "ClipStack Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
