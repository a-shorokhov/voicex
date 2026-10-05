import Foundation
struct SessionGate {
    private(set) var id: UUID?
    mutating func begin() -> UUID { let value = UUID(); id = value; return value }
    mutating func cancel() { id = nil }
    func accepts(_ value: UUID) -> Bool { id == value }
}
struct HotkeyEdge {
    private(set) var pressed = false
    mutating func down() -> Bool { guard !pressed else { return false }; pressed = true; return true }
    mutating func up() -> Bool { guard pressed else { return false }; pressed = false; return true }
}

struct RecordingPolicy {
    static let maximumSamples = 16000 * 300
    static func hasSpeech(_ samples: [Float]) -> Bool {
        guard samples.count >= 8000, samples.contains(where: { abs($0) > 0.01 }) else { return false }
        return samples.reduce(0.0, { $0 + Double($1 * $1) }) / Double(samples.count) > 0.000001
    }
}

struct HotkeyConfiguration: Equatable {
    let label: String
    let trusted: Bool
    let suspended: Bool
    static let modifierOnly: Set<String> = ["Правый ⌘", "Правый ⌥", "Правый ⇧", "Правый ⌃", "⌥ + ⌘", "⌃ + ⌘", "⌃ + ⌥", "⇧ + ⌘", "⌥ + ⇧", "⌃ + ⇧", "Fn"]
    var needsAccessibility: Bool { Self.modifierOnly.contains(label) && !trusted }
    var backgroundAvailable: Bool { !suspended && label != "Не указано" && !needsAccessibility }
}

// Each bar measures its own portion of the latest microphone buffer.
// Map -54…-12 dBFS to the display range; silence never creates fake movement.
enum MicrophoneWaveform {
    // One new moment of sound enters at the right edge; older moments move left.
    static func shifted(_ history: [CGFloat], newLevels: [Float]) -> [CGFloat] {
        guard !history.isEmpty else { return [] }
        let average = newLevels.isEmpty ? 0 : newLevels.reduce(0, +) / Float(newLevels.count)
        let peak = newLevels.max() ?? 0
        let next = CGFloat(min(1, max(0, average * 0.6 + peak * 0.4)))
        return Array(history.dropFirst()) + [next]
    }

    static func levels(_ samples: UnsafeBufferPointer<Float>) -> [Float] {
        (0..<28).map { bar in
            let start = bar * samples.count / 28
            let end = (bar + 1) * samples.count / 28
            guard end > start else { return 0 }
            var energy: Float = 0
            for index in start..<end {
                let value = samples[index].isFinite ? samples[index] : 0
                energy += value * value
            }
            let rms = sqrt(energy / Float(end - start))
            return min(1, max(0, (20 * log10(max(rms, 0.00001)) + 54) / 42))
        }
    }
}
