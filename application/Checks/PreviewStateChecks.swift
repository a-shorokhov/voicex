import Foundation
@main struct StateChecks {
    static func main() {
        var gate = SessionGate()
        let cancelled = gate.begin()
        precondition(gate.accepts(cancelled)); gate.cancel()
        precondition(!gate.accepts(cancelled))
        let next = gate.begin()
        precondition(!gate.accepts(cancelled) && gate.accepts(next))
        let blocked = HotkeyConfiguration(label: "Правый ⌘", trusted: false, suspended: false)
        let granted = HotkeyConfiguration(label: "Правый ⌘", trusted: true, suspended: false)
        precondition(blocked.needsAccessibility && !blocked.backgroundAvailable)
        precondition(granted.backgroundAvailable && blocked != granted)
        precondition(granted == HotkeyConfiguration(label: "Правый ⌘", trusted: true, suspended: false))
        precondition(HotkeyConfiguration(label: "⌃ ⇧ Space", trusted: false, suspended: false).backgroundAvailable)
        precondition(!HotkeyConfiguration(label: "Правый ⌘", trusted: true, suspended: true).backgroundAvailable)
        precondition(!HotkeyConfiguration(label: "Не указано", trusted: true, suspended: false).backgroundAvailable)
        let silentBars = Array(repeating: Float(0), count: 280).withUnsafeBufferPointer { MicrophoneWaveform.levels($0) }
        precondition(silentBars.count == 28 && silentBars.allSatisfy { $0 == 0 })
        let variedAudio = Array(repeating: Float(0.1), count: 140) + Array(repeating: Float(0), count: 140)
        let variedBars = variedAudio.withUnsafeBufferPointer { MicrophoneWaveform.levels($0) }
        precondition(variedBars.prefix(14).allSatisfy { $0 > 0.7 && $0 <= 1 })
        precondition(variedBars.suffix(14).allSatisfy { $0 == 0 })
        let shifted = MicrophoneWaveform.shifted([0.1, 0.2, 0.3], newLevels: [0.8, 0.8])
        precondition(shifted.count == 3 && shifted[0] == 0.2 && shifted[1] == 0.3 && abs(shifted[2] - 0.8) < 0.001)
        let paused = MicrophoneWaveform.shifted(shifted, newLevels: [0])
        precondition(paused[0] == 0.3 && paused[1] == shifted[2] && paused[2] == 0)
        var edge = HotkeyEdge()
        precondition(edge.down() && !edge.down() && edge.up() && !edge.up() && edge.down())
        precondition(!RecordingPolicy.hasSpeech([]))
        precondition(!RecordingPolicy.hasSpeech(Array(repeating: 0.2, count: 7999)))
        precondition(!RecordingPolicy.hasSpeech(Array(repeating: 0, count: 16000)))
        precondition(!RecordingPolicy.hasSpeech(Array(repeating: 0.00001, count: 16000)))
        precondition(RecordingPolicy.hasSpeech(Array(repeating: 0.05, count: 16000)))
        precondition(RecordingPolicy.maximumSamples == 4_800_000)
        precondition(PasteService.matches(originalPID: 10, currentPID: 10, sameElement: true, safe: true, trusted: true))
        for scenario in [(Optional<pid_t>(11), true, true, true), (nil, true, true, true), (10, false, true, true), (10, true, false, true), (10, true, true, false)] {
            precondition(!PasteService.matches(originalPID: 10, currentPID: scenario.0, sameElement: scenario.1, safe: scenario.2, trusted: scenario.3))
        }
        print("State checks passed: cancellation, replacement, key repeat/release, silence/short/energy, five-minute cap, guarded paste.")
    }
}
