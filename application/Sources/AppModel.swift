import SwiftUI
import AppKit

enum Section: String, CaseIterable, Identifiable {
    case dictation = "Диктовка", settings = "Основные настройки", models = "Модели диктовки", history = "История", onboarding = "Начало работы"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .dictation: "mic"
        case .settings: "slider.horizontal.3"
        case .models: "waveform"
        case .history: "clock"
        case .onboarding: "sparkles"
        }
    }
}
struct HistoryItem: Identifiable {
    let id = UUID()
    let text: String
    let date = Date()
}
@MainActor final class AppModel: ObservableObject {
    @Published var section: Section = .dictation
    @Published var recording = false
    @Published var processing = false
    @Published var seconds = 0
    @Published var result = ""
    @Published var copied = false
    @Published var modelReady = false
    @Published var installing = false
    @Published var progress = 0.0
    @Published var historyEnabled = false
    @Published var history: [HistoryItem] = []
    @Published var microphoneDemo = false
    @Published var accessibilityDemo = false
    @Published var message: String?
    private var recordTask: Task<Void, Never>?
    private var installTask: Task<Void, Never>?
    private var copyTask: Task<Void, Never>?
    var busy: Bool { recording || processing }
    func start() {
        guard modelReady, !busy else { return }
        seconds = 0
        recording = true
        recordTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                seconds += 1
                if seconds >= 300 { stop(); return }
            }
        }
    }
    func stop() {
        guard recording else { return }
        recordTask?.cancel()
        recording = false
        processing = true
        recordTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            result = "Давай обсудим идею завтра."
            copied = false
            if historyEnabled { history.insert(HistoryItem(text: result), at: 0) }
            processing = false
        }
    }
    func cancel() {
        recordTask?.cancel()
        recording = false
        processing = false
        seconds = 0
    }
    func install() {
        guard !installing, !busy else { return }
        installing = true
        progress = 0
        installTask = Task {
            for step in 1...20 {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                progress = Double(step) / 20
            }
            installing = false
            modelReady = true
        }
    }
    func cancelInstall() {
        installTask?.cancel()
        installing = false
        progress = 0
    }
    func removeModel() {
        guard !busy else { return }
        cancelInstall()
        modelReady = false
    }
    func copy(_ text: String? = nil) {
        let value = text ?? result
        guard !value.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        copied = true
        copyTask?.cancel()
        copyTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            copied = false
        }
    }
}
