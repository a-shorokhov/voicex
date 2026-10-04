# Voicex — общие решения и контракт

Дата подготовки: 4 октября 2026 года. Этот документ объединяет согласованный план и последнее уточнение пользователя: **репозиторий приватный**.

## Продукт

Один пользователь, локальная диктовка на Mac и простой сайт. Пользователь выбирает текстовое поле, запускает запись, говорит, останавливает запись и получает текст. Отдельная LLM для переписывания речи не входит в MVP.

| Область | Решение |
| --- | --- |
| Название | Voicex |
| GitHub | `a-shorokhov/voicex`, private |
| Основные папки | `landing/`, `application/` |
| Агенты разработки | GPT-6.1 Sol, Medium |
| Платформа | Apple Silicon M1+, macOS 14+ |
| Язык интерфейса | Русский |
| Проверяемая диктовка | Русский, английский |
| Сайт | Статические HTML-страницы, CSS, TypeScript, Vite |
| Приложение | SwiftUI, AppKit/AVFoundation, WhisperKit, KeyboardShortcuts |
| Хранение настроек | UserDefaults |
| Хранение модели | Application Support/Voicex |
| Первый установщик | DMG, без Developer ID и нотариализации |
| Дизайн | Отдельный последующий этап |

Главный приоритет: максимально простая работающая реализация. Нет backend, FastAPI, ORM, базы, Docker, sidecar, аккаунтов, платежей, облачной синхронизации, очередей и инфраструктуры масштабирования.

## Границы первого релиза

- Одна модель Whisper, установка по кнопке.
- Два режима горячей клавиши; начальный режим — повторное нажатие.
- Начальная комбинация Control+Shift+Space, с возможностью переназначения.
- Язык Auto, ru или en; начальный вариант Auto.
- Распознавание после остановки записи, без streaming-вставки.
- Одна операция диктовки за раз, максимум пять минут аудио.
- Автоматическая вставка только в проверенную исходную цель; иначе результат для ручного копирования.
- Нет постоянной истории, аудио на диске и телеметрии.
- Последний текст хранится в памяти приложения. При вставке текст остаётся в системном clipboard.

## Контракт между двумя частями

Пока нет HTTP API и общей runtime-библиотеки. Сайт и приложение связаны только описанием продукта и установщиком.

```text
Repository: a-shorokhov/voicex (PRIVATE)
Application: Voicex
Bundle identifier: io.github.a-shorokhov.voicex
Minimum macOS: 14.0
Architecture: arm64
Initial version: 0.1.0
Release tag: app-v0.1.0
DMG asset: Voicex-macos-arm64.dmg
Checksum asset: SHA256SUMS.txt
```

Если пользователь позже выберет публичный репозиторий и Pages, ожидаемый site base — `/voicex/`, адрес — `https://a-shorokhov.github.io/voicex/`, download URL — `https://github.com/a-shorokhov/voicex/releases/latest/download/Voicex-macos-arm64.dmg`.

Эти адреса сейчас **не считаются публично рабочими**. В private-репозитории такой download URL не подходит публичному посетителю. Лендинг должен иметь отдельную конфигурацию доступности релиза и download URL; до реальной публикации — состояние «Релиз готовится».

Имя DMG сохранять между релизами. Не создавать отдельные Releases лендинга, если используется ссылка `releases/latest`.

## Публикация и приватность репозитория

Первоначальный план предусматривал бесплатный GitHub Pages с публичным кодом. Последняя инструкция меняет приватность на private и имеет приоритет.

Не останавливать локальную реализацию из-за выбора хостинга. Сделать переносимый статический `dist` и локальный DMG. Публичный выпуск считать внешним этапом с одним из будущих решений пользователя:

1. GitHub Pro и Pages из private-репозитория; для публичного DMG всё равно потребуется публичный канал загрузки.
2. Отдельный публичный репозиторий только с результатами сборки и Releases.
3. Другой статический хостинг и публичное хранение DMG при private-исходниках.
4. Изменение исходного репозитория на public, только по явному указанию пользователя.

Не выбирать эти варианты молча, не подключать платные услуги и не публиковать код в рамках создания структуры.

## Организация агентов

- `feat/landing-mvp`: `landing/**`, `.github/workflows/landing.yml`.
- `feat/application-mvp`: `application/**`, `.github/workflows/application.yml`.
- Параллельные ветки — в разных worktree.
- Root-инструкции и контракт принадлежат задаче интеграции.
- Общих package manager workspace, lock-файлов и shared-модулей нет.
- Каждый агент реализует только свой `MVP.md`; roadmap не является разрешением на реализацию.

## Промптинг Sol 6.1 Medium

Указывать цель, рабочую область, ограничения стека, проверяемое завершение и внешние блокеры. `AGENTS.md` должен быть коротким; подробное поведение живёт в `MVP.md`. Разрешать обычные локальные действия, требовать завершать задачу и честно различать выполненные и непроверенные проверки. Дополнительные агенты автоматически не нужны.

Официальная документация указывает Medium как стандартный reasoning effort для GPT-6.1 Sol. Рекомендации семейства GPT-6 описаны на примерах Astra; правила границ папок и минимального стека — проектные решения, а не особые требования модели.

## Проверенные источники

- [GPT-6 и GPT-6.1 Sol: настройки и рекомендации](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-6.1-sol).
- [OpenAI: инструкции, AGENTS.md и объём контекста](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra).
- [Codex: Git worktrees](https://learn.chatgpt.com/docs/environments/git-worktrees).
- [Handy: пользовательский сценарий локальной диктовки](https://handy.computer/).
- [Wispr Flow: ориентир дальнейшего развития](https://wisprflow.ai/).
- [Argmax OSS / WhisperKit](https://github.com/argmaxinc/argmax-oss-swift).
- [WhisperKit: конфигурация v1.1.0](https://github.com/argmaxinc/argmax-oss-swift/blob/v1.1.0/Sources/WhisperKit/Core/Configurations.swift).
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts).
- [NVIDIA Parakeet v3: языки и модель](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3).
- [GitHub Pages: доступность для public/private](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages).
- [GitHub: ссылки на Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases).
- [Vite: статическая публикация и base](https://vite.dev/guide/static-deploy.html#github-pages).
- [Apple: ручной запуск приложения неизвестного разработчика](https://support.apple.com/en-md/guide/mac-help/mh40616/mac).

Не переносить branding, отзывы и заявления конкурентов в Voicex. Сохранять применимые notices зависимостей. Сам факт доступности Git-репозитория не заменяет выбор лицензии продукта.
