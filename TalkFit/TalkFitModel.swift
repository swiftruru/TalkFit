import Foundation
import Observation

private enum PendingHistoryCompletion {
    case result(PracticeResult)
    case comparison(ComparisonResult)
}

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
    var selectedContext: PracticeContext = .selfIntroduction
    var scriptPractice: ScriptPracticeSession?
    /// Which built-in script the recording screen shows for reading aloud.
    var referenceScriptStyle: ReferenceScriptStyle = .clean
    private(set) var retryParagraph: ScriptParagraph?
    var isHistoryChoicePresented = false
    private(set) var historyPreference: HistoryPreference
    private(set) var practiceHistory: [PracticeHistorySummary] = []
    private(set) var recordingSessions: [RecordingArchiveSessionSummary] = []
    private(set) var fillerWordsByLanguage: [PracticeLanguage: [String]]

    var reportRecordingURL: URL? {
        pendingRecordingAttempts.first(where: { $0.kind == .initial })?.temporaryAudioURL
    }

    var comparisonRecordingURL: URL? {
        pendingRecordingAttempts.last(where: { $0.kind != .initial })?.temporaryAudioURL
    }

    var activeFillerWords: [String] {
        fillerWordsByLanguage[selectedLanguage] ?? selectedLanguage.defaultFillerWords
    }

    var activePrompt: String {
        scriptPractice?.fullText
            ?? selectedContext.prompt(for: selectedLanguage)
    }

    var activePromptTitle: String {
        guard let scriptPractice else {
            return selectedContext.promptTitle(for: selectedLanguage)
        }
        return "自訂講稿 · 完整 \(scriptPractice.paragraphs.count) 段"
    }

    /// The built-in script for the current context, in the chosen version.
    var referenceScript: String {
        selectedContext.recordingScript(
            for: selectedLanguage,
            style: referenceScriptStyle
        )
    }

    var usesScriptPractice: Bool {
        scriptPractice != nil
    }

    var retryPrompt: String {
        retryParagraph?.text ?? firstResult?.prioritySegment ?? ""
    }

    var retryCoachingCue: String {
        guard let retryParagraph,
              let feedback = scriptParagraphFeedback.first(where: {
                  $0.paragraph.id == retryParagraph.id
              }) else {
            return firstResult?.coachingCue ?? "先把重點說清楚，不用追求一次完美。"
        }
        return feedback.suggestion
    }

    var scriptParagraphFeedback: [ScriptParagraphFeedback] {
        guard let scriptPractice, let firstResult else { return [] }
        return ScriptPracticeAnalyzer.paragraphFeedback(
            paragraphs: scriptPractice.paragraphs,
            spoken: firstResult.transcript,
            language: firstResult.language
        )
    }

    @ObservationIgnored private let speech = AudioSpeechService()
    @ObservationIgnored private let fillerStore: FillerLibraryStore
    @ObservationIgnored private let historyStore: PracticeHistoryStore?
    @ObservationIgnored private let recordingArchiveStore: RecordingArchiveStore?
    @ObservationIgnored private var clockTask: Task<Void, Never>?
    @ObservationIgnored private var recordingStartTask: Task<Void, Never>?
    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var analysisPaused = false
    @ObservationIgnored private var livePaceEstimator = LivePaceEstimator()
    @ObservationIgnored private var retryBaselineResult: PracticeResult?
    @ObservationIgnored private var pendingHistoryCompletion: PendingHistoryCompletion?
    @ObservationIgnored private var pendingRecordingSessionID: UUID?
    @ObservationIgnored private var pendingRecordingStartedAt: Date?
    @ObservationIgnored private var pendingRecordingAttempts: [RecordingArchiveAttemptDraft] = []

    init(
        historyStore: PracticeHistoryStore? = nil,
        recordingArchiveStore: RecordingArchiveStore? = nil
    ) {
        let fillerStore = FillerLibraryStore()
        self.fillerStore = fillerStore
        self.historyStore = historyStore
        self.recordingArchiveStore = recordingArchiveStore
        historyPreference = historyStore?.preference ?? .undecided
        fillerWordsByLanguage = fillerStore.load()
        speech.levelDidChange = { [weak self] level in self?.audioLevel = level }
        speech.captureDidChange = { [weak self] capture in
            guard let self else { return }
            self.liveTranscript = capture.readableTranscript
            self.liveFillerEvidence = capture.fillerEvidence
            self.updateLivePace(with: capture)
        }
        speech.prewarmFillerLanguageModel(
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
        reloadHistory()
    }

    var isHistoryEnabled: Bool {
        historyPreference == .enabled
    }

    var recentPracticeHistory: [PracticeHistorySummary] {
        Array(practiceHistory.prefix(3))
    }

    var practiceTrends: [PracticeTrend] {
        PracticeTrend.make(from: practiceHistory)
    }

    var trendProgress: PracticeTrendProgress? {
        PracticeTrendProgress.closest(from: practiceHistory)
    }

    var historyFillerSummary: String {
        guard !practiceHistory.isEmpty else { return "累積中" }
        let improvement = practiceHistory.reduce(0) { $0 + $1.fillerImprovement }
        return improvement > 0 ? "−\(improvement)" : "持平"
    }

    var historyStabilitySummary: String {
        guard !practiceHistory.isEmpty else { return "等資料" }
        let improvement = practiceHistory.reduce(0) { $0 + $1.stabilityImprovement }
        return improvement > 0 ? "+\(improvement)%" : "持平"
    }

    func selectLanguage(_ language: PracticeLanguage) {
        guard stage == .home else { return }
        selectedLanguage = language
        speech.prewarmFillerLanguageModel(
            language: language,
            fillerWords: activeFillerWords
        )
    }

    func selectContext(_ context: PracticeContext) {
        guard stage == .home else { return }
        selectedContext = context
    }

    @discardableResult
    func configureScriptPractice(text: String) -> Bool {
        guard stage == .home,
              let session = ScriptPracticeSession.make(text: text) else {
            return false
        }
        scriptPractice = session
        return true
    }

    func clearScriptPractice() {
        guard stage == .home else { return }
        scriptPractice = nil
    }

    @discardableResult
    func addFillerWord(_ value: String) -> Bool {
        let normalized = selectedLanguage.normalizeFiller(value)
        guard !normalized.isEmpty, activeFillerWords.count < 40 else { return false }
        guard !activeFillerWords.contains(where: {
            selectedLanguage.normalizeFiller($0) == normalized
        }) else { return false }
        fillerWordsByLanguage[selectedLanguage, default: []].append(normalized)
        fillerStore.save(fillerWordsByLanguage)
        speech.prewarmFillerLanguageModel(
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
        return true
    }

    func removeFillerWord(_ word: String) {
        fillerWordsByLanguage[selectedLanguage, default: []].removeAll { $0 == word }
        fillerStore.save(fillerWordsByLanguage)
        speech.prewarmFillerLanguageModel(
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
    }

    func resetFillerWords(for language: PracticeLanguage) {
        fillerWordsByLanguage[language] = language.defaultFillerWords
        fillerStore.save(fillerWordsByLanguage)
        guard language == selectedLanguage else { return }
        speech.prewarmFillerLanguageModel(
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
    }

    func resetAllFillerWords() {
        fillerWordsByLanguage = Dictionary(
            uniqueKeysWithValues: PracticeLanguage.allCases.map { language in
                (language, language.defaultFillerWords)
            }
        )
        fillerStore.resetAll()
        speech.prewarmFillerLanguageModel(
            language: selectedLanguage,
            fillerWords: activeFillerWords
        )
    }

    func startPractice(demo: Bool = false) {
        discardPendingRecordings()
        pendingRecordingSessionID = UUID()
        pendingRecordingStartedAt = .now
        beginRecording(round: .first, demo: demo)
    }

    func startRetry() {
        beginRecording(round: .retry, demo: isDemoMode || firstResult?.source == .sample)
    }

    func stopRecording() {
        guard case .recording(let round) = stage else { return }
        clockTask?.cancel()
        recordingStartTask?.cancel()
        recordingStartTask = nil
        let capturedDuration = max(elapsed, 1)
        stage = .analyzing(round)
        analysisPaused = false

        analysisTask?.cancel()
        analysisTask = Task { @MainActor [weak self] in
            guard let self else { return }
            var unclaimedRecordingURL: URL?
            defer {
                if let unclaimedRecordingURL {
                    try? FileManager.default.removeItem(at: unclaimedRecordingURL)
                }
            }
            let rawCapture = self.isDemoMode
                ? self.fallbackCapture(for: round)
                : await self.speech.finish()
            unclaimedRecordingURL = rawCapture.recordedFileURL
            guard !Task.isCancelled else { return }
            let capture = rawCapture.preservingBestTranscript
            guard capture.source == .sample || capture.hasReadableTranscript else {
                self.isDemoMode = false
                self.fallbackNotice = nil
                self.stage = .recognitionIssue(round, .noTranscript)
                return
            }
            self.liveTranscript = capture.readableTranscript
            self.liveFillerEvidence = capture.fillerEvidence
            self.liveSentencePaces = TalkFitAnalyzer.sentencePaceFeedback(
                capture: capture,
                duration: capturedDuration,
                language: self.selectedLanguage,
                context: self.selectedContext
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
                    context: self.selectedContext,
                    scriptReference: self.scriptReference(for: .first),
                    fillerWords: self.activeFillerWords
                )
                if self.retainRecording(
                    at: rawCapture.recordedFileURL,
                    for: result,
                    round: round
                ) {
                    unclaimedRecordingURL = nil
                }
                self.firstResult = result
                self.isDemoMode = result.source == .sample
                self.stage = .report
            case .retry:
                guard let before = self.retryBaselineResult ?? self.firstResult else {
                    self.stage = .home
                    return
                }
                let after = TalkFitAnalyzer.makeResult(
                    capture: capture,
                    duration: capturedDuration,
                    round: .retry,
                    language: self.selectedLanguage,
                    context: self.selectedContext,
                    scriptReference: self.scriptReference(for: .retry),
                    fillerWords: self.activeFillerWords
                )
                if self.retainRecording(
                    at: rawCapture.recordedFileURL,
                    for: after,
                    round: round
                ) {
                    unclaimedRecordingURL = nil
                }
                self.comparison = ComparisonResult(before: before, after: after)
                self.stage = .comparison
            }
        }
    }

    func choosePrioritySegment() {
        guard let firstResult else { return }
        retryParagraph = nil
        retryBaselineResult = shortPracticeBaseline(original: firstResult)
        comparison = nil
        stage = .retry
    }

    func chooseScriptParagraph(_ paragraph: ScriptParagraph) {
        guard let firstResult,
              let feedback = scriptParagraphFeedback.first(where: {
                  $0.paragraph.id == paragraph.id
              }) else { return }
        retryParagraph = paragraph
        retryBaselineResult = paragraphBaseline(
            feedback: feedback,
            original: firstResult
        )
        comparison = nil
        stage = .retry
    }

    func retryComparisonSegment() {
        guard let comparison else { return }
        retryBaselineResult = comparison.after
        self.comparison = nil
        stage = .retry
    }

    func retryAfterRecognitionIssue(round: PracticeRound) {
        beginRecording(round: round, demo: false)
    }

    func useDemoAfterRecognitionIssue(round: PracticeRound) {
        beginRecording(round: round, demo: true)
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
        retryParagraph = nil
        retryBaselineResult = nil
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
        discardPendingRecordings()
        elapsed = 0
        audioLevel = 0.08
        liveTranscript = ""
        liveFillerEvidence = []
        liveSentencePaces = []
        firstResult = nil
        comparison = nil
        retryParagraph = nil
        retryBaselineResult = nil
        pendingHistoryCompletion = nil
        fallbackNotice = nil
        isDemoMode = false
        isHistoryChoicePresented = false
        reloadHistory()
        stage = .home
    }

    func acceptResult() {
        guard let firstResult else {
            returnHome()
            return
        }
        finishPractice(.result(firstResult))
    }

    func acceptComparison() {
        guard let comparison else {
            returnHome()
            return
        }
        finishPractice(.comparison(comparison))
    }

    func enableHistoryAndSave() {
        setHistoryEnabled(true)
        savePendingHistoryCompletion()
        returnHome()
    }

    func declineHistoryAndFinish() {
        setHistoryEnabled(false)
        returnHome()
    }

    func setHistoryEnabled(_ enabled: Bool) {
        historyPreference = enabled ? .enabled : .disabled
        historyStore?.setPreference(historyPreference)
        reloadHistory()
    }

    func deleteHistory(id: UUID) {
        historyStore?.delete(id: id)
        reloadHistory()
    }

    func deleteAllHistory() {
        historyStore?.deleteAll()
        reloadHistory()
    }

    func deleteRecordingSession(id: UUID) {
        try? recordingArchiveStore?.deleteSession(id: id)
        reloadHistory()
    }

    func reloadHistory() {
        practiceHistory = historyStore?.fetchAll() ?? []
        recordingSessions = recordingArchiveStore?.fetchAll() ?? []
    }

    private func cancelTransientWork() {
        clockTask?.cancel()
        clockTask = nil
        recordingStartTask?.cancel()
        recordingStartTask = nil
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
        recordingStartTask?.cancel()
        recordingStartTask = nil
        speech.cancel()
        elapsed = 0
        audioLevel = 0.08
        liveTranscript = ""
        liveFillerEvidence = []
        liveSentencePaces = []
        livePaceEstimator.reset()
        fallbackNotice = demo ? "示範模式：會使用預先準備的穩定結果" : nil
        isDemoMode = demo
        stage = .recording(round)
        startClock(synthetic: demo)

        guard !demo else { return }
        recordingStartTask = Task { @MainActor [weak self] in
            guard let self else { return }
            guard !Task.isCancelled else { return }
            do {
                try await self.speech.start(
                    language: self.selectedLanguage,
                    context: self.selectedContext,
                    referenceText: self.recordingPrompt(for: round),
                    fillerWords: self.activeFillerWords
                )
                guard !Task.isCancelled else {
                    self.speech.cancel()
                    return
                }
            } catch {
                guard !Task.isCancelled else { return }
                guard case .recording(let activeRound) = self.stage,
                      activeRound == round else { return }
                self.clockTask?.cancel()
                self.clockTask = nil
                self.speech.cancel()
                self.isDemoMode = false
                self.fallbackNotice = nil
                self.stage = .recognitionIssue(round, .serviceUnavailable)
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

    /// Updates the pace shown while recording.
    ///
    /// Partial results usually have no usable word timings, so the pace then
    /// comes from how fast the transcript has been growing on the clock. The
    /// previous reading stays on screen until there is enough new speech.
    private func updateLivePace(with capture: SpeechCapture) {
        let language = selectedLanguage
        let context = selectedContext
        let recentPace = livePaceEstimator.record(
            time: elapsed,
            units: language.speechUnitCount(in: capture.readableTranscript)
        )
        if TranscriptSentenceSegmenter.hasReliableTiming(capture: capture, language: language) {
            liveSentencePaces = TalkFitAnalyzer.sentencePaceFeedback(
                capture: capture,
                duration: max(elapsed, 1),
                language: language,
                context: context
            )
            return
        }
        guard let recentPace else { return }
        let latestSentence = TalkFitAnalyzer.sentenceTexts(
            in: capture.readableTranscript,
            language: language
        ).last ?? capture.readableTranscript
        liveSentencePaces = [
            SentencePaceFeedback(
                text: latestSentence,
                pace: recentPace,
                state: context.livePaceState(for: recentPace, language: language),
                context: context
            )
        ]
    }

    private func updateDemoRecognitionPreview() {
        guard case .recording(let round) = stage else { return }
        let capture = fallbackCapture(for: round)
        let visibleCharacters = min(capture.readableTranscript.count, max(0, Int(elapsed * 5)))
        liveTranscript = String(capture.readableTranscript.prefix(visibleCharacters))
        liveFillerEvidence = capture.fillerEvidence.filter { $0.timestamp <= elapsed }
        var liveCapture = SpeechCapture.empty
        liveCapture.readableTranscript = liveTranscript
        liveSentencePaces = TalkFitAnalyzer.sentencePaceFeedback(
            capture: liveCapture,
            duration: max(elapsed, 1),
            language: selectedLanguage,
            context: selectedContext
        )
    }

    private func recordingPrompt(for round: PracticeRound) -> String {
        if round == .retry {
            return retryPrompt
        }
        return activePrompt
    }

    private func scriptReference(for round: PracticeRound) -> ScriptPracticeReference? {
        guard let scriptPractice else {
            return nil
        }
        if round == .retry, let retryParagraph {
            return ScriptPracticeReference(
                text: retryParagraph.text,
                paragraphNumber: retryParagraph.number,
                paragraphCount: scriptPractice.paragraphs.count
            )
        }
        return ScriptPracticeReference(
            text: scriptPractice.fullText,
            paragraphCount: scriptPractice.paragraphs.count
        )
    }

    private func fallbackCapture(for round: PracticeRound) -> SpeechCapture {
        if let scriptReference = scriptReference(for: round) {
            return TalkFitFixtures.scriptCapture(
                for: round,
                language: selectedLanguage,
                script: scriptReference.text,
                fillerWords: activeFillerWords
            )
        }
        if round == .retry {
            return TalkFitFixtures.sampleCapture(
                for: .retry,
                language: selectedLanguage,
                context: selectedContext,
                fillerWords: activeFillerWords
            )
        }
        return TalkFitFixtures.sampleCapture(
            for: round,
            language: selectedLanguage,
            context: selectedContext,
            fillerWords: activeFillerWords
        )
    }

    private func shortPracticeBaseline(original: PracticeResult) -> PracticeResult {
        let segment = original.prioritySegment
        let totalUnits = max(1, original.language.speechUnitCount(in: original.transcript))
        let segmentUnits = max(1, original.language.speechUnitCount(in: segment))
        let proportionalDuration = max(
            4,
            original.duration * Double(segmentUnits) / Double(totalUnits)
        )
        let capture = SpeechCapture(
            readableTranscript: segment,
            analysisTranscript: segment,
            fillerEvidence: [],
            segments: [],
            source: original.source
        )
        return TalkFitAnalyzer.makeResult(
            capture: capture,
            duration: proportionalDuration,
            round: .first,
            language: original.language,
            context: original.context,
            fillerWords: original.fillerWords
        )
    }

    private func paragraphBaseline(
        feedback: ScriptParagraphFeedback,
        original: PracticeResult
    ) -> PracticeResult {
        let excerpt = feedback.spokenExcerpt.isEmpty
            ? feedback.paragraph.text
            : feedback.spokenExcerpt
        let totalUnits = max(1, original.language.speechUnitCount(in: original.transcript))
        let excerptUnits = max(1, original.language.speechUnitCount(in: excerpt))
        let proportionalDuration = max(
            4,
            original.duration * Double(excerptUnits) / Double(totalUnits)
        )
        let capture = SpeechCapture(
            readableTranscript: excerpt,
            analysisTranscript: excerpt,
            // Full-recording timestamps cannot be assigned to a paragraph
            // reliably, so the scoped baseline uses only its visible words.
            fillerEvidence: [],
            segments: [],
            source: original.source
        )
        return TalkFitAnalyzer.makeResult(
            capture: capture,
            duration: proportionalDuration,
            round: .first,
            language: original.language,
            context: original.context,
            scriptReference: ScriptPracticeReference(
                text: feedback.paragraph.text,
                paragraphNumber: feedback.paragraph.number,
                paragraphCount: scriptPractice?.paragraphs.count ?? 1
            ),
            fillerWords: original.fillerWords
        )
    }

    private func finishPractice(_ completion: PendingHistoryCompletion) {
        let isRealPractice: Bool
        switch completion {
        case .result(let result):
            isRealPractice = result.source == .recognized
        case .comparison(let comparison):
            isRealPractice = comparison.before.source == .recognized
                && comparison.after.source == .recognized
        }
        guard isRealPractice else {
            returnHome()
            return
        }

        pendingHistoryCompletion = completion
        if historyPreference == .undecided, historyStore != nil {
            isHistoryChoicePresented = true
            return
        }
        if historyPreference == .enabled {
            savePendingHistoryCompletion()
        }
        returnHome()
    }

    private func savePendingHistoryCompletion() {
        switch pendingHistoryCompletion {
        case .result(let result):
            historyStore?.save(result)
        case .comparison(let comparison):
            historyStore?.save(comparison)
        case nil:
            break
        }
        savePendingRecordingSession()
        pendingHistoryCompletion = nil
    }

    @discardableResult
    private func retainRecording(
        at url: URL?,
        for result: PracticeResult,
        round: PracticeRound
    ) -> Bool {
        guard result.source == .recognized, let url else { return false }
        let kind: RecordingArchiveAttemptKind
        let paragraphNumber: Int?
        switch round {
        case .first:
            kind = .initial
            paragraphNumber = nil
        case .retry:
            if scriptPractice != nil, let retryParagraph {
                kind = .segmentRetry
                paragraphNumber = retryParagraph.number
            } else {
                kind = .fullRetry
                paragraphNumber = nil
            }
        }
        pendingRecordingAttempts.append(
            RecordingArchiveAttemptDraft(
                kind: kind,
                paragraphNumber: paragraphNumber,
                temporaryAudioURL: url,
                duration: result.duration,
                fillerCount: result.fillerTotal,
                pace: result.pace,
                stability: result.stability,
                transcript: result.transcript,
                transcriptSegments: result.transcriptSegments,
                source: result.source
            )
        )
        return true
    }

    private func savePendingRecordingSession() {
        guard let recordingArchiveStore,
              let firstResult,
              let sessionID = pendingRecordingSessionID,
              !pendingRecordingAttempts.isEmpty else {
            return
        }
        let kind: RecordingArchiveSessionKind = scriptPractice == nil
            ? .shortPractice
            : .scriptPractice
        let title = scriptPractice == nil
            ? firstResult.historyPromptTitle
            : "自訂講稿"
        let draft = RecordingArchiveSessionDraft(
            id: sessionID,
            createdAt: pendingRecordingStartedAt ?? .now,
            kind: kind,
            title: title,
            language: firstResult.language,
            context: firstResult.context,
            paragraphCount: scriptPractice?.paragraphs.count,
            attempts: pendingRecordingAttempts
        )
        _ = try? recordingArchiveStore.importSession(draft)
        recordingSessions = recordingArchiveStore.fetchAll()
    }

    private func discardPendingRecordings() {
        pendingRecordingAttempts.forEach { attempt in
            try? FileManager.default.removeItem(at: attempt.temporaryAudioURL)
        }
        pendingRecordingAttempts = []
        pendingRecordingSessionID = nil
        pendingRecordingStartedAt = nil
    }

#if DEBUG
    func loadRecordingArchiveQAFixtures(now: Date = .now) {
        let unavailableURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("talkfit-qa-recording.caf")
        func attempt(
            sequence: Int,
            kind: RecordingArchiveAttemptKind,
            paragraphNumber: Int? = nil,
            duration: TimeInterval,
            fillerCount: Int,
            pace: Int,
            stability: Int,
            transcript: String = "我曾帶領三人團隊改善選課流程，重新整理資訊後，完成時間縮短兩分鐘。"
        ) -> RecordingArchiveAttemptSummary {
            RecordingArchiveAttemptSummary(
                id: UUID(),
                capturedAt: now.addingTimeInterval(TimeInterval(sequence * 40)),
                sequence: sequence,
                kind: kind,
                paragraphNumber: paragraphNumber,
                relativeAudioPath: "qa/fixture.caf",
                audioURL: unavailableURL,
                audioIsAvailable: FileManager.default.fileExists(atPath: unavailableURL.path),
                duration: duration,
                fillerCount: fillerCount,
                pace: pace,
                stability: stability,
                transcript: transcript,
                transcriptSegments: [
                    SpeechTextSegment(text: "我曾帶領三人團隊", timestamp: 0, duration: 0.35),
                    SpeechTextSegment(text: "改善選課流程", timestamp: 0.38, duration: 0.25),
                    SpeechTextSegment(text: "重新整理資訊後", timestamp: 0.66, duration: 0.25),
                    SpeechTextSegment(text: "完成時間縮短兩分鐘", timestamp: 0.94, duration: 0.35)
                ]
            )
        }
        recordingSessions = [
            RecordingArchiveSessionSummary(
                id: UUID(),
                createdAt: now,
                completedAt: now,
                kind: .shortPractice,
                title: "30 秒自我介紹",
                language: .traditionalChinese,
                context: .selfIntroduction,
                paragraphCount: nil,
                attempts: [
                    attempt(sequence: 0, kind: .initial, duration: 30, fillerCount: 3, pace: 212, stability: 71),
                    attempt(sequence: 1, kind: .fullRetry, duration: 24, fillerCount: 1, pace: 190, stability: 84)
                ]
            ),
            RecordingArchiveSessionSummary(
                id: UUID(),
                createdAt: now.addingTimeInterval(-86_400),
                completedAt: now.addingTimeInterval(-86_400),
                kind: .scriptPractice,
                title: "自訂講稿",
                language: .traditionalChinese,
                context: .presentation,
                paragraphCount: 5,
                attempts: [
                    attempt(sequence: 0, kind: .initial, duration: 182, fillerCount: 12, pace: 176, stability: 68),
                    attempt(sequence: 1, kind: .segmentRetry, paragraphNumber: 2, duration: 28, fillerCount: 2, pace: 165, stability: 80),
                    attempt(sequence: 2, kind: .segmentRetry, paragraphNumber: 4, duration: 25, fillerCount: 1, pace: 158, stability: 86)
                ]
            )
        ]
    }
#endif

}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = self.components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
