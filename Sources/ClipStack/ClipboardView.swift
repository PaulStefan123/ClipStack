import AppKit
import SwiftUI

struct ClipboardView: View {
    static let width: CGFloat = 480

    @ObservedObject var store: ClipboardStore
    @ObservedObject var state: PanelState
    var onPick: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            if store.items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 2) {
                    ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                        ClipRow(item: item, index: index, isSelected: index == state.selection, now: state.now)
                            .onTapGesture { onPick(index) }
                            .onHover { inside in if inside { state.selection = index } }
                    }
                }
                .padding(6)
            }
            Divider().opacity(0.4)
            footer
        }
        .frame(width: Self.width)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("Clipboard")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(store.items.count == 1 ? "1 item" : "\(store.items.count) items")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)
            Text("Nothing copied yet")
                .font(.system(size: 13, weight: .medium))
            Text("Copy something with ⌘C and it will show up here.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            KeyHint(keys: "↑↓", label: "Navigate")
            KeyHint(keys: "↩", label: "Paste")
            KeyHint(keys: "1–0", label: "Quick paste")
            KeyHint(keys: "⌫", label: "Remove")
            Spacer()
            KeyHint(keys: "esc", label: "Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

private struct ClipRow: View {
    let item: ClipItem
    let index: Int
    let isSelected: Bool
    let now: Date

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(index == 9 ? "0" : "\(index + 1)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white.opacity(isSelected ? 0.25 : 0.08))
                )
                .foregroundStyle(isSelected ? Color.white : Color.secondary)

            Image(nsImage: AppIconCache.icon(for: item.appBundleID))
                .resizable()
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(Color.primary)
                Text(metadata)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.75) : Color.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private var metadata: String {
        var parts = [item.appName ?? "Unknown app", relativeTime]
        let lineCount = item.lines.count
        if lineCount > 1 { parts.append("\(lineCount) lines") }
        else if item.text.count > 80 { parts.append("\(item.text.count) chars") }
        return parts.joined(separator: " · ")
    }

    private var relativeTime: String {
        let seconds = now.timeIntervalSince(item.date)
        if seconds < 10 { return "just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: item.date, relativeTo: now)
    }
}

private struct KeyHint: View {
    let keys: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(keys)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)))
            Text(label)
                .font(.system(size: 10))
        }
        .foregroundStyle(.secondary)
    }
}

private struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

enum AppIconCache {
    private static var cache: [String: NSImage] = [:]
    private static let fallback: NSImage = {
        let image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil) ?? NSImage()
        return image
    }()

    static func icon(for bundleID: String?) -> NSImage {
        guard let bundleID else { return fallback }
        if let cached = cache[bundleID] { return cached }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return fallback }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache[bundleID] = icon
        return icon
    }
}
