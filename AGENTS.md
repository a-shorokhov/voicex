# Voicex — instructions for coding agents

Voicex is a small local macOS dictation app and a static download website, designed initially for one user. Simplicity is the main engineering requirement.

## Read only the context needed

- Read `PROJECT.md` once when starting a substantive task.
- For implementation, read the assigned folder's `AGENTS.md` and `MVP.md`.
- Read `PLAN.md` for architecture or roadmap context; its future work is not part of the MVP.
- Do not reread every document before each small edit.

## Keep the stack minimal

- Website: static HTML, CSS, TypeScript, Vite, npm.
- App: SwiftUI, necessary AppKit/AVFoundation APIs, WhisperKit, KeyboardShortcuts, UserDefaults.
- Do not add a backend, FastAPI, ORM, database, Docker, Python sidecar, cloud transcription, accounts, payments, Redis, queues, microservices, Kubernetes, analytics, or enterprise infrastructure.
- Do not add DI containers, repository/use-case layers, event buses, plugin systems, or abstractions for hypothetical future engines.
- Use one direct implementation until a real second use case requires an abstraction.

## Ownership and Git

- Website agent owns `landing/**` and, when needed, `.github/workflows/landing.yml`.
- App agent owns `application/**` and, when needed, `.github/workflows/application.yml`.
- Root documents and cross-component release coordination belong to the preparation/integration task.
- Do not edit another agent's area or revert unrelated changes.
- Parallel chats on different branches require separate Git worktrees. Never switch a shared checkout's branch underneath another chat.
- The repository is PRIVATE. Do not change visibility, publish source, publish Releases, enable Pages, or deploy externally unless the user authorizes that action. Local builds and fixes are authorized by an implementation request.

## Follow through and verify

- Implement the current MVP, not the future roadmap.
- Carry out routine local edits, builds, and relevant checks without repeated confirmation.
- Finish independent work if an external prerequisite is blocked; report the exact blocker.
- Test meaningful state transitions, concurrency, offline operation, and system integration. Do not create a large test framework for static prose.
- Rerun affected checks after fixes; do not repeatedly run unrelated suites.
- Distinguish checks that passed from checks not run. Do not invent verification results.
- Do not spawn additional agents unless explicitly requested.

## Data handling

- Never commit credentials, signing material, model weights, personal audio, dictated text, or private diagnostic dumps.
- Do not log dictation or target-field content. Use neutral synthetic test data.
- Do not add an OpenAI API key: Sol is the development agent, not an app runtime dependency.
- Keep `.gitignore` exceptions narrow and intentional.

Communicate in Russian, briefly state what changed and why, and include run instructions and material limitations.
