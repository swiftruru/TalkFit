import Foundation
import Observation

@MainActor
@Observable
final class TalkFitModel {
    var stage: PracticeStage = .home
    var elapsed: TimeInterval = 0
    var audioLevel: Float = 0.08
    var liveTranscript = ""
    var liveFillerEvidence: [FillerEvidence] = []
    var liveSentencePaces: [SentencePaceFeedback] = []
    var firstResult: PracticeResult?
    var comparison: ComparisonResult?
    var fallbackNotice: String?
    var isDemoMode = false
    var selectedLanguage: PracticeLanguage = .traditionalChinese
    private(set) var fillerWordsByLanguage = Dictionary(
        uniqueKeysWithValues: PracticeLanguage.allCases.map { language in
            (language, language.defaultFillerWords)
        }
    )

    var activeFillerWords: [String] {
        fillerWordsByLanguage[selectedLanguage] ?? selectedLanguage.defaultFillerWords
    }

    @ObservationIgnored private let speech = AudioSpeechService()
    @ObservationIgnored private var clockTask: Task<Void, Never>?
    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var analysisPaused = false

    init() {
        speech.levelDidChange = { [weak self] level in self?.audioLevel = level }
        speech.captureDidChange = { [weak self] capture in
            guard let self else { return }
            self.liveTranscript = capture.readableTranscript
            self.liveFillerEvidence = capture.fillerEvidence
            self.liveSentencePaces = TalkFitAnalyzer.sentencePaceFeedback(
                capture: capture,
                duration: max(self.elapsed, 1),
                language: self.selectedLanguage
            )
        }
        speech.prewarmFillerLanguageModel(
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
    }

    func selectLanguage(_ language: PracticeLanguage) {
        guard stage == .home else { return }
        selectedLanguage = language
        speech.prewarmFillerLanguageModel(
            language: language,
            fillerWords: activeFillerWords
        )
    }

    @discardableResult
    func addFillerWord(_ value: String) -> Bool {
        let normalized = selectedLanguage.normalizeFiller(value)
        guard !normalized.isEmpty, activeFillerWords.count < 40 else { return false }
        guard !activeFillerWords.contains(where: {
            selectedLanguage.normalizeFiller($0) == normalized
        }) else { return false }
        fillerWordsByLanguage[selectedLanguage, default: []].append(normalized)
        speech.prewarmFillerLanguageModel(
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
        return true
    }

    func removeFillerWord(_ word: String) {
        fillerWordsByLanguage[selectedLanguage, default: []].removeAll { $0 == word }
        speech.prewarmFillerLanguageModel(
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
    }

    func startPractice(demo: Bool = false) {
        beginRecording(round: .first, demo: demo)
    }

    func startRetry() {
        beginRecording(round: .retry, demo: isDemoMode || firstResult?.source == .sample)
    }

    func stopRecording() {
        guard case .recording(let round) = stage else { return }
        clockTask?.cancel()
        let capturedDuration = max(elapsed, 1)
        stage = .analyzing(round)
        analysisPaused = false

        analysisTask?.cancel()
        analysisTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let capture = self.isDemoMode
                ? TalkFitFixtures.sampleCapture(
                    for: round,
                    language: self.selectedLanguage,
                    fillerWords: self.activeFillerWords
                )
                : await self.speech.finish()
            guard !Task.isCancelled else { return }
            self.liveTranscript = capture.readableTranscript
            self.liveFillerEvidence = capture.fillerEvidence
            self.liveSentencePaces = TalkFitAnalyzer.sentencePaceFeedback(
                capture: capture,
                duration: capturedDuration,
                language: self.selectedLanguage
            )
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            while self.analysisPaused {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
            }
            switch round {
            case .first:
                let result = TalkFitAnalyzer.makeResult(
                    capture: capture,
                    duration: capturedDuration,
                    round: .first,
                    language: self.selectedLanguage,
                    fillerWords: self.activeFillerWords
                )
                self.firstResult = result
                self.isDemoMode = result.source == .sample
                self.stage = .report
            case .retry:
                guard let before = self.firstResult else {
                    self.stage = .home
                    return
                }
                let after = TalkFitAnalyzer.makeResult(
                    capture: capture,
                    duration: capturedDuration,
                    round: .retry,
                    language: self.selectedLanguage,
                    fillerWords: self.activeFillerWords
                )
                self.comparison = ComparisonResult(before: before, after: after)
                self.stage = .comparison
            }
        }
    }

    func choosePrioritySegment() {
        guard firstResult != nil else { return }
        stage = .retry
    }

    func setAnalysisPaused(_ paused: Bool) {
        analysisPaused = paused
    }

    func returnToReport() {
        guard firstResult != nil else {
            returnHome()
            return
        }
        cancelTransientWork()
        comparison = nil
        stage = .report
    }

    func cancelRetryAndReturnToPreparation() {
        guard firstResult != nil else {
            returnHome()
            return
        }
        cancelTransientWork()
        comparison = nil
        stage = .retry
    }

    func returnHome() {
        cancelTransientWork()
        elapsed = 0
        audioLevel = 0.08
        liveTranscript = ""
        liveFillerEvidence = []
        liveSentencePaces = []
        firstResult = nil
        comparison = nil
        fallbackNotice = nil
        isDemoMode = false
        stage = .home
    }

    private func cancelTransientWork() {
        clockTask?.cancel()
        clockTask = nil
        analysisTask?.cancel()
        analysisTask = nil
        analysisPaused = false
        speech.cancel()
        elapsed = 0
        audioLevel = 0.08
        liveTranscript = ""
        liveFillerEvidence = []
        liveSentencePaces = []
        fallbackNotice = nil
    }

    private func beginRecording(round: PracticeRound, demo: Bool) {
        clockTask?.cancel()
        speech.cancel()
        elapsed = 0
        audioLevel = 0.08
        liveTranscript = ""
        liveFillerEvidence = []
        liveSentencePaces = []
        fallbackNotice = demo ? "示範模式：會使用預先準備的穩定結果" : nil
        isDemoMode = demo
        stage = .recording(round)
        startClock(synthetic: demo)

        guard !demo else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.speech.start(
                    language: self.selectedLanguage,
                    fillerWords: self.activeFillerWords
                )
            } catch {
                self.isDemoMode = true
                self.fallbackNotice = "目前無法使用語音辨識，已切換為示範結果"
                self.startClock(synthetic: true)
            }
        }
    }

    private func startClock(synthetic: Bool) {
        clockTask?.cancel()
        let start = ContinuousClock.now
        clockTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.elapsed = start.duration(to: .now).timeInterval
                if synthetic {
                    let wave = (sin(self.elapsed * 4.2) + sin(self.elapsed * 8.7) * 0.45 + 1.5) / 3
                    self.audioLevel = Float(max(0.08, min(0.86, wave)))
                    self.updateDemoRecognitionPreview()
                }
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    private func updateDemoRecognitionPreview() {
        guard case .recording(let round) = stage else { return }
        let capture = TalkFitFixtures.sampleCapture(
            for: round,
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
        let visibleCharacters = min(capture.readableTranscript.count, max(0, Int(elapsed * 5)))
        liveTranscript = String(capture.readableTranscript.prefix(visibleCharacters))
        liveFillerEvidence = capture.fillerEvidence.filter { $0.timestamp <= elapsed }
        var liveCapture = SpeechCapture.empty
        liveCapture.readableTranscript = liveTranscript
        liveSentencePaces = TalkFitAnalyzer.sentencePaceFeedback(
            capture: liveCapture,
            duration: max(elapsed, 1),
            language: selectedLanguage
        )
    }

}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = self.components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
