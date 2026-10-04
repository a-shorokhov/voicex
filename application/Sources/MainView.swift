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
            .padding(.horizontal, 22).padding(.vertical, 12)
            .foregroundStyle(primary ? Color.white : forest)
            .background(primary ? forest : Color.white.opacity(0.35), in: Capsule())
            .overlay(Capsule().strokeBorder(primary ? Color.clear : forest.opacity(0.12), lineWidth: 1))
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .contentShape(Capsule())
    }
}
struct MainView: View {
    @ObservedObject var model: AppModel
    @AppStorage("recognitionLanguage") private var language = "Auto"
    @AppStorage("activationMode") private var mode = "Нажатие"
    @AppStorage("shortcutPreview") private var shortcut = "⌃ ⇧ Space"
    @State private var showShortcut = false
    @State private var showRemoval = false
    @State private var showHistoryClear = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 264)
            Rectangle().fill(forest.opacity(0.08)).frame(width: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    switch model.section {
                    case .dictation: dictation
                    case .settings: settings
                    case .models: models
                    case .history: history
                    case .onboarding: onboarding
                    }
                    Spacer(minLength: 12)
                    Label("Демонстрация интерфейса · микрофон не используется", systemImage: "info.circle")
                        .font(.system(size: 12)).foregroundStyle(forest.opacity(0.55))
                }
                .padding(34).padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(ivory.opacity(reduceTransparency ? 1 : 0.86))
        }
        .background { if reduceTransparency { ivory } else { FrostedSurface() } }
        .tint(forest)
        .overlay(alignment: .bottomTrailing) {
            if model.busy { hud.padding(24) }
        }
        .alert("Voicex", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) {
            Button("Понятно", role: .cancel) { model.message = nil }
        } message: { Text(model.message ?? "") }
        .confirmationDialog("Удалить демонстрационную модель?", isPresented: $showRemoval) {
            Button("Удалить модель", role: .destructive) { model.removeModel() }
        } message: { Text("Реальные файлы не загружались. Можно снова проверить установку.") }
        .confirmationDialog("Очистить историю?", isPresented: $showHistoryClear) {
            Button("Очистить", role: .destructive) { model.history.removeAll() }
        }
        .sheet(isPresented: $showShortcut) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Горячая клавиша").font(.title2.weight(.semibold))
                Text("Выберите комбинацию для макета. Глобальная обработка клавиш будет подключена вместе с диктовкой.")
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Picker("Комбинация", selection: $shortcut) {
                    Text("⌃ ⇧ Space").tag("⌃ ⇧ Space")
                    Text("⌥ Space").tag("⌥ Space")
                    Text("⌃ ⌥ D").tag("⌃ ⌥ D")
                }.pickerStyle(.segmented)
                Button("Готово") { showShortcut = false }.buttonStyle(SoftButton(primary: true))
            }.padding(30).frame(width: 440)
        }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Voicex").font(.system(size: 38, weight: .medium, design: .serif))
                .foregroundStyle(forest).padding(.horizontal, 18).padding(.top, 46).padding(.bottom, 26)
            ForEach(Section.allCases) { section in
                Button { model.section = section } label: {
                    HStack(spacing: 12) {
                        Image(systemName: section.symbol).font(.system(size: 19)).frame(width: 24)
                        Text(section.rawValue).font(.system(size: 13, weight: model.section == section ? .medium : .regular)).lineLimit(1).minimumScaleFactor(0.9)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(model.section == section ? forest : forest.opacity(0.7))
                    .padding(.horizontal, 16).padding(.vertical, 16)
                    .background(model.section == section ? sage.opacity(0.24) : .clear, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 17))
                }.buttonStyle(.plain).accessibilityIdentifier("nav-\(section.id)")
            }
            Spacer()
            Divider().padding(.horizontal, 16)
            Label("Локально на Mac", systemImage: "lock").font(.system(size: 13))
                .foregroundStyle(forest.opacity(0.6)).padding(.horizontal, 18).padding(.top, 16)
            Text("Voicex 0.1.0 · UI preview").font(.system(size: 11)).foregroundStyle(forest.opacity(0.45))
                .padding(.leading, 47).padding(.bottom, 22)
        }.padding(.horizontal, 12).background(sage.opacity(0.13))
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(model.section == .dictation ? "Проверим диктовку" : model.section.rawValue)
                    .font(.system(size: 32, weight: .medium, design: .serif)).foregroundStyle(forest)
                Spacer()
                if model.section == .dictation {
                    Label(model.modelReady ? "Модель готова · демо" : "Нет модели", systemImage: "circle.fill")
                        .font(.system(size: 11)).foregroundStyle(sage)
                        .padding(10).background(.white.opacity(0.3), in: Capsule())
                }
            }
            Text(subtitle).font(.system(size: 15)).foregroundStyle(forest.opacity(0.6))
        }
    }
    private var subtitle: String {
        switch model.section {
        case .dictation: "Нажмите кнопку — тестовый текст появится ниже."
        case .settings: "Настройте диктовку под себя."
        case .models: "Локальная модель распознавания."
        case .history: "Вы решаете, сохранять ли расшифровки."
        case .onboarding: "Три шага до первой диктовки."
        }
    }
    private var dictation: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "mic.fill").font(.system(size: 44)).foregroundStyle(sage)
                    .frame(width: 112, height: 112)
                    .background(sage.opacity(0.12), in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2))
                Text(model.recording ? "Запись · \(time)" : model.processing ? "Распознаём…" : model.modelReady ? "Готово к проверке" : "Сначала установите модель")
                    .foregroundStyle(forest).font(.system(size: 15))
                Text(shortcut).font(.system(size: 15, weight: .medium)).padding(.horizontal, 20).padding(.vertical, 10)
                    .background(.white.opacity(0.35), in: Capsule())
                if model.modelReady {
                    Button(model.recording ? "Остановить проверку" : "Начать проверку") {
                        if model.recording { model.stop() } else { model.start() }
                    }.buttonStyle(SoftButton(primary: true)).disabled(model.processing)
                } else {
                    Button("Перейти к установке") { model.section = .models }.buttonStyle(SoftButton(primary: true))
                }
                Text("Сейчас проверяем состояния интерфейса, без записи голоса.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity).padding(.vertical, 12)
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
        VStack(alignment: .leading, spacing: 24) {
            row("Язык распознавания") {
                Picker("Язык", selection: $language) { ForEach(["Auto", "RU", "EN"], id: \.self) { Text($0) } }
                    .labelsHidden().pickerStyle(.segmented).frame(width: 270)
            }
            Divider()
            row("Горячая клавиша") { Button(shortcut) { showShortcut = true }.buttonStyle(SoftButton()) }
            Divider()
            row("Режим записи") {
                Picker("Режим", selection: $mode) { ForEach(["Нажатие", "Удержание"], id: \.self) { Text($0) } }
                    .labelsHidden().pickerStyle(.segmented).frame(width: 270)
            }
            Text(mode == "Нажатие" ? "Первое нажатие — запись, второе — остановка." : "Удерживайте клавиши во время записи.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Divider()
            Text("Разрешения").font(.system(size: 15)).foregroundStyle(.secondary)
            permission("Микрофон", icon: "mic", checked: model.microphoneDemo) { model.microphoneDemo.toggle() }
            permission("Вставка текста", icon: "accessibility", checked: model.accessibilityDemo) { model.accessibilityDemo.toggle() }
            Text("Кнопки переключают демонстрационные состояния. Системные разрешения пока не запрашиваются.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Button("Открыть системные настройки") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
            }.buttonStyle(SoftButton())
        }
    }
    private var models: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 24) {
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
                row("Состояние") { Text(model.installing ? "Установка · демо" : model.modelReady ? "Готова · демо" : "Не установлена").foregroundStyle(sage) }
                if model.installing {
                    ProgressView(value: model.progress)
                    Button("Отменить установку") { model.cancelInstall() }.buttonStyle(SoftButton())
                } else if model.modelReady {
                    Button("Удалить модель") { showRemoval = true }.buttonStyle(SoftButton()).disabled(model.busy)
                } else {
                    Button("Установить Whisper · демо") { model.install() }.buttonStyle(SoftButton(primary: true)).disabled(model.busy)
                }
            }.padding(26).background(.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 24))
            Label("После реальной установки диктовка будет работать без интернета.", systemImage: "info.circle")
                .font(.system(size: 13)).foregroundStyle(.secondary)
            Text("В этом каркасе проверяются установка, отмена и удаление. Файлы модели не скачиваются.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
    private var history: some View {
        VStack(alignment: .leading, spacing: 24) {
            Toggle("Сохранять тестовые результаты в этой сессии", isOn: $model.historyEnabled).toggleStyle(.switch)
            Text("По умолчанию выключено. В каркасе история живёт только в памяти и исчезнет после выхода.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Divider()
            if model.history.isEmpty {
                VStack(spacing: 18) {
                    Image(systemName: "clock").font(.system(size: 40)).foregroundStyle(sage)
                        .frame(width: 92, height: 92).background(sage.opacity(0.12), in: Circle())
                    Text(model.historyEnabled ? "Пока нет результатов" : "История выключена").font(.system(size: 21, weight: .medium))
                    Text(model.historyEnabled ? "Проверьте диктовку, чтобы увидеть тестовую запись." : "Сейчас доступен только последний результат.")
                        .foregroundStyle(.secondary)
                    Button(model.historyEnabled ? "Проверить диктовку" : "Включить историю") {
                        if model.historyEnabled { model.section = .dictation } else { model.historyEnabled = true }
                    }.buttonStyle(SoftButton())
                }.frame(maxWidth: .infinity).padding(.vertical, 38)
            } else {
                ForEach(model.history) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.text).textSelection(.enabled)
                            Text(item.date, style: .time).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { model.copy(item.text) } label: { Image(systemName: "doc.on.doc") }.buttonStyle(SoftButton())
                    }.padding(18).background(.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
                }
                Button("Очистить историю") { showHistoryClear = true }.buttonStyle(SoftButton())
            }
        }
    }
    private var onboarding: some View {
        VStack(alignment: .leading, spacing: 18) {
            step(1, "Разрешите микрофон", "Для записи вашего голоса", done: model.microphoneDemo) {
                model.microphoneDemo = true
                model.message = "Отмечено для проверки интерфейса. Настоящий запрос микрофона появится при подключении записи."
            }
            step(2, "Разрешите вставку текста", "Через Универсальный доступ macOS", done: model.accessibilityDemo) {
                model.accessibilityDemo = true
                model.message = "Отмечено для проверки интерфейса. Автовставка и проверка системного доступа пока не подключены."
            }
            HStack(spacing: 18) {
                number(3)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Установите модель").font(.system(size: 17, weight: .medium))
                    Text("Распознавание будет работать локально.").font(.system(size: 13)).foregroundStyle(.secondary)
                    if model.installing { ProgressView(value: model.progress) }
                }
                Spacer()
                if model.modelReady { Label("Готово · демо", systemImage: "checkmark.circle.fill").foregroundStyle(sage) }
                else { Button(model.installing ? "Отменить" : "Установить · демо") { if model.installing { model.cancelInstall() } else { model.install() } }.buttonStyle(SoftButton(primary: !model.installing)) }
            }.padding(20).background(.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 22))
            Divider().padding(.vertical, 8)
            Button("Проверим диктовку") { model.section = .dictation }.buttonStyle(SoftButton(primary: true)).disabled(!model.modelReady)
            Text("Без доступа к вставке можно копировать текст вручную.").font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
    private var time: String { String(format: "%02d:%02d", model.seconds / 60, model.seconds % 60) }
    private var hud: some View {
        HStack(spacing: 16) {
            if model.recording {
                Button { model.stop() } label: {
                    Image(systemName: "stop.fill").foregroundStyle(.white).frame(width: 36, height: 36).background(.orange, in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("Остановить проверку")
                HStack(alignment: .center, spacing: 3) {
                    ForEach(0..<15) { i in Capsule().fill(sage).frame(width: 3, height: CGFloat([8, 15, 24, 12, 32, 19, 10][(i + model.seconds) % 7])) }
                }.frame(height: 34)
            } else { ProgressView().controlSize(.small) }
            Text(model.recording ? "Запись · \(time)" : "Распознаём…").font(.system(size: 12)).foregroundStyle(forest)
            Button { model.cancel() } label: { Image(systemName: "xmark").frame(width: 30, height: 30).background(.white.opacity(0.4), in: Circle()) }
                .buttonStyle(.plain).accessibilityLabel("Отменить проверку")
        }.padding(14).background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
            .shadow(color: forest.opacity(0.1), radius: 14, y: 6)
    }
    private func row<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        HStack { Text(title).font(.system(size: 15)); Spacer(); content() }.frame(minHeight: 32)
    }
    private func permission(_ title: String, icon: String, checked: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Label(title, systemImage: icon).font(.system(size: 15))
            Spacer()
            Button(checked ? "Демо-доступ ✓" : "Проверить состояние") { action() }.buttonStyle(SoftButton())
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
            Button(done ? "Готово · демо ✓" : "Проверить") { action() }.buttonStyle(SoftButton())
        }.padding(20).background(.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 22))
    }
}
