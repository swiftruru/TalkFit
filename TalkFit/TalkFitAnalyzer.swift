import Foundation

enum TalkFitAnalyzer {
    static func makeResult(
        capture: SpeechCapture,
        duration: TimeInterval,
        round: PracticeRound,
        language: PracticeLanguage,
        fillerWords: [String]
    ) -> PracticeResult {
        let trimmed = capture.readableTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let isUsable = capture.source == .sample
            || language.speechUnitCount(in: trimmed) >= language.minimumUsableUnits
        let effectiveCapture = isUsable
            ? capture
            : TalkFitFixtures.sampleCapture(
                for: round,
                language: language,
                fillerWords: fillerWords
            )
        let transcript = effectiveCapture.readableTranscript
        let source = effectiveCapture.source
        let effectiveDuration = source == .sample
            ? (round == .first ? 31 : 22)
            : max(duration, 4)

        let visibleCounts = fillerCounts(
            in: transcript,
            fillerWords: fillerWords,
            language: language
        )
        let evidenceCounts = Dictionary(grouping: effectiveCapture.fillerEvidence, by: \FillerEvidence.word)
            .mapValues(\.count)
        let counts = Dictionary(uniqueKeysWithValues: fillerWords.map { word in
            (word, max(visibleCounts[word] ?? 0, evidenceCounts[word] ?? 0))
        })
        let fillerTotal = counts.values.reduce(0, +)
        let units = language.speechUnitCount(in: transcript)
        let pace = Int((Double(units) / effectiveDuration * 60).rounded())
        let target = (language.comfortablePace.lowerBound + language.comfortablePace.upperBound) / 2
        let rangeWidth = max(1, language.comfortablePace.upperBound - language.comfortablePace.lowerBound)
        let pacePenalty = abs(pace - target) * 18 / rangeWidth
        let stability = max(42, min(96, 91 - fillerTotal * 8 - pacePenalty))

        let evidenceTranscript = effectiveCapture.analysisTranscript
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let segmentSource = fillerScore(
            in: evidenceTranscript,
            fillerWords: fillerWords,
            language: language
        ) > fillerScore(in: transcript, fillerWords: fillerWords, language: language)
            ? evidenceTranscript
            : transcript

        return PracticeResult(
            transcript: transcript,
            duration: effectiveDuration,
            fillerCounts: counts,
            fillerEvidence: effectiveCapture.fillerEvidence.sorted { $0.timestamp < $1.timestamp },
            fillerWords: fillerWords,
            language: language,
            sentencePaces: sentencePaceFeedback(
                capture: effectiveCapture,
                duration: effectiveDuration,
                language: language
            ),
            pace: pace,
            stability: stability,
            prioritySegment: prioritySegment(
                in: segmentSource,
                fillerWords: fillerWords,
                language: language
            ),
            coachingCue: "先停半拍，再用一句話直接說出重點。",
            source: source
        )
    }

