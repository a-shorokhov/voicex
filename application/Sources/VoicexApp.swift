import SwiftUI
import AppKit

@main struct VoicexApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup("Voicex", id: "main") {
            MainView(model: model)
                .frame(minWidth: 940, minHeight: 680)
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 1060, height: 740)
        .windowStyle(.hiddenTitleBar)
        .commands { CommandGroup(replacing: .newItem) {} }
        MenuBarExtra("Voicex", systemImage: "waveform") {
            MenuContent(model: model)
        }
    }
}
struct MenuContent: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Text("Voicex · демо интерфейса")
        Button("Открыть Voicex") { openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true) }
        Button("Настройки") { model.section = .settings; openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true) }
        Divider()
        Button("Выйти") { model.cancel(); model.cancelInstall(); NSApp.terminate(nil) }
    }
}
