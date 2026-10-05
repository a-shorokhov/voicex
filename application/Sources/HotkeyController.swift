import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let dictation = Self("dictation", default: .init(.space, modifiers: [.control, .shift]))
    static let cancelDictation = Self("cancelDictation", default: .init(.escape))
}
@MainActor final class HotkeyController {
    var onDown: () -> Void = {}
    var onUp: () -> Void = {}
    var onCancel: () -> Void = {}
    private var monitors: [Any] = []
    private var edge = HotkeyEdge()
    private var suspended = false
    private var configuration: HotkeyConfiguration?
    init() {
        KeyboardShortcuts.onKeyDown(for: .dictation) { [weak self] in self?.down() }
        KeyboardShortcuts.onKeyUp(for: .dictation) { [weak self] in self?.up() }
        KeyboardShortcuts.onKeyDown(for: .cancelDictation) { [weak self] in self?.onCancel() }
        KeyboardShortcuts.disable(.cancelDictation)
    }
    private func down() { guard !suspended, edge.down() else { return }; onDown() }
    private func up() { guard edge.up() else { return }; if !suspended { onUp() } }
    func cancelEnabled(_ enabled: Bool) { if enabled { KeyboardShortcuts.enable(.cancelDictation) } else { KeyboardShortcuts.disable(.cancelDictation) } }
    func configure(suspended: Bool? = nil, force: Bool = false) {
        if let suspended { self.suspended = suspended }
        let label = UserDefaults.standard.string(forKey: "shortcutPreview") ?? "⌃ ⇧ Space"
        let next = HotkeyConfiguration(label: label, trusted: AXIsProcessTrusted(), suspended: self.suspended)
        guard force || configuration != next else { return }
        configuration = next
        edge = HotkeyEdge()
        monitors.forEach(NSEvent.removeMonitor); monitors = []
        KeyboardShortcuts.disable(.dictation)
        guard !self.suspended else { return }
        if label == "Не указано" { return }
        if label == "⌃ ⇧ Space" {
            KeyboardShortcuts.setShortcut(.init(.space, modifiers: [.control, .shift]), for: .dictation)
            KeyboardShortcuts.enable(.dictation); return
        }
        let masks: [String: UInt] = ["Правый ⌘": 0x10, "Правый ⌥": 0x40, "Правый ⇧": 0x4, "Правый ⌃": 0x2000]
        let pairs: [String: NSEvent.ModifierFlags] = ["⌥ + ⌘": [.option, .command], "⌃ + ⌘": [.control, .command], "⌃ + ⌥": [.control, .option], "⇧ + ⌘": [.shift, .command], "⌥ + ⇧": [.option, .shift], "⌃ + ⇧": [.control, .shift], "Fn": [.function]]
        if masks[label] != nil || pairs[label] != nil {
            // Modifier-only shortcuts cannot be registered with Carbon. Observe
            // flags changes only; never inspect typed characters or field content.
            let handle: (NSEvent) -> Void = { [weak self] event in
                let flags = event.modifierFlags.intersection([.command, .option, .shift, .control, .function])
                let active: Bool
                if let mask = masks[label] {
                    let expected: NSEvent.ModifierFlags = label == "Правый ⌘" ? .command : label == "Правый ⌥" ? .option : label == "Правый ⇧" ? .shift : .control
                    active = event.modifierFlags.rawValue & mask != 0 && flags == expected
                } else { active = flags == pairs[label] }
                if active { self?.down() } else { self?.up() }
            }
            if let monitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: { event in handle(event); return event }) { monitors.append(monitor) }
            if AXIsProcessTrusted(), let monitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handle) { monitors.append(monitor) }
        } else if let data = UserDefaults.standard.data(forKey: "customShortcutData"), let shortcut = try? JSONDecoder().decode(KeyboardShortcuts.Shortcut.self, from: data) {
            KeyboardShortcuts.setShortcut(shortcut, for: .dictation); KeyboardShortcuts.enable(.dictation)
        }
    }
    static func save(_ event: NSEvent) {
        if let shortcut = KeyboardShortcuts.Shortcut(event: event), let data = try? JSONEncoder().encode(shortcut) { UserDefaults.standard.set(data, forKey: "customShortcutData") }
    }
}
