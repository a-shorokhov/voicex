# Voicex — подробный план macOS-приложения

## 1. Назначение

Menu bar-приложение локальной диктовки для одного пользователя: выбрать поле → начать запись глобальной клавишей → говорить → остановить → распознать → вставить. Если вставка невозможна, результат доступен для ручного копирования. После установки модели и перезапуска диктовка работает офлайн.

Платформа: Apple Silicon M1+, macOS 14+. Русский UI, проверяем RU и EN. Первый релиз без Developer ID/нотаризации. Дизайн системный macOS, фирменная доводка позже.

Не повторять весь Wispr Flow: нет отдельной LLM, переписывания речи, cloud ASR, аккаунтов, платежей, истории, контекста из других приложений, meetings/notetaker и синхронизации.

## 2. Минимальный проект

Стандартный Xcode-проект: один app target, один XCTest target, shared scheme. SwiftUI для окон/настроек; AppKit для nonactivating indicator и системной интеграции; AVFoundation для записи; UserDefaults для настроек. Подключить через SPM WhisperKit из argmaxinc/argmax-oss-swift, initial pinned version 1.1.0, и KeyboardShortcuts со стабильной версией, зафиксированной в resolved dependencies. Выровнять language mode с зависимостью; не проводить самостоятельную миграцию strict-concurrency ради этого MVP.

Выбрать только WhisperKit product. Не добавлять umbrella ArgmaxOSS, TTSKit, SpeakerKit, local server и дополнительные inference runtimes. Нет Python sidecar, Electron, Tauri, HTTP API, database и Docker.

Достаточная структура:

| Компонент | Работа |
| --- | --- |
| AppModel | UI, координация, текущая сессия диктовки |
| Recorder | Микрофон, преобразование, буфер, stop/cancel |
| SpeechService | Установка, загрузка, вызов WhisperKit |
| HotkeyController | Привязка и оба режима |
| PasteService | Исходная цель, clipboard, Cmd+V/fallback |

Системные permission checks — небольшие функции рядом. Не делать architecture framework. UI-состояние обновляется на main actor; экземпляр WhisperKit живёт в сериализованном контексте SpeechService. Одна активная операция диктовки. Не обходить concurrency errors повсеместным unchecked Sendable; сначала исправить владение состоянием.

## 3. Интерфейс

Menu bar icon, onboarding, Settings, nonactivating recording/transcribing panel, последний результат с Copy. Использовать стандартные SwiftUI формы и системные элементы.

Menu bar: состояние, настройки, последний результат, start/stop, выход. Onboarding: назначение приложения, разрешения, установка модели, тестовая диктовка. Settings: модель/статус, install/cancel/retry/remove, режим hotkey, recorder комбинации, Auto/ru/en, состояние permissions и версия.

HUD не забирает фокус текстового поля. Показывает запись/длительность/простую амплитуду или распознавание и кнопку отмены. Не нужен отдельный сложный waveform engine. Состояния должны различаться текстом, а не только цветом.

Не добавлять историю, множество моделей и внутренние knobs декодирования в UI.

## 4. Разрешения

Microphone — запись; Accessibility — вставка. Объяснить цель перед запросом. После возвращения из System Settings повторно проверить разрешение. Без microphone недоступна запись; без Accessibility доступна диктовка с ручным копированием. Отказы, отзыв разрешений и повторный запрос не приводят к crash/вечной загрузке.

Screen Recording не нужен. Input Monitoring не запрашивать без подтверждённой необходимости выбранного hotkey API. Не читать окружающий текст или clipboard для улучшения распознавания.

При переносе приложения и обновлении ad hoc-сборки macOS может потребовать повторно выдать Accessibility. Описать проверенное поведение в README, не обещать стабильность permissions между неподписанными сборками.

## 5. Установка модели и offline-first

Одна модель:

```text
WhisperKit variant: large-v3-v20240930_626MB
Source repository: argmaxinc/whisperkit-coreml
Local root: ~/Library/Application Support/Voicex/
```

Это локальная модель Whisper в формате для WhisperKit, а не отдельное приложение Wispr/Whisper. Не требовать Homebrew, Python и терминал у пользователя.

