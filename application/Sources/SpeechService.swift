import Foundation
import WhisperKit

// The SDK's local-tokenizer helper can fall back to a download. This adapter uses
// the strictly local factory instead, so a broken installation fails offline.
struct LocalTokenizer: WhisperTokenizer {
    let tokenizer: TokenizerWrapper
    let specialTokens: SpecialTokens
    let allLanguageTokens: Set<Int>
    init(folder: URL) async throws {
        let loaded = try await AutoTokenizerWrapper.from(modelFolder: folder)
        tokenizer = loaded
        func id(_ text: String) throws -> Int {
            guard let value = loaded.convertTokenToId(text) else { throw RuntimeError("Повреждён токенизатор. Переустановите модель.") }
            return value
        }
        specialTokens = try SpecialTokens(endToken: id("<|endoftext|>"), englishToken: id("<|en|>"), noSpeechToken: id("<|nospeech|>"), noTimestampsToken: id("<|notimestamps|>"), specialTokenBegin: id("<|endoftext|>"), startOfPreviousToken: id("<|startofprev|>"), startOfTranscriptToken: id("<|startoftranscript|>"), timeTokenBegin: id("<|0.00|>"), transcribeToken: id("<|transcribe|>"), translateToken: id("<|translate|>"), whitespaceToken: loaded.encode(text: " ").first ?? 220)
        allLanguageTokens = Set(Constants.languages.values.compactMap { loaded.convertTokenToId("<|\($0)|>") })
    }
    func encode(text: String) -> [Int] { tokenizer.encode(text: text) }
    func decode(tokens: [Int]) -> String { tokenizer.decode(tokens: tokens) }
    func convertTokenToId(_ token: String) -> Int? { tokenizer.convertTokenToId(token) }
    func convertIdToToken(_ id: Int) -> String? { tokenizer.convertIdToToken(id) }
    func splitToWordTokens(tokenIds: [Int]) -> (words: [String], wordTokens: [[Int]]) {
        // Word timestamps are disabled; retain complete Unicode text if called.
        ([decode(tokens: tokenIds)], [tokenIds])
    }
}
struct RuntimeError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
actor SpeechService {
    static let variant = "large-v3-v20240930_626MB"
    static var root: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Voicex", isDirectory: true) }
    private var engine: WhisperKit?
    private var operating = false
    private var marker: URL { Self.root.appendingPathComponent("installation.json") }
    private struct Installation: Codable { let model: String; let tokenizer: String }
    func loadInstalled() async throws -> Bool {
        guard FileManager.default.fileExists(atPath: marker.path) else { return false }
        guard !operating else { throw RuntimeError("Модель занята") }
        operating = true; defer { operating = false }
        let paths = try JSONDecoder().decode(Installation.self, from: Data(contentsOf: marker))
        try await load(model: Self.root.appendingPathComponent(paths.model), tokenizer: Self.root.appendingPathComponent(paths.tokenizer))
        return true
    }
    private func load(model: URL, tokenizer: URL) async throws {
        Logging.updateLogLevel(.none)
        let localTokenizer = try await LocalTokenizer(folder: tokenizer)
        let kit = try await WhisperKit(WhisperKitConfig(modelFolder: model.path, tokenizerFolder: tokenizer, verbose: false, prewarm: false, load: false, download: false))
        kit.tokenizer = localTokenizer
        try Task.checkCancellation()
        try await kit.prewarmModels()
        try Task.checkCancellation()
        try await kit.loadModels()
        try Task.checkCancellation()
        engine = kit
    }
    func install(progress: @escaping @Sendable (Double, Bool) -> Void) async throws {
        guard !operating else { throw RuntimeError("Модель занята") }
        operating = true; defer { operating = false }
        Logging.updateLogLevel(.none)
        try FileManager.default.createDirectory(at: Self.root, withIntermediateDirectories: true)
        let model = try await WhisperKit.download(variant: Self.variant, downloadBase: Self.root, from: "argmaxinc/whisperkit-coreml", progressCallback: { progress($0.fractionCompleted * 0.92, false) })
        try Task.checkCancellation()
        let hub = HubApiWrapper(downloadBase: Self.root)
        let tokenizer = try await hub.snapshot(from: .init(id: "openai/whisper-large-v3"), matching: ["tokenizer.json", "tokenizer_config.json", "config.json", "special_tokens_map.json", "added_tokens.json"], progressHandler: { progress(0.92 + $0.fractionCompleted * 0.08, false) })
        try Task.checkCancellation()
        progress(1, true)
        try await load(model: model, tokenizer: tokenizer)
        let installation = Installation(model: String(model.path.dropFirst(Self.root.path.count + 1)), tokenizer: String(tokenizer.path.dropFirst(Self.root.path.count + 1)))
        try JSONEncoder().encode(installation).write(to: marker, options: .atomic)
    }
    func remove() async throws {
        guard !operating else { throw RuntimeError("Модель занята") }
        operating = true; defer { operating = false }
        await engine?.unloadModels(); engine = nil
        if FileManager.default.fileExists(atPath: Self.root.path) { try FileManager.default.removeItem(at: Self.root) }
    }
    func transcribe(_ samples: [Float], language: String?) async throws -> String {
        guard !operating, let engine else { throw RuntimeError("Модель не готова") }
        operating = true; defer { operating = false }
        let options = DecodingOptions(task: .transcribe, language: language, detectLanguage: language == nil, skipSpecialTokens: true, withoutTimestamps: true, concurrentWorkerCount: 1)
        let results = try await engine.transcribe(audioArray: samples, decodeOptions: options)
        try Task.checkCancellation()
        return results.flatMap(\.segments).filter { $0.noSpeechProb < 0.6 }.map(\.text).joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
