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
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var finishContinuation: CheckedContinuation<SpeechCapture, Never>?
    private var finishTimeoutTask: Task<Void, Never>?
    private var languageModelTask: Task<SFSpeechLanguageModel.Configuration?, Never>?
    private var fillerLanguageModelConfiguration: SFSpeechLanguageModel.Configuration?
    private var languageModelKey: String?
    private var currentLanguage: PracticeLanguage = .traditionalChinese
    private var currentFillerWords = PracticeLanguage.traditionalChinese.defaultFillerWords
    private var tapInstalled = false

    private(set) var latestCapture = SpeechCapture.empty
    var levelDidChange: (Float) -> Void = { _ in }
    var captureDidChange: (SpeechCapture) -> Void = { _ in }

    func prewarmFillerLanguageModel(
        language: PracticeLanguage,
        fillerWords: [String]
    ) {
        let key = language.localeIdentifier + "|" + fillerWords.joined(separator: "|")
        guard languageModelKey != key else { return }
        languageModelTask?.cancel()
        languageModelKey = key
        fillerLanguageModelConfiguration = nil
        let phrases = language.languageModelPhrases(fillerWords: fillerWords)
        let localeIdentifier = language.localeIdentifier
        languageModelTask = Task { [weak self] in
            let configuration = await FillerLanguageModel.prepare(
                localeIdentifier: localeIdentifier,
                phrases: phrases
            )
            guard !Task.isCancelled else { return nil }
            self?.fillerLanguageModelConfiguration = configuration
            return configuration
        }
    }

    func start(
        language: PracticeLanguage,
        context: PracticeContext,
        referenceText: String? = nil,
        fillerWords: [String]
    ) async throws {
        let microphoneAllowed = await requestMicrophonePermission()
        guard microphoneAllowed else { throw AudioSpeechError.microphoneDenied }

        let speechStatus = await requestSpeechPermission()
        guard speechStatus == .authorized else { throw AudioSpeechError.speechDenied }

        cancel()
        currentLanguage = language
        currentFillerWords = fillerWords
        latestCapture = .empty
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.localeIdentifier))
        guard let recognizer, recognizer.isAvailable else {
            throw AudioSpeechError.recognizerUnavailable
        }
        prewarmFillerLanguageModel(language: language, fillerWords: fillerWords)
        let preparedLanguageModel: SFSpeechLanguageModel.Configuration?
        if let fillerLanguageModelConfiguration {
            preparedLanguageModel = fillerLanguageModelConfiguration
        } else {
            preparedLanguageModel = await languageModelTask?.value
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.taskHint = .unspecified
        let baseHints = language.recognitionHints(
            fillerWords: fillerWords,
            context: context
        )
        let scriptHints = referenceText.map {
            ScriptPracticeAnalyzer.recognitionHints(from: $0, language: language)
        } ?? []
        request.contextualStrings = Array((baseHints + scriptHints).prefix(100))
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
            request.customizedLanguageModel = preparedLanguageModel
        }
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.consume(result)
                }
                if error != nil {
                    self.levelDidChange(0)
                    if self.finishContinuation != nil {
                        self.completeFinish()
                    }
                }
            }
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            cancel()
            throw AudioSpeechError.inputUnavailable
        }
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
        tapInstalled = true

        engine.prepare()
        do {
            try engine.start()
        } catch {
            cancel()
            throw error
        }
    }

    func finish() async -> SpeechCapture {
        stopAudioInput()
        guard recognitionTask != nil else {
            deactivateAudioSession()
            return latestCapture
        }

        recognitionRequest?.endAudio()
        return await withCheckedContinuation { continuation in
            finishContinuation = continuation
            finishTimeoutTask?.cancel()
            finishTimeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(850))
                guard !Task.isCancelled else { return }
                self?.completeFinish()
            }
        }
    }

    func cancel() {
        stopAudioInput()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        finishTimeoutTask?.cancel()
        finishTimeoutTask = nil
        if let continuation = finishContinuation {
            finishContinuation = nil
            continuation.resume(returning: latestCapture)
        }
        deactivateAudioSession()
        levelDidChange(0)
    }

    private func consume(_ result: SFSpeechRecognitionResult) {
        let readable = result.bestTranscription.formattedString
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !readable.isEmpty {
            latestCapture.readableTranscript = readable
            retainMostInformativeTranscript(readable)
        }
        latestCapture.segments = result.bestTranscription.segments.map { segment in
            SpeechTextSegment(
                text: segment.substring,
                timestamp: segment.timestamp,
                duration: segment.duration
            )
        }

        for (index, transcription) in result.transcriptions.enumerated() {
            let source: FillerEvidenceSource
            if index == 0 {
                source = result.isFinal ? .final : .partial
            } else {
                source = .alternative
            }
            collectEvidence(from: transcription, source: source)
            retainMostInformativeTranscript(transcription.formattedString)
        }

        latestCapture.fillerEvidence.sort { $0.timestamp < $1.timestamp }
        captureDidChange(latestCapture)

        if result.isFinal, finishContinuation != nil {
            completeFinish()
        }
    }

    private func collectEvidence(from transcription: SFTranscription, source: FillerEvidenceSource) {
        for segment in transcription.segments {
            let primaryWords = fillerOccurrences(in: segment.substring)
            for word in primaryWords {
                upsert(
                    FillerEvidence(
                        word: word,
                        timestamp: segment.timestamp,
                        confidence: segment.confidence,
                        source: source
                    )
                )
            }

            if primaryWords.isEmpty,
               let alternative = segment.alternativeSubstrings.first(where: {
                   !fillerOccurrences(in: $0).isEmpty
               }) {
                for word in fillerOccurrences(in: alternative) {
                    upsert(
                        FillerEvidence(
                            word: word,
                            timestamp: segment.timestamp,
                            confidence: max(0.01, segment.confidence * 0.75),
                            source: .alternative
                        )
                    )
                }
            }
        }
    }

    private func fillerOccurrences(in text: String) -> [String] {
        currentFillerWords.flatMap { word in
            let count = TalkFitAnalyzer.fillerCounts(
                in: text,
                fillerWords: currentFillerWords,
                language: currentLanguage
            )[word] ?? 0
            return Array(repeating: word, count: count)
        }
    }

    private func upsert(_ candidate: FillerEvidence) {
        FillerEvidenceReducer.upsert(candidate, into: &latestCapture.fillerEvidence)
    }

    private func retainMostInformativeTranscript(_ candidate: String) {
        let candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return }
        let currentScore = TalkFitAnalyzer.fillerCounts(
            in: latestCapture.analysisTranscript,
            fillerWords: currentFillerWords,
            language: currentLanguage
        ).values.reduce(0, +)
        let candidateScore = TalkFitAnalyzer.fillerCounts(
            in: candidate,
            fillerWords: currentFillerWords,
            language: currentLanguage
        ).values.reduce(0, +)
        if candidateScore > currentScore
            || (candidateScore == currentScore && candidate.count > latestCapture.analysisTranscript.count) {
            latestCapture.analysisTranscript = candidate
        }
    }

    private func completeFinish() {
        finishTimeoutTask?.cancel()
        finishTimeoutTask = nil
        recognitionTask?.finish()
        recognitionTask = nil
        recognitionRequest = nil
        deactivateAudioSession()
        levelDidChange(0)
        guard let continuation = finishContinuation else { return }
        finishContinuation = nil
        continuation.resume(returning: latestCapture)
    }

    private func stopAudioInput() {
        if engine.isRunning {
            engine.stop()
        }
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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
