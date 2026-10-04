import SwiftUI
import AppKit

private let forest = Color(red: 0.07, green: 0.24, blue: 0.16)
private let sage = Color(red: 0.55, green: 0.64, blue: 0.43)
private let ivory = Color(red: 0.97, green: 0.96, blue: 0.92)

struct FrostedSurface: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}
struct SoftButton: ButtonStyle {
    var primary = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 18).padding(.vertical, 10)
            .foregroundStyle(primary ? Color.white : forest)
            .background(primary ? forest : Color.white.opacity(0.35), in: Capsule())
            .overlay(Capsule().strokeBorder(primary ? Color.clear : forest.opacity(0.12), lineWidth: 1))
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .contentShape(Capsule())
    }
}
struct NavigationItem: View {
    let section: Section
    let selected: Bool
    let selectionAnimation: Namespace.ID
    let action: () -> Void
    @State private var hovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.symbol).font(.system(size: 16)).frame(width: 20)
                Text(section.rawValue).font(.system(size: 13, weight: selected ? .medium : .regular))
                    .lineLimit(1).minimumScaleFactor(0.9)
                Spacer(minLength: 0)
            }
            .foregroundStyle(selected ? forest : forest.opacity(hovered ? 0.9 : 0.62))
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(sage.opacity(hovered ? 0.12 : 0))
                    if selected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(sage.opacity(0.25))
                            .matchedGeometryEffect(id: "selection", in: selectionAnimation)
                    }
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
        .accessibilityIdentifier("nav-\(section.id)")
    }
}
struct MainView: View {
    @ObservedObject var model: AppModel
    @AppStorage("recognitionLanguage") private var language = "Auto"
    @AppStorage("activationMode") private var mode = "Нажатие"
    @AppStorage("shortcutPreview") private var shortcut = "⌃ ⇧ Space"
    @State private var showShortcut = false
    @State private var recordingShortcut = false
    @Namespace private var navigationAnimation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showRemoval = false
    @State private var showHistoryClear = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        HStack(spacing: 16) {
            sidebar.frame(width: 244)
            VStack(alignment: .leading, spacing: 18) {
                header
                Group {
                    switch model.section {
                    case .dictation: dictation
                    case .settings: settings
                    case .models: models
                    case .history: history
                    case .onboarding: onboarding
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .id(model.section)
                .transition(.opacity)
                Label(model.status, systemImage: "lock")
                    .font(.system(size: 11)).foregroundStyle(forest.opacity(0.5))
            }
            .padding(.horizontal, 20).padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .background {
            if reduceTransparency { ivory }
            else {
                FrostedSurface()
                ivory.opacity(0.78)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: model.section)
        .tint(forest)
        .onAppear { if !model.busy { model.configureShortcut() } }
        .alert("Voicex", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) {
            Button("Понятно", role: .cancel) { model.message = nil }
        } message: { Text(model.message ?? "") }
        .confirmationDialog("Удалить локальную модель?", isPresented: $showRemoval) {
            Button("Удалить модель", role: .destructive) { model.removeModel() }
        } message: { Text("Файлы модели и токенизатора будут удалены с этого Mac.") }
        .confirmationDialog("Очистить историю?", isPresented: $showHistoryClear) {
            Button("Очистить", role: .destructive) { model.history.removeAll() }
        }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Voicex").font(.system(size: 30, weight: .medium, design: .serif))
                .foregroundStyle(forest).padding(.horizontal, 12).padding(.top, 30).padding(.bottom, 22)
            ForEach(Section.allCases) { section in
                NavigationItem(section: section, selected: model.section == section, selectionAnimation: navigationAnimation) {
                    showShortcut = false
                    model.section = section
                }
            }
            Spacer()
            Divider().padding(.horizontal, 12)
            Label("Локально на Mac", systemImage: "lock").font(.system(size: 12))
                .foregroundStyle(forest.opacity(0.6)).padding(.horizontal, 12).padding(.top, 14)
            Text("Voicex 0.1.0").font(.system(size: 11)).foregroundStyle(forest.opacity(0.45))
                .padding(.leading, 36).padding(.top, 4).padding(.bottom, 18)
        }
        .padding(.horizontal, 10)
        .frame(maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(reduceTransparency ? Color(red: 0.88, green: 0.91, blue: 0.83) : sage.opacity(0.18))
        }
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.55), lineWidth: 1))
    }
    private var shortcutControl: some View {
        Button { showShortcut.toggle() } label: {
            HStack(spacing: 12) {
                Text(shortcut)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10))
            }
        }
        .buttonStyle(SoftButton())
        .accessibilityLabel("Сочетание клавиш: \(shortcut)")
        .disabled(model.busy)
        .popover(isPresented: $showShortcut, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 2) {
                if recordingShortcut {
                    Text("Нажмите сочетание клавиш")
                        .font(.system(size: 14, weight: .medium)).padding(10)
                    Text("Например, ⌃ ⇧ Space. Escape — отмена.")
                        .font(.system(size: 12)).foregroundStyle(.secondary).padding(.horizontal, 10)
                    ShortcutCapture(onRecord: { value in
                        shortcut = value
                        recordingShortcut = false
                        showShortcut = false
                    }, onCancel: { recordingShortcut = false })
                    .frame(height: 42)
                    .background(sage.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(forest.opacity(0.15)))
                    .padding(.horizontal, 10)
                    Button("Отмена") { recordingShortcut = false }
                        .buttonStyle(SoftButton()).padding(10)
                } else {
                    ForEach(shortcutPresets, id: \.self) { value in
                        shortcutOption(value)
                    }
                    if !shortcutPresets.contains(shortcut) {
                        Divider().padding(.vertical, 4)
                        shortcutOption(shortcut)
                    }
                    Divider().padding(.vertical, 4)
                    Button {
                        recordingShortcut = true
                    } label: {
                        Text("Записать сочетание…")
                            .font(.system(size: 14)).foregroundStyle(forest)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 36).padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
            .padding(8).frame(width: 260)
            .background(.regularMaterial)
        }
        .onDisappear { if !model.busy { model.configureShortcut(suspended: false) } }
        .onChange(of: showShortcut) { _, shown in
            model.configureShortcut(suspended: shown)
            if !shown { recordingShortcut = false }
        }
    }
    private let shortcutPresets = [
        "⌃ ⇧ Space", "Не указано", "Правый ⌘", "Правый ⌥", "Правый ⇧", "Правый ⌃",
        "⌥ + ⌘", "⌃ + ⌘", "⌃ + ⌥", "⇧ + ⌘", "⌥ + ⇧", "⌃ + ⇧", "Fn"
    ]
    private func shortcutOption(_ value: String) -> some View {
        Button {
            shortcut = value
            showShortcut = false
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark").opacity(shortcut == value ? 1 : 0).frame(width: 14)
                Text(value).font(.system(size: 14))
                Spacer()
            }
            .foregroundStyle(forest).padding(.horizontal, 10).padding(.vertical, 7)
            .background(shortcut == value ? sage.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(model.section == .dictation ? "Проверим диктовку" : model.section.rawValue)
                    .font(.system(size: 29, weight: .medium, design: .serif)).foregroundStyle(forest)
                Spacer()
                if model.section == .dictation {
                    Label(model.modelReady ? "Модель готова" : model.installing ? "Подготовка модели…" : "Нет модели", systemImage: "circle.fill")
                        .font(.system(size: 11)).foregroundStyle(sage)
                        .padding(10).background(.white.opacity(0.3), in: Capsule())
                }
            }
            Text(subtitle).font(.system(size: 15)).foregroundStyle(forest.opacity(0.6))
        }
    }
    private var subtitle: String {
        switch model.section {
        case .dictation: "Проверьте микрофон здесь или диктуйте в любое поле горячей клавишей."
        case .settings: "Настройте диктовку под себя."
        case .models: "Локальная модель распознавания."
        case .history: "Вы решаете, сохранять ли расшифровки."
        case .onboarding: "Три шага до первой диктовки."
        }
    }
    private var dictation: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "mic.fill").font(.system(size: 36)).foregroundStyle(sage)
                    .frame(width: 90, height: 90)
                    .background(sage.opacity(0.12), in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2))
                Text(model.recording ? "Запись · \(time)" : model.processing ? "Распознаём…" : model.modelReady ? "Готово к проверке" : model.installing ? model.modelStatus : "Сначала установите модель")
                    .foregroundStyle(forest).font(.system(size: 15))
                shortcutControl
                if model.modelReady {
                    Button(model.recording ? "Остановить проверку" : "Начать проверку") {
                        if model.recording { model.stop() } else { model.start() }
                    }.buttonStyle(SoftButton(primary: true)).disabled(model.processing || model.starting)
                } else if model.installing {
                    ProgressView().controlSize(.small)
                } else {
                    Button("Перейти к установке") { model.section = .models }.buttonStyle(SoftButton(primary: true))
                }
                Text("Говорите естественно. Остановите запись, чтобы получить текст.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity).padding(.vertical, 8)
            Divider()
            VStack(alignment: .leading, spacing: 14) {
                Text("Результат проверки").font(.system(size: 15)).foregroundStyle(.secondary)
                HStack(alignment: .top, spacing: 18) {
                    Text(model.result.isEmpty ? "Здесь появится ваша расшифровка" : model.result)
                        .font(.system(size: 16)).foregroundStyle(model.result.isEmpty ? forest.opacity(0.4) : forest)
                        .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    Button { model.copy() } label: { Label(model.copied ? "Скопировано" : "Копировать", systemImage: model.copied ? "checkmark" : "doc.on.doc") }
                        .buttonStyle(SoftButton()).disabled(model.result.isEmpty)
                }.padding(20).background(.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 20))
                Text("Во время проверки текст остаётся в этом окне.").font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
    }
    private var settings: some View {
        VStack(alignment: .leading, spacing: 16) {
            row("Язык распознавания") {
                Picker("Язык", selection: $language) { ForEach(["Auto", "RU", "EN"], id: \.self) { Text($0) } }
                    .labelsHidden().pickerStyle(.segmented).frame(width: 270)
            }
            Divider()
            row("Горячая клавиша") { shortcutControl }
            Divider()
            row("Режим записи") {
                Picker("Режим", selection: $mode) { ForEach(["Нажатие", "Удержание"], id: \.self) { Text($0) } }
                    .labelsHidden().pickerStyle(.segmented).frame(width: 270)
            }
            Text(mode == "Нажатие" ? "Первое нажатие — запись, второе — остановка." : "Удерживайте клавиши во время записи.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Divider()
            Text("Разрешения").font(.system(size: 15)).foregroundStyle(.secondary)
            permission("Микрофон", icon: "mic", checked: model.microphoneGranted) { model.requestMicrophone() }
            permission("Вставка текста", icon: "accessibility", checked: model.accessibilityGranted) { model.requestAccessibility() }
            Text("Без Универсального доступа можно диктовать и копировать вручную. Для правых модификаторов и Fn в фоне нужен этот доступ.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Button("Открыть системные настройки") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
            }.buttonStyle(SoftButton())
        }
    }
    private var models: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 18) {
                    Image(systemName: "waveform").font(.system(size: 32)).foregroundStyle(sage)
                        .frame(width: 64, height: 64).background(sage.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Whisper Large v3").font(.system(size: 23, weight: .medium))
                        Text("Русский и английский · локально").foregroundStyle(.secondary)
                    }
                }
                Divider()
                row("Размер модели") { Text("≈ 626 МБ").foregroundStyle(forest) }
                Text("Дополнительные файлы также занимают место.").font(.system(size: 12)).foregroundStyle(.secondary)
                row("Состояние") { Text(model.modelStatus).foregroundStyle(sage) }
                if model.installing {
                    ProgressView(value: model.progress)
                    Button("Отменить установку") { model.cancelInstall() }.buttonStyle(SoftButton())
                } else if model.modelReady {
                    Button("Удалить модель") { showRemoval = true }.buttonStyle(SoftButton()).disabled(model.busy)
                } else {
                    HStack {
                        Button("Установить Whisper") { model.install() }.buttonStyle(SoftButton(primary: true)).disabled(model.busy)
                        if model.modelStatus != "Не установлена" {
                            Button("Сбросить файлы") { showRemoval = true }.buttonStyle(SoftButton()).disabled(model.busy)
                        }
                    }
                }
            }.padding(26).background(.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 24))
            Label("После установки диктовка работает без интернета.", systemImage: "info.circle")
                .font(.system(size: 13)).foregroundStyle(.secondary)
            Text("Модель и токенизатор хранятся в Application Support/Voicex. При первой установке нужен интернет.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
    private var history: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Сохранять результаты в этой сессии", isOn: $model.historyEnabled).toggleStyle(.switch)
            Text("По умолчанию выключено. История живёт только в памяти и исчезнет после выхода.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Divider()
            if model.history.isEmpty {
                VStack(spacing: 18) {
                    Image(systemName: "clock").font(.system(size: 40)).foregroundStyle(sage)
                        .frame(width: 92, height: 92).background(sage.opacity(0.12), in: Circle())
                    Text(model.historyEnabled ? "Пока нет результатов" : "История выключена").font(.system(size: 21, weight: .medium))
                    Text(model.historyEnabled ? "Продиктуйте фразу, чтобы увидеть результат." : "Сейчас доступен только последний результат.")
                        .foregroundStyle(.secondary)
                    Button(model.historyEnabled ? "Проверить диктовку" : "Включить историю") {
                        if model.historyEnabled { model.section = .dictation } else { model.historyEnabled = true }
                    }.buttonStyle(SoftButton())
                }.frame(maxWidth: .infinity).padding(.vertical, 38)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(model.history) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.text).textSelection(.enabled)
                                    Text(item.date, style: .time).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button { model.copy(item.text) } label: { Image(systemName: "doc.on.doc") }
                                    .buttonStyle(SoftButton())
                            }
                            .padding(18)
                            .background(.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
                Button("Очистить историю") { showHistoryClear = true }.buttonStyle(SoftButton())
            }
        }
    }
    private var onboarding: some View {
        VStack(alignment: .leading, spacing: 18) {
            step(1, "Разрешите микрофон", "Для записи вашего голоса", done: model.microphoneGranted) {
                model.requestMicrophone()
            }
            step(2, "Разрешите вставку текста", "Через Универсальный доступ macOS", done: model.accessibilityGranted) {
                model.requestAccessibility()
            }
            HStack(spacing: 18) {
                number(3)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Установите модель").font(.system(size: 17, weight: .medium))
                    Text("Распознавание будет работать локально.").font(.system(size: 13)).foregroundStyle(.secondary)
                    if model.installing { ProgressView(value: model.progress) }
                }
                Spacer()
                if model.modelReady { Label("Готово", systemImage: "checkmark.circle.fill").foregroundStyle(sage) }
                else { Button(model.installing ? "Отменить" : "Установить") { if model.installing { model.cancelInstall() } else { model.install() } }.buttonStyle(SoftButton(primary: !model.installing)) }
            }.padding(20).background(.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 22))
            Divider().padding(.vertical, 8)
            Button("Проверим диктовку") { model.section = .dictation }.buttonStyle(SoftButton(primary: true)).disabled(!model.modelReady)
            Text("Без доступа к вставке можно копировать текст вручную.").font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
    private var time: String { String(format: "%02d:%02d", model.seconds / 60, model.seconds % 60) }
    private func row<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        HStack { Text(title).font(.system(size: 15)); Spacer(); content() }.frame(minHeight: 32)
    }
    private func permission(_ title: String, icon: String, checked: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Label(title, systemImage: icon).font(.system(size: 15))
            Spacer()
            Button(checked ? "Разрешено ✓" : "Проверить состояние") { action() }.buttonStyle(SoftButton())
        }
    }
    private func number(_ value: Int) -> some View {
        Text("\(value)").font(.system(size: 22)).foregroundStyle(forest)
            .frame(width: 48, height: 48).background(sage.opacity(0.18), in: Circle())
    }
    private func step(_ n: Int, _ title: String, _ subtitle: String, done: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 18) {
            number(n)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(size: 17, weight: .medium))
                Text(subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Spacer()
            Button(done ? "Готово ✓" : "Проверить") { action() }.buttonStyle(SoftButton())
        }.padding(20).background(.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 22))
    }
}