Последовательность: показать название/примерный размер → install по явному нажатию → progress → необходимые model/tokenizer assets → подготовка Core ML → успешная load-проверка → ready. SDK умеет скачивание и кеширование; повторно использовать их.

Статусы: missing, downloading, preparing, ready, failed. Cancel доступен при загрузке; повтор не объявляет неполную папку установленной. Показать ошибки сети, места, повреждённых/неполных файлов и load. Не делать бесконечный автоматический retry. Ready устанавливать после реальной успешной подготовки.

Сохранять фактические локальные пути, включая токенизатор. При запуске использовать local modelFolder/tokenizerFolder и download=false. Проверить, что SDK не обращается к сети за отсутствующими tokenizer/config assets. Не создавать WhisperKit с default auto-download во время обычной диктовки.

Первый warmup может быть заметным; UI должен различать скачивание и подготовку и не замерзать. Полный download size показывать по доступным метаданным, не объявлять название 626MB гарантированным размером всего кеша.

Remove unload-ит модель, затрагивает только файлы Voicex и возвращает missing. Не удалять чужой shared-cache. В текущей подготовке не скачивать модель: это делает агент приложения при проверке реализации.

## 6. Запись и hotkey

Начальная комбинация Control+Shift+Space, редактируемая. Начальный режим toggle. KeyboardShortcuts должен обеспечивать key-down/up и recorder UI без собственного мониторинга всех клавиш.

Toggle: первое нажатие start, второе stop → transcribe; key repeat подавляется. Hold: down start, up stop → transcribe. После auto-stop release не запускает новое действие. Во время transcribing/preparing нет новой записи. Переназначение выключает обработку; смена режима действует для следующей сессии.

Recorder использует текущий default microphone, преобразует native input в mono Float32 16kHz. Буфер в памяти. Максимум пять минут; по лимиту stop и transcribe. Ранний тест интерфейса может использовать кнопку, но финальный путь hotkey обязателен.

Cancel освобождает буфер и запрещает позднюю вставку. Сон, смена/отключение microphone, отзыв разрешений и exit прекращают запись. Не писать постоянные аудиофайлы. Не нужен отдельный device-picker в MVP.

## 7. Распознавание и состояние

Transcription начинается после stop. Task transcribe, не translate. Auto по умолчанию, ru/en при явном выборе. Один запрос к экземпляру WhisperKit; UI остаётся responsive. Использовать штатное разбиение/декодирование SDK для длинных записей, не создавать streaming-вставку и собственный speech-server.

Возвращать текст Whisper с его пунктуацией. Допустимы trim/нормализация пробелов/удаление технических tokens. Отдельно не переписывать смысл, не форматировать письма LLM.

Слишком короткая запись или тишина не должны давать выдуманную вставку. Простой duration/energy guard плюс штатный no-speech handling SDK; без отдельной нейронной VAD-зависимости. Empty → «Речь не распознана».

Основные состояния диктовки: idle, recording, transcribing, pasting, recoverable error. Подготовка модели имеет отдельное состояние. Каждая сессия имеет идентификатор; отмена/новая сессия инвалидирует старый результат. Даже если compute нельзя немедленно прервать, cancelled-result не вставляется.

Последний успешный текст хранится только в памяти. После ошибки приложение возвращается к доступному действию, а не остаётся busy. RU/EN quality проверяется реальными фразами; mixed-language input — измеряемое ограничение, не маркетинговая гарантия.

## 8. Вставка

На start зафиксировать frontmost application PID и доступный AX focused element. Не собирать текст поля. На result проверить исходное приложение, фокус и отсутствие secure target/input.

Если исходная цель подтверждена: положить текст в NSPasteboard → Cmd+V. Enter не нажимать. Не восстанавливать прежний clipboard автоматически: текст остаётся доступен для повторной ручной вставки. Поведение отражено в интерфейсе/приватности.

При смене приложения, поля, невозможности проверки, protected input или отсутствии Accessibility — не отправлять Cmd+V, показать результат и Copy. Не выдавать системный key event за доказательство успешной вставки. Supported-app integration проверяется вручную.

Автовставка из menu bar-кнопки не должна случайно вставить в само окно Voicex; при неизвестной исходной цели — manual result. Во время onboarding тестовый текст показывать внутри приложения.

