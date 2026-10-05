import SwiftUI
import AppKit
import AVFoundation
import ApplicationServices

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
    @Published var starting = false
    @Published var seconds = 0
    @Published var result = ""
    @Published var copied = false
    @Published var modelReady = false
    @Published var installing = false
    @Published var progress = 0.0
    @Published var modelStatus = "Не установлена"
    @Published var historyEnabled = false
    @Published var history: [HistoryItem] = []
    @Published var microphoneGranted = false
    @Published var accessibilityGranted = false
    @Published var backgroundHotkeyNeedsPermission = false
    @Published var message: String?
    @Published var status = "Распознавание локально на Mac"
    @Published var levels: [CGFloat] = Array(repeating: 0, count: 28)
    @Published var targetName = "Voicex"
    private let speech = SpeechService()
    private let audio = AudioRecorder()
    private let hotkey = HotkeyController()
    private var hud: HUDController?
    private var gate = SessionGate()
    private var target: PasteTarget?
    private var automaticPaste = false
    private var holdSession = false
    private var timer: Task<Void, Never>?
    private var work: Task<Void, Never>?
    private var installTask: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []
    private var permissionTask: Task<Void, Never>?
    var busy: Bool { recording || processing || starting }
    init() {
        refreshPermissions()
        hotkey.onDown = { [weak self] in
            guard let self else { return }
            if self.recording { if !self.holdSession { self.stop() }; return }
            self.start(automatic: true)
        }
        hotkey.onUp = { [weak self] in
            guard let self, self.holdSession else { return }
            if self.recording { self.stop() } else if self.starting { self.cancel() }
        }
        hotkey.onCancel = { [weak self] in self?.cancel() }
        hotkey.configure()
        // System Settings can grant access while Voicex remains in the background.
        // Reconnect only on a configuration change; never reset a held session.
        permissionTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.refreshPermissions()
            }
        }
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.refreshPermissions(); if self?.busy == false { self?.hotkey.configure() } } })
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.cancel() } })
        observers.append(NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in
            guard let self, self.recording else { return }; self.cancel(); self.status = "Аудиоустройство изменилось. Начните запись снова."
        } })
        installing = true; modelStatus = "Подготовка…"
        installTask = Task {
            do { modelReady = try await speech.loadInstalled(); modelStatus = modelReady ? "Готова" : "Не установлена" }
            catch { modelStatus = "Ошибка подготовки"; status = "Не удалось загрузить модель. Удалите её и повторите установку." }
            installing = false
        }
    }
    func configureShortcut(suspended: Bool? = nil, force: Bool = false) {
        refreshPermissions()
        hotkey.configure(suspended: suspended, force: force)
    }
    func useStandardShortcut() {
        UserDefaults.standard.set("⌃ ⇧ Space", forKey: "shortcutPreview")
        configureShortcut(suspended: false)
    }
    func refreshPermissions() {
        microphoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityGranted = AXIsProcessTrusted()
        let label = UserDefaults.standard.string(forKey: "shortcutPreview") ?? "⌃ ⇧ Space"
        backgroundHotkeyNeedsPermission = HotkeyConfiguration(label: label, trusted: accessibilityGranted, suspended: false).needsAccessibility
        if !busy { hotkey.configure() }
    }
    func requestMicrophone() {
        Task {
            if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined { _ = await AVCaptureDevice.requestAccess(for: .audio) }
            else if !microphoneGranted { openPrivacy("Microphone") }
            refreshPermissions()
        }
    }
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options); refreshPermissions()
        if !accessibilityGranted { openPrivacy("Accessibility") }
    }
    private func openPrivacy(_ pane: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_" + pane) { NSWorkspace.shared.open(url) }
    }
    func start(automatic: Bool = false) {
        guard modelReady, !busy, !installing else { status = modelReady ? "Дождитесь завершения операции" : "Сначала установите модель"; return }
        let id = gate.begin()
        target = automatic ? PasteService.capture() : nil
        targetName = automatic ? NSWorkspace.shared.frontmostApplication?.localizedName ?? "Диктовка" : "Проверка диктовки"
        automaticPaste = automatic
        holdSession = automatic && UserDefaults.standard.string(forKey: "activationMode") == "Удержание"
        starting = true
        work = Task {
            if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined { _ = await AVCaptureDevice.requestAccess(for: .audio) }
            refreshPermissions()
            guard gate.accepts(id) else { starting = false; return }
            guard microphoneGranted else { starting = false; status = "Разрешите микрофон в настройках macOS"; finish(); return }
            do {
                try audio.start(); starting = false; recording = true; seconds = 0; levels = Array(repeating: 0, count: 28)
                status = "Запись…"; hotkey.cancelEnabled(true)
                if hud == nil { hud = HUDController(model: self) }; hud?.show()
                timer = Task {
                    while !Task.isCancelled && recording {
                        try? await Task.sleep(for: .milliseconds(60))
                        guard !Task.isCancelled, recording else { return }
                        let value = audio.snapshot(); seconds = Int(value.seconds)
                        levels.removeFirst(); levels.append(CGFloat(min(1, sqrt(value.level) * 2.8)))
                        if value.failed { cancel(); status = "Ошибка микрофона. Начните запись снова."; return }
                        if value.seconds >= 300 { stop(); return }
                    }
                }
            } catch { starting = false; status = "Не удалось начать запись: " + error.localizedDescription; finish() }
        }
    }
    func stop() {
        guard recording, let id = gate.id else { return }
        timer?.cancel(); recording = false
        let samples = audio.stop()
        guard RecordingPolicy.hasSpeech(samples) else {
            status = "Речь не обнаружена или запись слишком короткая"; finish(); return
        }
        processing = true; status = "Распознаём…"
        let selected = UserDefaults.standard.string(forKey: "recognitionLanguage") ?? "Auto"
        let language = selected == "Auto" ? nil : selected.lowercased()
        work = Task {
            defer { processing = false; finish() }
            do {
                let text = try await speech.transcribe(samples, language: language)
                guard gate.accepts(id), !Task.isCancelled else { return }
                guard !text.isEmpty else { status = "Речь не обнаружена"; return }
                result = text; copied = false
                if historyEnabled { history.insert(HistoryItem(text: text), at: 0); if history.count > 100 { history.removeLast() } }
                if automaticPaste {
                    status = PasteService.paste(text, into: target) ? "Команда вставки отправлена" : "Текст готов. Автовставка недоступна — скопируйте результат."
                } else { status = "Проверка завершена. Текст остаётся в этом окне." }
            } catch {
                if gate.accepts(id), !(error is CancellationError) { status = "Ошибка распознавания: " + error.localizedDescription }
            }
        }
    }
    private func finish() { gate.cancel(); target = nil; hotkey.cancelEnabled(false); hud?.hide(); refreshPermissions() }
    func cancel() {
        gate.cancel(); timer?.cancel(); work?.cancel()
        if recording { _ = audio.stop() }; recording = false; seconds = 0
        // Do not clear processing until the SDK actually returns: no overlapping compute.
        status = processing ? "Отмена — завершаем вычисление…" : "Запись отменена"
        target = nil; hotkey.cancelEnabled(false); hud?.hide()
    }
    func install() {
        guard !installing, !busy else { return }
        installing = true; progress = 0; modelStatus = "Загрузка…"
        installTask = Task {
            defer { installing = false }
            do {
                try await speech.install { [weak self] value, preparing in Task { @MainActor in
                    guard let self, self.installing else { return }; self.progress = value; self.modelStatus = preparing ? "Подготовка…" : "Загрузка…"
                } }
                try Task.checkCancellation()
                modelReady = true; modelStatus = "Готова"; status = "Модель готова к локальной диктовке"
            } catch { modelReady = false; modelStatus = error is CancellationError ? "Установка отменена" : "Ошибка установки"; if !(error is CancellationError) { status = error.localizedDescription } }
        }
    }
    func cancelInstall() { installTask?.cancel(); modelStatus = "Отмена…" }
    func removeModel() {
        guard !busy, !installing else { return }
        installing = true; modelReady = false
        installTask = Task {
            defer { installing = false }
            do { try await speech.remove(); modelStatus = "Не установлена" }
            catch { modelStatus = "Ошибка удаления"; status = error.localizedDescription }
        }
    }
    func copy(_ text: String? = nil) {
        let value = text ?? result; guard !value.isEmpty else { return }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(value, forType: .string); copied = true
    }
}
