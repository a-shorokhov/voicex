import XCTest
@testable import Voicex

final class StateTests: XCTestCase {
    func testMissingTokenizerFailsLocally() async {
        do {
            _ = try await LocalTokenizer(folder: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString))
            XCTFail("A missing tokenizer must fail instead of downloading")
        } catch { /* Missing local files are recoverable via explicit installation. */ }
    }
    func testCancelledSessionRejectsLateResultAndNextSession() {
        var gate = SessionGate()
        let cancelled = gate.begin()
        XCTAssertTrue(gate.accepts(cancelled))
        gate.cancel()
        XCTAssertFalse(gate.accepts(cancelled))
        let next = gate.begin()
        XCTAssertFalse(gate.accepts(cancelled))
        XCTAssertTrue(gate.accepts(next))
    }
    func testSilenceShortRecordingAndSpeech() {
        XCTAssertFalse(RecordingPolicy.hasSpeech([]))
        XCTAssertFalse(RecordingPolicy.hasSpeech(Array(repeating: 0.2, count: 7999)))
        XCTAssertFalse(RecordingPolicy.hasSpeech(Array(repeating: 0, count: 16000)))
        XCTAssertFalse(RecordingPolicy.hasSpeech(Array(repeating: 0.00001, count: 16000)))
        XCTAssertTrue(RecordingPolicy.hasSpeech(Array(repeating: 0.05, count: 16000)))
        XCTAssertEqual(RecordingPolicy.maximumSamples, 4_800_000)
    }
    func testBackgroundModifierReconnectsWhenAccessChanges() {
        let blocked = HotkeyConfiguration(label: "Правый ⌘", trusted: false, suspended: false)
        let granted = HotkeyConfiguration(label: "Правый ⌘", trusted: true, suspended: false)
        XCTAssertTrue(blocked.needsAccessibility)
        XCTAssertFalse(blocked.backgroundAvailable)
        XCTAssertTrue(granted.backgroundAvailable)
        XCTAssertNotEqual(blocked, granted)
        XCTAssertEqual(granted, HotkeyConfiguration(label: "Правый ⌘", trusted: true, suspended: false))
        XCTAssertTrue(HotkeyConfiguration(label: "⌃ ⇧ Space", trusted: false, suspended: false).backgroundAvailable)
        XCTAssertFalse(HotkeyConfiguration(label: "Правый ⌘", trusted: true, suspended: true).backgroundAvailable)
        XCTAssertFalse(HotkeyConfiguration(label: "Не указано", trusted: true, suspended: false).backgroundAvailable)
    }
    func testRepeatSuppressionAndRelease() {
        var edge = HotkeyEdge()
        XCTAssertTrue(edge.down())
        XCTAssertFalse(edge.down())
        XCTAssertFalse(edge.down())
        XCTAssertTrue(edge.up())
        XCTAssertFalse(edge.up())
        XCTAssertTrue(edge.down())
    }
    func testPasteRequiresSameTrustedSafeTarget() {
        XCTAssertTrue(PasteService.matches(originalPID: 10, currentPID: 10, sameElement: true, safe: true, trusted: true))
        XCTAssertFalse(PasteService.matches(originalPID: 10, currentPID: 11, sameElement: true, safe: true, trusted: true))
        XCTAssertFalse(PasteService.matches(originalPID: 10, currentPID: nil, sameElement: true, safe: true, trusted: true))
        XCTAssertFalse(PasteService.matches(originalPID: 10, currentPID: 10, sameElement: false, safe: true, trusted: true))
        XCTAssertFalse(PasteService.matches(originalPID: 10, currentPID: 10, sameElement: true, safe: false, trusted: true))
        XCTAssertFalse(PasteService.matches(originalPID: 10, currentPID: 10, sameElement: true, safe: true, trusted: false))
    }
}
