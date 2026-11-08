import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = ClipboardStore()
    private let settings = Settings()
    private let settingsWindow = SettingsWindowController()
    private var panel: PanelController!
    private var hotKey: HotKey?
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.$retention
            .sink { [weak self] in self?.store.maxAge = $0.maxAge }
            .store(in: &cancellables)
        store.start()
        panel = PanelController(store: store)

        if !registerHotKey(settings.shortcut) {
            showAlert("\(settings.shortcut.displayString) is already in use",
                      "Another app has claimed this shortcut. Pick a different one in ClipStack Settings.")
            openSettings()
        }

        setUpStatusItem()
        LoginItem.enableOnFirstInstall()
        if !Paster.isTrusted { Paster.requestAccess() }
    }

    /// Opening the app again (Spotlight, Launchpad, Finder) shows the clipboard.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.show()
        return false
    }

    // MARK: Shortcut

    @discardableResult
    private func registerHotKey(_ shortcut: Shortcut) -> Bool {
        hotKey = nil // unregisters the previous one
        hotKey = HotKey(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers) { [weak self] in
            self?.panel.toggle()
        }
        return hotKey != nil
    }

    /// Switches to a new shortcut, keeping the old one if the new one is taken.
    private func applyShortcut(_ shortcut: Shortcut) -> Bool {
        if registerHotKey(shortcut) {
            settings.setShortcut(shortcut)
            return true
        }
        registerHotKey(settings.shortcut)
        return false
    }

    private func setRecordingShortcut(_ recording: Bool) {
        if recording {
            hotKey = nil
        } else if hotKey == nil {
            registerHotKey(settings.shortcut)
        }
    }

    // MARK: Menu bar

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "ClipStack")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let show = NSMenuItem(title: "Show Clipboard  \(settings.shortcut.displayString)",
                              action: #selector(showPanel), keyEquivalent: "")
        show.target = self
        menu.addItem(show)

        let clear = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clear.target = self
        clear.isEnabled = !store.items.isEmpty
        menu.addItem(clear)

        menu.addItem(.separator())

        let prefs = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        if !Paster.isTrusted {
            let access = NSMenuItem(title: "Grant Accessibility Access…", action: #selector(grantAccess), keyEquivalent: "")
            access.target = self
            menu.addItem(access)
        }

        menu.addItem(.separator())
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        let about = NSMenuItem(title: "ClipStack \(version)", action: nil, keyEquivalent: "")
        about.isEnabled = false
        menu.addItem(about)
        menu.addItem(NSMenuItem(title: "Quit ClipStack", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func showPanel() {
        // Let the menu close first so the panel can take keyboard focus.
        DispatchQueue.main.async { self.panel.show() }
    }

    @objc private func clearHistory() {
        store.clear()
    }

    @objc private func openSettings() {
        settingsWindow.show {
            SettingsView(settings: settings,
                         applyShortcut: { [weak self] in self?.applyShortcut($0) ?? false },
                         setRecording: { [weak self] in self?.setRecordingShortcut($0) })
        }
    }

    @objc private func grantAccess() {
        Paster.requestAccess()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
