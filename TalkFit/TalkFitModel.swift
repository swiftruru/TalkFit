import Foundation
import Observation

@MainActor
@Observable
final class TalkFitModel {
    var stage: PracticeStage = .home
    var elapsed: TimeInterval = 0
    var audioLevel: Float = 0.08
    var liveTranscript = ""
    var firstResult: PracticeResult?
    var comparison: ComparisonResult?
    var fallbackNotice: String?
    var isDemoMode = false

    @ObservationIgnored private let speech = AudioSpeechService()
    @ObservationIgnored private var clockTask: Task<Void, Never>?

    init() {
        speech.levelDidChange = { [weak self] level in self?.audioLevel = level }
        speech.transcriptDidChange = { [weak self] transcript in self?.liveTranscript = transcript }
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
        let recognized = speech.stop()
        if !recognized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            liveTranscript = recognized
        }
        let capturedDuration = max(elapsed, 1)
        stage = .analyzing

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(1050))
            guard let self, !Task.isCancelled else { return }
            switch round {
            case .first:
                let result = self.makeResult(
                    transcript: self.liveTranscript,
                    duration: capturedDuration,
                    round: .first
                )
                self.firstResult = result
                self.isDemoMode = result.source == .sample
                self.stage = .report
            case .retry:
                guard let before = self.firstResult else {
                    self.stage = .home
                    return
                }
                let after = self.makeResult(
                    transcript: self.liveTranscript,
                    duration: capturedDuration,
                    round: .retry
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

    func returnHome() {
        clockTask?.cancel()
        speech.stop()
        elapsed = 0
        audioLevel = 0.08
        liveTranscript = ""
        firstResult = nil
        comparison = nil
        fallbackNotice = nil
        isDemoMode = false
        stage = .home
    }

    private func beginRecording(round: PracticeRound, demo: Bool) {
        clockTask?.cancel()
        speech.stop()
        elapsed = 0
        audioLevel = 0.08
        liveTranscript = ""
        fallbackNotice = demo ? "示範模式：會使用預先準備的穩定結果" : nil
        isDemoMode = demo
        stage = .recording(round)
        startClock(synthetic: demo)

        guard !demo else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.speech.start()
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
                }
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    private func makeResult(transcript rawTranscript: String, duration: TimeInterval, round: PracticeRound) -> PracticeResult {
        let trimmed = rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let isUsable = Self.speechCharacterCount(in: trimmed) >= 8
        let transcript: String
        let source: ResultSource
        let effectiveDuration: TimeInterval

        if isUsable {
            transcript = trimmed
            source = .recognized
            effectiveDuration = max(duration, 4)
        } else {
            transcript = round == .first ? TalkFitFixtures.sampleFirstTranscript : TalkFitFixtures.sampleRetryTranscript
            source = .sample
            effectiveDuration = round == .first ? 31 : 22
        }

        let counts = Self.fillerCounts(in: transcript)
        let fillerTotal = counts.values.reduce(0, +)
        let characters = Self.speechCharacterCount(in: transcript)
        let pace = Int((Double(characters) / effectiveDuration * 60).rounded())
        let paceDeviation = abs(pace - 205)
        let stability = max(42, min(96, 91 - fillerTotal * 8 - paceDeviation / 7))
        let segment = Self.prioritySegment(in: transcript)

        return PracticeResult(
            transcript: transcript,
            duration: effectiveDuration,
            fillerCounts: counts,
            pace: pace,
            stability: stability,
            prioritySegment: segment,
            coachingCue: "先停半拍，再用一句話直接說出重點。",
            source: source
        )
    }

    private static func fillerCounts(in transcript: String) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: TalkFitFixtures.fillerWords.map { filler in
            var count = 0
            var searchStart = transcript.startIndex
            while searchStart < transcript.endIndex,
                  let range = transcript.range(of: filler, range: searchStart..<transcript.endIndex) {
                count += 1
                searchStart = range.upperBound
            }
            return (filler, count)
        })
    }

    private static func speechCharacterCount(in text: String) -> Int {
        text.unicodeScalars.reduce(into: 0) { count, scalar in
            if (0x4E00...0x9FFF).contains(scalar.value) || CharacterSet.alphanumerics.contains(scalar) {
                count += 1
            }
        }
    }

    private static func prioritySegment(in transcript: String) -> String {
        let segments = transcript
            .components(separatedBy: CharacterSet(charactersIn: "。！？!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return segments.max { lhs, rhs in
            score(lhs) < score(rhs)
        }.map { $0 + "。" } ?? transcript
    }

    private static func score(_ segment: String) -> Int {
        let fillerScore = TalkFitFixtures.fillerWords.reduce(0) { partial, filler in
            partial + segment.components(separatedBy: filler).count - 1
        } * 5
        return fillerScore + min(segment.count, 36) / 7
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = self.components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
