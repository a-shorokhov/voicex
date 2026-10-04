import AppKit
import ApplicationServices
import Carbon

struct PasteTarget {
    let pid: pid_t
    let element: AXUIElement
    let name: String
}
enum PasteService {
    static func focused(_ pid: pid_t) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(AXUIElementCreateApplication(pid), kAXFocusedUIElementAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }
    private static func attribute(_ element: AXUIElement, _ name: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? String
    }
    static func safe(_ element: AXUIElement) -> Bool {
        guard !IsSecureEventInputEnabled(), let role = attribute(element, kAXRoleAttribute), [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole].contains(role),
              attribute(element, kAXSubroleAttribute) != kAXSecureTextFieldSubrole else { return false }
        var editable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &editable) == .success && editable.boolValue
    }
    static func capture() -> PasteTarget? {
        guard AXIsProcessTrusted(), let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              let element = focused(app.processIdentifier), safe(element) else { return nil }
        return PasteTarget(pid: app.processIdentifier, element: element, name: app.localizedName ?? "Приложение")
    }
    static func matches(originalPID: pid_t, currentPID: pid_t?, sameElement: Bool, safe: Bool, trusted: Bool) -> Bool {
        trusted && safe && sameElement && currentPID == originalPID
    }
    static func paste(_ text: String, into target: PasteTarget?) -> Bool {
        guard let target, let current = focused(target.pid), matches(originalPID: target.pid, currentPID: NSWorkspace.shared.frontmostApplication?.processIdentifier, sameElement: CFEqual(target.element, current), safe: safe(current), trusted: AXIsProcessTrusted()),
              let source = CGEventSource(stateID: .combinedSessionState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return false }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
        down.flags = .maskCommand; up.flags = .maskCommand
        down.post(tap: .cghidEventTap); up.post(tap: .cghidEventTap)
        return true
    }
}
