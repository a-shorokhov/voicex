import Foundation
import WhisperKit

// Optional integration check: installed model + explicitly supplied SYNTHETIC audio.
// Never use personal recordings, and never print a transcript.
@main struct ModelChecks {
    static func main() async throws {
        let service = SpeechService()
        let start = Date()
        guard try await service.loadInstalled() else { throw RuntimeError("Install the model through Voicex first") }
        print("Strict local model load passed in \(String(format: "%.2f", Date().timeIntervalSince(start))) s")
        let args = CommandLine.arguments
        guard args.count == 4 else { return }
        let samples = try AudioProcessor.loadAudioAsFloatArray(fromPath: args[1])
        let began = Date()
        let text = try await service.transcribe(samples, language: args[2] == "auto" ? nil : args[2])
        guard text.lowercased().contains(args[3].lowercased()) else { throw RuntimeError("Synthetic reference phrase did not match; transcript intentionally omitted") }
        print("Synthetic \(args[2]) recognition passed: audio \(String(format: "%.2f", Double(samples.count)/16000)) s; compute \(String(format: "%.2f", Date().timeIntervalSince(began))) s")
    }
}
