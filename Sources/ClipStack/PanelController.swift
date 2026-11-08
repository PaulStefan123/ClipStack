import AppKit
import SwiftUI

final class PanelState: ObservableObject {
    @Published var selection = 0
    @Published var now = Date()
}

/// Borderless floating panel that can take keyboard focus without
/// activating ClipStack (so the app you were typing in stays frontmost).
final class ClipPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class PanelController: NSObject, NSWindowDelegate {
    private let store: ClipboardStore
    private let state = PanelState()
    private var panel: ClipPanel!
    private var hostingView: NSHostingView<ClipboardView>!
    private var keyMonitor: Any?
    private var previousApp: NSRunningApplication?

    var isVisible: Bool { panel.isVisible }

    init(store: ClipboardStore) {
        self.store = store
        super.init()

        panel = ClipPanel(contentRect: NSRect(x: 0, y: 0, width: ClipboardView.width, height: 300),
                          styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                          backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.delegate = self

        let root = ClipboardView(store: store, state: state) { [weak self] index in
            self?.paste(index: index)
        }
        hostingView = NSHostingView(rootView: root)
        panel.contentView = hostingView
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        let front = NSWorkspace.shared.frontmostApplication
        if front?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previousApp = front
        }
        state.selection = 0
        state.now = Date()

        let size = fittedSize()
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        let area = screen?.visibleFrame ?? .zero
        let origin = NSPoint(x: area.midX - size.width / 2,
                             y: max(area.minY, area.minY + area.height * 0.6 - size.height / 2))
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.makeKeyAndOrderFront(nil)
        installKeyMonitor()
    }

    func hide() {
        removeKeyMonitor()
        panel.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        if panel.isVisible { hide() }
    }

    // MARK: Actions

    private func paste(index: Int) {
        guard store.items.indices.contains(index) else { return }
        store.copyToPasteboard(store.items[index])
        hide()

        let target = previousApp
        if let target, !target.isActive {
            target.activate(options: [])
        }
        // Give the target app a moment to regain focus before sending ⌘V.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            Paster.pasteIntoFrontApp()
        }
    }

    private func deleteSelected() {
        store.remove(at: state.selection)
        state.selection = min(state.selection, max(store.items.count - 1, 0))
        // Shrink the panel, keeping its top edge in place.
        DispatchQueue.main.async { [self] in
            let size = fittedSize()
            var frame = panel.frame
            frame.origin.y += frame.height - size.height
            frame.size = size
            panel.setFrame(frame, display: true, animate: false)
        }
    }

    private func fittedSize() -> NSSize {
        hostingView.layoutSubtreeIfNeeded()
        let fitting = hostingView.fittingSize
        return NSSize(width: ClipboardView.width, height: ceil(fitting.height))
    }

    // MARK: Keyboard

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isKeyWindow else { return event }
            return self.handle(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    /// Returns true when the key was handled.
    private func handle(_ event: NSEvent) -> Bool {
        let count = store.items.count
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.contains(.command) { return false }

        switch Int(event.keyCode) {
        case 125: // ↓
            if count > 0 { state.selection = (state.selection + 1) % count }
        case 126: // ↑
            if count > 0 { state.selection = (state.selection - 1 + count) % count }
        case 36, 76: // Return, keypad Enter
            paste(index: state.selection)
        case 53: // Esc
            hide()
        case 51, 117: // Delete, Forward Delete
            deleteSelected()
        default:
            // 1–9 and 0 paste that row directly.
            guard let chars = event.charactersIgnoringModifiers, chars.count == 1,
                  let digit = Int(chars) else { return false }
            paste(index: digit == 0 ? 9 : digit - 1)
        }
        return true
    }
}
