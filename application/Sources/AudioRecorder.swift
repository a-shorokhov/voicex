import AVFoundation
import Foundation

final class AudioRecorder {
    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var samples: [Float] = []
    private var levels = Array(repeating: Float(0), count: 28)
    private var failed = false
    private var tapped = false
    static let maximumSamples = RecordingPolicy.maximumSamples
    func start() throws {
        let input = engine.inputNode
        let source = input.outputFormat(forBus: 0)
        guard source.sampleRate > 0, source.channelCount > 0,
              let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: source, to: target) else { throw RuntimeError("Микрофон недоступен") }
        lock.lock(); samples.removeAll(keepingCapacity: false); levels = Array(repeating: 0, count: 28); failed = false; lock.unlock()
        input.installTap(onBus: 0, bufferSize: 1024, format: source) { [weak self] buffer, _ in
            guard let self else { return }
            let capacity = AVAudioFrameCount(ceil(Double(buffer.frameLength) * 16000 / source.sampleRate) + 32)
            guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return }
            var supplied = false
            var error: NSError?
            let status = converter.convert(to: output, error: &error) { _, state in
                if supplied { state.pointee = .noDataNow; return nil }
                supplied = true; state.pointee = .haveData; return buffer
            }
            self.lock.lock(); defer { self.lock.unlock() }
            guard error == nil, status != .error, let values = output.floatChannelData?[0] else { self.failed = true; return }
            let count = min(Int(output.frameLength), Self.maximumSamples - self.samples.count)
            for i in 0..<count { self.samples.append(values[i].isFinite ? values[i] : 0) }
            self.levels = MicrophoneWaveform.levels(UnsafeBufferPointer(start: values, count: count))
        }
        tapped = true
        do { engine.prepare(); try engine.start() } catch { _ = stop(); throw error }
    }
    func snapshot() -> (seconds: Double, levels: [Float], failed: Bool) {
        lock.lock(); defer { lock.unlock() }
        return (Double(samples.count) / 16000, levels, failed)
    }
    func stop() -> [Float] {
        engine.stop()
        if tapped { engine.inputNode.removeTap(onBus: 0); tapped = false }
        lock.lock(); defer { lock.unlock() }
        let result = samples; samples = []; levels = Array(repeating: 0, count: 28)
        return result
    }
}
