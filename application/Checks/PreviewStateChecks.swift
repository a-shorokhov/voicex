import Foundation
@main struct StateChecks {
    static func main() {
        var gate = SessionGate()
        let cancelled = gate.begin()
        precondition(gate.accepts(cancelled)); gate.cancel()
        precondition(!gate.accepts(cancelled))
        let next = gate.begin()
        precondition(!gate.accepts(cancelled) && gate.accepts(next))
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
