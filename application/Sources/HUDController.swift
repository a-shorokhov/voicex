import AppKit
import SwiftUI

private final class DictationPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
@MainActor final class HUDController {
    private let panel: DictationPanel
    init(model: AppModel) {
        panel = DictationPanel(contentRect: NSRect(x: 0, y: 0, width: 280, height: 80), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "Voicex — диктовка"
        panel.isFloatingPanel = true; panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.becomesKeyOnlyIfNeeded = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false; panel.isOpaque = false; panel.backgroundColor = .clear
        panel.hasShadow = true; panel.contentView = NSHostingView(rootView: DictationHUD(model: model))
        panel.isReleasedWhenClosed = false
    }
    func show() {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        if let frame = screen?.visibleFrame { panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2, y: frame.minY + 24)) }
        panel.orderFrontRegardless()
    }
    func hide() { panel.orderOut(nil) }
}
private struct DictationHUD: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    private let green = Color(red: 0.39, green: 0.52, blue: 0.26)
    private let ink = Color(red: 0.09, green: 0.25, blue: 0.17)
    var body: some View {
        HStack(spacing: 12) {
            Button { model.stop() } label: {
                ZStack {
                    Circle().fill(.white.opacity(0.48)).frame(width: 34, height: 34)
                    Circle().fill(LinearGradient(colors: [Color(red: 1, green: 0.66, blue: 0.28), Color(red: 0.97, green: 0.43, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
                        .shadow(color: .orange.opacity(0.18), radius: 5, y: 2)
                    if model.recording {
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.9)).frame(width: 8, height: 8)
                    } else { ProgressView().controlSize(.mini).tint(.white) }
                }
            }
            .buttonStyle(.plain).disabled(!model.recording)
            .accessibilityLabel(model.recording ? "Остановить диктовку" : "Распознавание")
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: "leaf.fill").font(.system(size: 10))
                    Text(model.targetName).font(.system(size: 10, weight: .medium)).lineLimit(1)
                    Spacer(minLength: 4)
                    Button { model.cancel() } label: {
                        Image(systemName: "xmark").font(.system(size: 10, weight: .medium))
                            .frame(width: 18, height: 18).contentShape(Circle())
                    }.buttonStyle(.plain).foregroundStyle(ink.opacity(0.55))
                        .accessibilityLabel("Отменить диктовку")
                }.foregroundStyle(ink)
                if model.recording {
                    HStack(spacing: 2) {
                        ForEach(Array(model.levels.enumerated()), id: \.offset) { _, level in
                            Capsule().fill(green).frame(width: 3, height: 3 + level * 21)
                        }
                    }.frame(height: 24)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.09), value: model.levels)
                        .accessibilityLabel("Амплитуда микрофона")
                } else {
                    Text("Распознаём локально…").font(.system(size: 10)).foregroundStyle(green).frame(height: 24)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .frame(width: 264, height: 64)
        .background {
            if reduceTransparency {
                Capsule().fill(.white)
            } else {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(.white.opacity(0.88))
            }
        }
        .overlay(Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 1.5))
        .overlay(Capsule().inset(by: 5).strokeBorder(.white.opacity(0.23), lineWidth: 1))
        .shadow(color: ink.opacity(0.08), radius: 4, y: 2)
        .padding(8)
        .frame(width: 280, height: 80)
        .environment(\.colorScheme, .light)
    }
}
