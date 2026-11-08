import AppKit
import Carbon.HIToolbox

/// A global shortcut stored as a Carbon key code + Carbon modifier mask.
struct Shortcut: Codable, Equatable {
    var keyCode: Int
    var modifiers: Int
    var key: String

    static let `default` = Shortcut(keyCode: kVK_ANSI_V, modifiers: cmdKey | optionKey, key: "V")

    var displayString: String {
        var s = ""
        if modifiers & controlKey != 0 { s += "⌃" }
        if modifiers & optionKey != 0 { s += "⌥" }
        if modifiers & shiftKey != 0 { s += "⇧" }
        if modifiers & cmdKey != 0 { s += "⌘" }
        return s + key
    }

    /// Builds a shortcut from a key press. Returns nil unless ⌘, ⌥ or ⌃ is held,
    /// so plain typing can never become a global shortcut.
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var carbon = 0
        if flags.contains(.command) { carbon |= cmdKey }
        if flags.contains(.option) { carbon |= optionKey }
        if flags.contains(.control) { carbon |= controlKey }
        if flags.contains(.shift) { carbon |= shiftKey }
        guard carbon & (cmdKey | optionKey | controlKey) != 0 else { return nil }
        self.init(keyCode: Int(event.keyCode), modifiers: carbon,
                  key: Self.keyName(keyCode: Int(event.keyCode), characters: event.charactersIgnoringModifiers))
    }

    init(keyCode: Int, modifiers: Int, key: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.key = key
    }

    private static let specialKeys: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    private static func keyName(keyCode: Int, characters: String?) -> String {
        if let name = specialKeys[keyCode] { return name }
        let chars = (characters ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return chars.isEmpty ? "Key \(keyCode)" : chars.uppercased()
    }
}

/// How long a copy stays in the history before it is removed automatically.
enum Retention: Int, CaseIterable, Identifiable {
    case forever = 0
    case oneHour = 3600
    case oneDay = 86_400
    case oneWeek = 604_800
    case oneMonth = 2_592_000

    var id: Int { rawValue }

    /// nil means "never expire" (items still drop off once there are more than 10).
    var maxAge: TimeInterval? { self == .forever ? nil : TimeInterval(rawValue) }

    var title: String {
        switch self {
        case .forever: return "Until replaced by newer copies"
        case .oneHour: return "1 hour"
        case .oneDay: return "1 day"
        case .oneWeek: return "1 week"
        case .oneMonth: return "30 days"
        }
    }
}

/// User preferences, persisted in UserDefaults.
final class Settings: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published private(set) var shortcut: Shortcut
    @Published var retention: Retention {
        didSet { defaults.set(retention.rawValue, forKey: "retention") }
    }

    init() {
        if let data = defaults.data(forKey: "shortcut"),
           let saved = try? JSONDecoder().decode(Shortcut.self, from: data) {
            shortcut = saved
        } else {
            shortcut = .default
        }
        retention = Retention(rawValue: defaults.integer(forKey: "retention")) ?? .forever
    }

    func setShortcut(_ new: Shortcut) {
        shortcut = new
        if let data = try? JSONEncoder().encode(new) { defaults.set(data, forKey: "shortcut") }
    }
}
