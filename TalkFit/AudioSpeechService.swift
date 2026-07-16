import AVFoundation
import Speech

enum AudioSpeechError: Error {
    case microphoneDenied
    case speechDenied
    case recognizerUnavailable
    case inputUnavailable
}

@MainActor
final class AudioSpeechService {
    private let engine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private(set) var latestTranscript = ""
    var levelDidChange: (Float) -> Void = { _ in }
    var transcriptDidChange: (String) -> Void = { _ in }

    func start() async throws {
        let microphoneAllowed = await requestMicrophonePermission()
        guard microphoneAllowed else { throw AudioSpeechError.microphoneDenied }

        let speechStatus = await requestSpeechPermission()
        guard speechStatus == .authorized else { throw AudioSpeechError.speechDenied }
        guard let recognizer, recognizer.isAvailable else { throw AudioSpeechError.recognizerUnavailable }

        stop()
        latestTranscript = ""

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.taskHint = .dictation
        request.contextualStrings = TalkFitFixtures.fillerWords + [TalkFitFixtures.promptTitle]
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let text = result?.bestTranscription.formattedString, !text.isEmpty {
                Task { @MainActor in
                    self.latestTranscript = text
                    self.transcriptDidChange(text)
                }
            }
            if error != nil {
                Task { @MainActor in self.levelDidChange(0) }
            }
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw AudioSpeechError.inputUnavailable }
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self, request] buffer, _ in
            request.append(buffer)
            guard let channel = buffer.floatChannelData?.pointee else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }
            var sum: Float = 0
            for index in stride(from: 0, to: frameLength, by: 4) {
                sum += channel[index] * channel[index]
            }
            let mean = sum / Float(max(1, frameLength / 4))
            let rms = sqrt(mean)
            let normalized = min(1, max(0.04, rms * 13))
            Task { @MainActor in self?.levelDidChange(normalized) }
        }

        engine.prepare()
        try engine.start()
    }

    @discardableResult
    func stop() -> String {
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionTask = nil
        recognitionRequest = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        levelDidChange(0)
        return latestTranscript
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechPermission() async -> SFSpeechRecognizerAuthorizationStatus {
        if SFSpeechRecognizer.authorizationStatus() != .notDetermined {
            return SFSpeechRecognizer.authorizationStatus()
        }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