## 9. Данные

Нет cloud ASR, telemetry, automatic crash upload и remote text editing. Нет API keys. Audio хранится в памяти и освобождается после сессии. Transcript не логируется. Settings — UserDefaults, weights/tokenizer — Application Support. Логи диагностируют тип события/ошибки без содержания.

Использовать нейтральные synthetic phrases в тестах. Личные диктовки не включать в repo и public bug reports. Учитывать, что использование системного clipboard имеет свойства самого clipboard/ОС, а не только приложения.

## 10. Сборка и DMG

Bundle identifier `io.github.a-shorokhov.voicex`, version 0.1.0, arm64, target macOS 14. Shared Xcode scheme для CLI. Обычный app bundle; необходимые usage descriptions и permissions. Для первого релиза local/ad hoc signing, без Developer ID/нотаризации. Не заявлять, что ad hoc удовлетворяет Gatekeeper.

Добавить scripts build-release и package-dmg внутри application. Использовать Xcode, hdiutil и SHA-256; дополнительный installer framework не нужен. DMG содержит Voicex.app и Applications shortcut. Веса внутри DMG отсутствуют.

Артефакты: `Voicex-macos-arm64.dmg`, `SHA256SUMS.txt`. Build outputs игнорируются Git. Проверить запуск именно из установщика после копирования в Applications, включая разрешения и model installation.

В private repo Releases не доступны публичному посетителю. Сейчас подготовить локальный DMG и сообщить путь. Внешняя публикация и смена приватности — отдельное разрешение, не часть задания на реализацию.

## 11. Этапы

1. Xcode project, menu bar, окна, shared scheme.
2. Permissions/onboarding.
3. Install/load/warmup/offline paths.
4. Recorder и показ результата внутри app.
5. Оба hotkey modes и indicator/cancel.
6. Target capture, guarded paste, manual fallback.
7. Error recovery и meaningful unit tests.
8. Release scripts и DMG.
9. Offline/cold-start и installer manual acceptance.

На каждом этапе сохранять рабочее состояние. Полный чеклист MVP — в MVP.md. Не останавливаться после scaffolding или UI без рабочего распознавания.

## 12. Проверки

XCTest с подменами: toggle/hold/key repeat, concurrent-action guard, cancel/late result, empty transcript, missing model, failure/retry, changed target/fallback, recovery after error. CI build/test не скачивает модель и не использует microphone.

Ручные сценарии: initial permissions и отказы, отмена/обрыв install, restart offline, RU/EN, silence, five-minute cap, change focus/app, secure field, sleep/device disconnect, DMG install. Проверить paste в TextEdit, Notes, Safari/Chrome textarea и VS Code.

Записать actual performance: initial prepare, warmed transcription time для фиксированной длины, RAM и характеристики тестового Mac. Не обещать latency без измерений. Если нет доступа к Mac/macOS 14 для конкретной проверки — честно указать limitation; deployment target сам по себе не доказывает совместимость.

## 13. Roadmap — НЕ текущий MVP

После отдельного согласования: качество по реальным ошибкам; ещё Whisper-модели; device picker/login launch; словарь имён; preview; исследование Parakeet; локальная LLM editing; выключенная по умолчанию history; Developer ID/нотаризация/updates.

Для Parakeet нужен отдельный runtime/формат и benchmark на целевом Mac. WhisperKit OSS не считать готовым универсальным engine для него. Не создавать adapter architecture до второго работающего engine. Для history сначала рассмотреть простой локальный файл, не серверную базу.

## 14. Источники

- [WhisperKit / Argmax OSS](https://github.com/argmaxinc/argmax-oss-swift).
- [Pinned package v1.1.0](https://github.com/argmaxinc/argmax-oss-swift/blob/v1.1.0/Package.swift).
- [WhisperKitConfig](https://github.com/argmaxinc/argmax-oss-swift/blob/v1.1.0/Sources/WhisperKit/Core/Configurations.swift).
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts).
- [Apple: manual launch](https://support.apple.com/en-md/guide/mac-help/mh40616/mac).
- Общие источники и release contract — в ../PROJECT.md.