    static func fillerCounts(
        in transcript: String,
        fillerWords: [String],
        language: PracticeLanguage
    ) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: fillerWords.map { filler in
            (filler, ranges(of: filler, in: transcript, language: language).count)
        })
    }

    static func ranges(
        of filler: String,
        in text: String,
        language: PracticeLanguage
    ) -> [Range<String.Index>] {
        guard !filler.isEmpty else { return [] }
        if language == .traditionalChinese {
            var result: [Range<String.Index>] = []
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let range = text.range(of: filler, range: searchStart..<text.endIndex) {
                result.append(range)
                searchStart = range.upperBound
            }
            return result
        }

        let escaped = NSRegularExpression.escapedPattern(for: filler)
        let pattern = "(?i)(?<![A-Za-z0-9'])\(escaped)(?![A-Za-z0-9'])"
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.matches(in: text, range: fullRange).compactMap { match in
            Range(match.range, in: text)
        }
    }

    static func sampleEvidence(
        in transcript: String,
        duration: TimeInterval,
        fillerWords: [String],
        language: PracticeLanguage
    ) -> [FillerEvidence] {
        let characterCount = max(1, transcript.count)
        return fillerWords.flatMap { filler in
            ranges(of: filler, in: transcript, language: language).map { range in
                let offset = transcript.distance(from: transcript.startIndex, to: range.lowerBound)
                return FillerEvidence(
                    word: filler,
                    timestamp: Double(offset) / Double(characterCount) * duration,
                    confidence: 1,
                    source: .sample
                )
            }
        }
        .sorted { $0.timestamp < $1.timestamp }
    }

    static func sampleSegments(
        in transcript: String,
        duration: TimeInterval,
        language: PracticeLanguage
    ) -> [SpeechTextSegment] {
        let sentences = sentenceTexts(in: transcript)
        guard !sentences.isEmpty else { return [] }
        let factors = [0.92, 1.12, 0.84, 1.04]
        let weights = sentences.enumerated().map { index, sentence in
            Double(max(1, language.speechUnitCount(in: sentence))) * factors[index % factors.count]
        }
        let totalWeight = max(1, weights.reduce(0, +))
        var cursor: TimeInterval = 0
        return zip(sentences, weights).map { sentence, weight in
            let segmentDuration = duration * weight / totalWeight
            defer { cursor += segmentDuration }
            return SpeechTextSegment(
                text: sentence,
                timestamp: cursor,
                duration: segmentDuration
            )
        }
    }

    static func sentencePaceFeedback(
        capture: SpeechCapture,
        duration: TimeInterval,
        language: PracticeLanguage
    ) -> [SentencePaceFeedback] {
        let sentences = sentenceTexts(in: capture.readableTranscript)
        guard !sentences.isEmpty else { return [] }
        let totalUnits = max(1, language.speechUnitCount(in: capture.readableTranscript))
        let orderedSegments = capture.segments.sorted { $0.timestamp < $1.timestamp }
        var segmentIndex = 0

        return sentences.map { sentence in
            let units = max(1, language.speechUnitCount(in: sentence))
            var consumedUnits = 0
            var start: TimeInterval?
            var end: TimeInterval?

            while segmentIndex < orderedSegments.count, consumedUnits < units {
                let segment = orderedSegments[segmentIndex]
                if start == nil { start = segment.timestamp }
                end = max(end ?? 0, segment.timestamp + segment.duration)
                consumedUnits += max(1, language.speechUnitCount(in: segment.text))
                segmentIndex += 1
            }

            let proportionalDuration = max(0.8, duration * Double(units) / Double(totalUnits))
            let sentenceDuration = max(0.8, (end ?? 0) - (start ?? 0))
            let effectiveDuration = start == nil ? proportionalDuration : sentenceDuration
            let pace = Int((Double(units) / effectiveDuration * 60).rounded())
            return SentencePaceFeedback(
                text: sentence,
                pace: pace,
                state: language.paceState(for: pace)
            )
        }
    }

    static func sentenceTexts(in transcript: String) -> [String] {
        transcript
            .components(separatedBy: CharacterSet(charactersIn: "。！？!?。\n"))
            .flatMap { component in
                component.components(separatedBy: ". ")
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func prioritySegment(
        in transcript: String,
        fillerWords: [String],
        language: PracticeLanguage
    ) -> String {
        let segments = transcript
            .components(separatedBy: CharacterSet(charactersIn: "。！？!?.\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let segment = segments.max { lhs, rhs in
            score(lhs, fillerWords: fillerWords, language: language)
                < score(rhs, fillerWords: fillerWords, language: language)
        } ?? transcript
        return segment + (language == .english ? "." : "。")
    }

    private static func score(
        _ segment: String,
        fillerWords: [String],
        language: PracticeLanguage
    ) -> Int {
        fillerScore(in: segment, fillerWords: fillerWords, language: language) * 5
            + min(language.speechUnitCount(in: segment), 36) / 7
    }

    private static func fillerScore(
        in text: String,
        fillerWords: [String],
        language: PracticeLanguage
    ) -> Int {
        fillerCounts(in: text, fillerWords: fillerWords, language: language)
            .values
            .reduce(0, +)
    }
}