// Captures only events directed to this popover; no global event monitoring or permissions.
private struct ShortcutCapture: NSViewRepresentable {
    var onRecord: (String) -> Void
    var onCancel: () -> Void
    func makeNSView(context: Context) -> ShortcutCaptureView {
        let view = ShortcutCaptureView()
        view.onRecord = onRecord
        view.onCancel = onCancel
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.textField)
        view.setAccessibilityLabel("Запись сочетания клавиш")
        return view
    }
    func updateNSView(_ view: ShortcutCaptureView, context: Context) {
        view.onRecord = onRecord
        view.onCancel = onCancel
    }
}
private final class ShortcutCaptureView: NSView {
    var onRecord: (String) -> Void = { _ in }
    var onCancel: () -> Void = {}
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)
    }
    override func accessibilityPerformPress() -> Bool {
        window?.makeKey()
        return window?.makeFirstResponder(self) ?? false
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            NSApp.activate(ignoringOtherApps: true)
            window.makeKey()
            window.makeFirstResponder(self)
        }
    }
    override func keyDown(with event: NSEvent) { capture(event) }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self else { return false }
        capture(event)
        return true
    }
    private func capture(_ event: NSEvent) {
        if event.keyCode == 53 { onCancel(); return }
        guard !event.isARepeat else { return }
        let flags = event.modifierFlags.intersection([.control, .option, .shift, .command])
        // Plain typing is not a shortcut. Modifier-only options are available in the preset list.
        guard !flags.isEmpty else { return }
        let special: [UInt16: String] = [
            49: "Space", 36: "Return", 48: "Tab", 51: "Delete", 117: "⌦",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        let letters: [UInt16: String] = [0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M"]
        let characters = event.charactersIgnoringModifiers?.uppercased() ?? ""
        let printable = characters.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
        let key = special[event.keyCode] ?? (printable && !characters.isEmpty ? characters : letters[event.keyCode] ?? "")
        guard !key.isEmpty, key.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else { return }
        var modifiers: [String] = []
        if flags.contains(.control) { modifiers.append("⌃") }
        if flags.contains(.option) { modifiers.append("⌥") }
        if flags.contains(.shift) { modifiers.append("⇧") }
        if flags.contains(.command) { modifiers.append("⌘") }
        HotkeyController.save(event)
        onRecord((modifiers + [key]).joined(separator: " "))
    }
}
