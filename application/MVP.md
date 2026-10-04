# Application MVP — исполняемая задача

## Результат

Нативное menu bar-приложение на Apple Silicon/macOS 14+: устанавливает одну Whisper-модель кнопкой, записывает голос двумя hotkey modes, распознаёт локально, guarded-вставляет в исходное поле или позволяет Copy. После установки и перезапуска работает офлайн. Итог — проверенный локальный DMG; публичная публикация отдельно из-за private repo.

## Фиксированные решения

- SwiftUI, необходимые AppKit/AVFoundation API, WhisperKit, KeyboardShortcuts, UserDefaults, XCTest.
- Обычный Xcode project, один app target + один test target, shared scheme.
- WhisperKit product из Argmax OSS, initial SDK 1.1.0 с resolved dependencies.
- Model `large-v3-v20240930_626MB` из `argmaxinc/whisperkit-coreml`.
- Русский UI, язык распознавания Auto/ru/en, default Auto.
- Hotkey Control+Shift+Space, configurable; toggle default, hold selectable.
- Максимум одна сессия и пять минут audio, transcription после stop.
- UserDefaults settings, Application Support/Voicex assets, in-memory audio/result.
- Bundle ID `io.github.a-shorokhov.voicex`, initial version 0.1.0.

## Этап A — проект и разрешения

- [ ] Создать Xcode app и shared scheme, deployment target 14, arm64.
- [ ] Подключить только WhisperKit и KeyboardShortcuts, не umbrella SDK.
- [ ] Menu bar, onboarding, Settings и last-result window.
- [ ] Microphone permission с объяснением и обработкой отказа.
- [ ] Accessibility check/request с повторной проверкой после System Settings.
- [ ] Без Accessibility доступна диктовка с Copy; без microphone нет записи.
- [ ] Не запрашивать Screen Recording и лишний Input Monitoring.
- [ ] Стандартный системный UI; не тратить этап на фирменный дизайн.

## Этап B — модель

- [ ] Install по явной кнопке, название, примерный размер, progress/cancel/retry.
- [ ] Download model и все tokenizer/config assets в app-controlled location.
- [ ] Состояния missing/downloading/preparing/ready/failed.
- [ ] Ready только после successful load/preparation, не по наличию папки.
- [ ] Сеть/обрыв/место/неполные файлы/load errors имеют recovery.
- [ ] При normal launch локальные modelFolder/tokenizerFolder, download=false.
- [ ] Remove unload-ит и удаляет только свои assets.
- [ ] Холодный запуск после установки без сети не тянет скрытые зависимости.

## Этап C — audio и ASR

- [ ] Default microphone, mono Float32 16kHz через корректное преобразование.
- [ ] In-memory buffer, five-minute auto-stop, stop/cancel cleanup.
- [ ] Локальная transcription, не translation, Auto/ru/en.
- [ ] UI responsive; экземпляр WhisperKit сериализован, одной сессией владеет AppModel.
- [ ] Показ результата внутри приложения до реализации системной вставки.
- [ ] Silence/short/empty не даёт выдуманную вставку; понятное сообщение.
- [ ] Cancel инвалидирует поздний result даже при продолжающемся compute.
- [ ] Sleep/exit/device failure прекращают запись, восстанавливают состояние.

## Этап D — hotkey и вставка

- [ ] Toggle: first press start, second stop; autorepeat не меняет состояние.
- [ ] Hold: down start, up stop; late up после auto-stop игнорируется.
- [ ] Recorder комбинации и переключатель mode, сохранение UserDefaults.
- [ ] Во время настройки комбинации/compute нет случайного start.
- [ ] Nonactivating indicator не забирает фокус; есть Cancel.
- [ ] На start захватить app PID и AX focused element, без чтения текстового содержимого.
- [ ] На result проверить исходную цель и protected input.
- [ ] Подтверждённая цель: NSPasteboard + Cmd+V, без Enter.
- [ ] Clipboard остаётся с transcript; не добавлять автоматический restore.
- [ ] Changed/unknown/secure target → last-result и Copy, без auto-paste.
- [ ] Нет persistent history, audio files, transcript logs, telemetry и API keys.

## Этап E — проверки и установщик

- [ ] XCTest для meaningful state/error/cancel/hotkey/target scenarios с подменами.
- [ ] Build-only/test `.github/workflows/application.yml`, без model download/microphone.
- [ ] Release build и package-DMG scripts внутри application.
- [ ] DMG: Voicex.app + Applications shortcut; без weights.
- [ ] Артефакты Voicex-macos-arm64.dmg и SHA256SUMS.txt.
- [ ] Локальная ad hoc-сборка без Developer ID/нотаризации; не объявлять её подписанной для обычной distribution.
- [ ] README с actual commands, permissions, manual Apple launch, known limitations.
- [ ] Notices применимых зависимостей сохранены.

## Обязательная ручная приёмка

1. Установить .app из полученного DMG в Applications, запускать оттуда.
2. Проверить первый запуск, permissions и отказы.
3. Установить модель кнопкой; проверить cancel/retry и preparation.
4. Закрыть приложение, отключить сеть, запустить и распознать без дополнительного download.
5. По нескольку нейтральных RU/EN фраз различной длины; recorded actual latency, не обещания.
6. Проверить тишину и очень короткую запись.
7. Проверить toggle/hold, переназначение и autorepeat.
8. Проверить paste в TextEdit, Notes, Safari/Chrome textarea и VS Code.
9. Сменить app/поле во время compute: auto-paste не должен попасть в новую цель.
10. Проверить защищённое поле, отсутствие Accessibility, manual Copy.
11. Проверить cancel, сон, device disconnect, выход и пяти-minute cap.

Невыполненные проверки перечислить явно. Не требовать реального audio/model в unit CI и не считать deployment target доказательством теста на старой macOS.

## Вне MVP

Parakeet, LLM editing, streaming-вставка, history, несколько моделей, vocabulary, microphone picker, launch-at-login, cloud/backend, payments/accounts, updater, Developer ID/нотаризация и публичная публикация.

Не меняй private-видимость repo и не публикуй Releases в рамках реализации. Следующий отдельный запрос определит публичный канал сайта/DMG.

## Итог агента

Дать рабочий local app, путь DMG/checksum, команды запуска/сборки, результаты автоматических и ручных проверок, точные external blockers. Не останавливаться на проекте, моковом UI или выводе текста без завершения остальных разрешённых задач MVP.
