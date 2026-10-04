import Foundation

@main struct PreviewStateChecks {
    @MainActor static func main() async {
        let model = AppModel()
        model.start()
        precondition(!model.recording, "Missing model must block start")
        model.install()
        try? await Task.sleep(for: .milliseconds(600))
        precondition(model.installing && model.progress > 0)
        model.cancelInstall()
        try? await Task.sleep(for: .milliseconds(200))
        precondition(!model.installing && !model.modelReady && model.progress == 0)
        model.modelReady = true
        model.historyEnabled = true
        model.start()
        model.start()
        precondition(model.recording && !model.processing)
        model.removeModel()
        precondition(model.modelReady, "Busy model must not be removed")
        model.stop()
        precondition(model.processing && !model.recording)
        model.start()
        precondition(model.processing && !model.recording)
        model.cancel()
        try? await Task.sleep(for: .seconds(4.2))
        precondition(!model.busy && model.result.isEmpty && model.history.isEmpty, "Cancelled result must not arrive")
        model.start()
        model.stop()
        try? await Task.sleep(for: .seconds(4.2))
        precondition(!model.busy && !model.result.isEmpty && model.history.count == 1)
        model.historyEnabled = false
        model.start()
        model.cancel()
        precondition(!model.busy && model.history.count == 1)
        model.removeModel()
        precondition(!model.modelReady)
        print("Preview state checks: PASS (missing model, install cancel, busy guard, late-result cancel, result/history, remove)")
    }
}
