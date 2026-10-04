import AppKit
import SwiftUI

private final class DictationPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
@MainActor final class HUDController {
    private let panel: DictationPanel
    init(model: AppModel) {
        panel = DictationPanel(contentRect: NSRect(x: 0, y: 0, width: 340, height: 86), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "Voicex — диктовка"
        panel.isFloatingPanel = true; panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false; panel.isOpaque = false; panel.backgroundColor = .clear
        panel.hasShadow = true; panel.contentView = NSHostingView(rootView: DictationHUD(model: model))
        panel.isReleasedWhenClosed = false
    }
    func show() {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        if let frame = screen?.visibleFrame { panel.setFrameOrigin(NSPoint(x: frame.midX - 170, y: frame.minY + 24)) }
        panel.orderFrontRegardless()
    }
    func hide() { panel.orderOut(nil) }
}
private struct DictationHUD: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Image(systemName: "leaf.fill")
                Text(model.targetName).lineLimit(1)
                Spacer()
                if model.recording {
                    Button { model.stop() } label: { Image(systemName: "stop.fill") }.buttonStyle(.plain).accessibilityLabel("Остановить диктовку")
                } else { ProgressView().controlSize(.mini) }
                Button { model.cancel() } label: { Image(systemName: "xmark") }.buttonStyle(.plain).accessibilityLabel("Отменить диктовку")
            }.font(.system(size: 12, weight: .medium))
            if model.recording {
                HStack(spacing: 4) {
                    ForEach(Array(model.levels.enumerated()), id: \.offset) { _, level in Capsule().frame(width: 6, height: 3 + level * 23) }
                }.frame(height: 26).animation(reduceMotion ? nil : .linear(duration: 0.06), value: model.levels)
            } else { Text("Распознаём локально…").font(.system(size: 12)).frame(height: 26) }
        }
        .foregroundStyle(Color(red: 0.07, green: 0.24, blue: 0.16))
        .padding(.horizontal, 18).padding(.vertical, 12)
        .frame(width: 340, height: 86)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 25))
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(.white.opacity(0.65), lineWidth: 1))
    }
}
