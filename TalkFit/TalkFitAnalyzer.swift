import Foundation

enum TalkFitAnalyzer {
    static func makeResult(
        capture: SpeechCapture,
        duration: TimeInterval,
        round: PracticeRound,
        language: PracticeLanguage,
        context: PracticeContext = .selfIntroduction,
        scriptReference: ScriptPracticeReference? = nil,
        fillerWords: [String]
    ) -> PracticeResult {
        // A recognized capture must remain the user's capture, even when it is
        // short or incomplete. Sample content is accepted only when the caller
        // explicitly supplied a sample capture.
        let effectiveCapture = capture
        let transcript = effectiveCapture.readableTranscript
        let source = effectiveCapture.source
        let effectiveDuration: TimeInterval
        if source == .sample, scriptReference != nil {
            let units = max(1, language.speechUnitCount(in: transcript))
            let comfortablePace = context.comfortablePace(for: language)
            let targetPace = max(1, (comfortablePace.lowerBound + comfortablePace.upperBound) / 2)
            effectiveDuration = Double(units) / Double(targetPace) * 60
        } else if source == .sample {
            effectiveDuration = round == .first ? 31 : 22
        } else {
            effectiveDuration = max(duration, 4)
        }

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
        let sentencePaces = sentencePaceFeedback(
            capture: effectiveCapture,
            duration: effectiveDuration,
            language: language,
            context: context
        )
        let rhythmSummary = RhythmSummary(feedback: sentencePaces)
        let comfortablePace = context.comfortablePace(for: language)
        let target = (comfortablePace.lowerBound + comfortablePace.upperBound) / 2
        let rangeWidth = max(1, comfortablePace.upperBound - comfortablePace.lowerBound)
        let pacePenalty = abs(pace - target) * 18 / rangeWidth
        let rhythmPenalty = rhythmSummary.shortPauseCount * 3
            + rhythmSummary.longPauseCount * 4
            + rhythmSummary.suddenAccelerationCount * 6
        let stability = max(
            42,
            min(96, 91 - fillerTotal * 8 - pacePenalty - rhythmPenalty)
        )

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
            context: context,
            scriptReference: scriptReference,
            scriptComparison: scriptReference.map {
                ScriptPracticeAnalyzer.compare(
                    reference: $0.text,
                    spoken: transcript,
                    language: language
                )
            },
            sentencePaces: sentencePaces,
            pace: pace,
            stability: stability,
            prioritySegment: prioritySegment(
                in: segmentSource,
                fillerWords: fillerWords,
                language: language
            ),
            coachingCue: coachingCue(for: rhythmSummary),
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

    static func removingFillers(
        from text: String,
        fillerWords: [String],
        language: PracticeLanguage
    ) -> String {
        var result = text
        for filler in fillerWords {
            let matches = ranges(of: filler, in: result, language: language)
            for range in matches.reversed() {
                result.removeSubrange(range)
            }
        }
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        let leadingTrimSet = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
        while let scalar = result.unicodeScalars.first,
              leadingTrimSet.contains(scalar) {
            result.removeFirst()
        }
        return result.replacingOccurrences(of: "  ", with: " ")
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
        language: PracticeLanguage,
        round: PracticeRound
    ) -> [SpeechTextSegment] {
        let sentences = sentenceTexts(in: transcript, language: language)
        guard !sentences.isEmpty else { return [] }
        let factors = round == .first
            ? [1.15, 0.62, 1.18, 0.92]
            : [1.0, 0.98, 1.02, 1.0]
        let pauses = round == .first
            ? [0.12, 1.55, 0.18]
            : [0.72, 0.64, 0.78]
        let totalPause = pauses.prefix(max(0, sentences.count - 1)).reduce(0, +)
        let speakingDuration = max(Double(sentences.count) * 0.8, duration - totalPause)
        let weights = sentences.enumerated().map { index, sentence in
            Double(max(1, language.speechUnitCount(in: sentence))) * factors[index % factors.count]
        }
        let totalWeight = max(1, weights.reduce(0, +))
        var cursor: TimeInterval = 0
        return zip(sentences, weights).enumerated().map { index, entry in
            let (sentence, weight) = entry
            let segmentDuration = speakingDuration * weight / totalWeight
            defer {
                cursor += segmentDuration
                if sentences.indices.contains(index + 1) {
                    cursor += pauses[index % pauses.count]
                }
            }
            return SpeechTextSegment(
                text: sentence + (language == .english ? "." : "。"),
                timestamp: cursor,
                duration: segmentDuration
            )
        }
    }

    static func sentencePaceFeedback(
        capture: SpeechCapture,
        duration: TimeInterval,
        language: PracticeLanguage,
        context: PracticeContext = .selfIntroduction
    ) -> [SentencePaceFeedback] {
        let sentences = TranscriptSentenceSegmenter.timedSentences(
            capture: capture,
            duration: duration,
            language: language
        )
        let paces = sentences.map { sentence in
            let units = max(1, language.speechUnitCount(in: sentence.text))
            return Int((Double(units) / sentence.duration * 60).rounded())
        }

        return sentences.enumerated().map { index, sentence in
            let pace = paces[index]
            let paceChange = index > 0 ? pace - paces[index - 1] : nil
            let accelerationThreshold = language == .traditionalChinese ? 45 : 30
            let isSuddenAcceleration = paceChange.map { change in
                let previousPace = max(1, paces[index - 1])
                return change >= accelerationThreshold
                    && Double(pace) / Double(previousPace) >= 1.28
            } ?? false
            let classifiedPauseState: SentencePauseState?
            if let pauseAfter = sentence.pauseAfter {
                classifiedPauseState = pauseState(for: pauseAfter)
            } else {
                classifiedPauseState = nil
            }
            return SentencePaceFeedback(
                text: sentence.text,
                pace: pace,
                state: context.paceState(for: pace, language: language),
                context: context,
                pauseAfter: sentence.pauseAfter,
                pauseState: classifiedPauseState,
                paceChange: paceChange,
                isSuddenAcceleration: isSuddenAcceleration
            )
        }
    }

    static func sentenceTexts(
        in transcript: String,
        language: PracticeLanguage
    ) -> [String] {
        TranscriptSentenceSegmenter.sentences(in: transcript, language: language)
    }

    private static func prioritySegment(
        in transcript: String,
        fillerWords: [String],
        language: PracticeLanguage
    ) -> String {
        let segments = sentenceTexts(in: transcript, language: language)

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

    private static func pauseState(for duration: TimeInterval) -> SentencePauseState {
        if duration < 0.35 { return .short }
        if duration > 1.25 { return .long }
        return .balanced
    }

    private static func coachingCue(for rhythmSummary: RhythmSummary) -> String {
        if rhythmSummary.suddenAccelerationCount > 0 {
            return "先把第一個重點說穩，句尾留半拍再接下一句。"
        }
        if rhythmSummary.shortPauseCount > 0 {
            return "句尾多留半拍，再用一句話直接說出重點。"
        }
        if rhythmSummary.longPauseCount > 0 {
            return "先想好下一句的開頭，再讓停頓自然接回重點。"
        }
        return "保留現在的停頓，用一句話直接說出重點。"
    }
}
