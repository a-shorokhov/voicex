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
