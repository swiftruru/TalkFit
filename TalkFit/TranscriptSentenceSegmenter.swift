import Foundation

struct TimedTranscriptSentence: Equatable {
    let text: String
    let startTime: TimeInterval
    let duration: TimeInterval
    let pauseAfter: TimeInterval?
}

enum TranscriptSentenceSegmenter {
    private static let strongBoundaries = CharacterSet(charactersIn: "。！？!?")
    private static let softBoundaries = CharacterSet(charactersIn: "，,；;：:")
    private static let trimBoundaries = CharacterSet(charactersIn: "。！？!?，,；;：:. ")
    private static let pauseThreshold: TimeInterval = 0.68

    static func sentences(
        in transcript: String,
        language: PracticeLanguage
    ) -> [String] {
        splitAtStrongBoundaries(transcript).flatMap { clause in
            splitLongClause(clause, language: language)
        }
    }

    static func timedSentences(
        capture: SpeechCapture,
        duration: TimeInterval,
        language: PracticeLanguage
    ) -> [TimedTranscriptSentence] {
        let transcriptUnits = language.speechUnitCount(in: capture.readableTranscript)
        let orderedSegments = capture.segments
            .filter { language.speechUnitCount(in: $0.text) > 0 }
            .sorted { $0.timestamp < $1.timestamp }
        let segmentUnits = orderedSegments.reduce(0) {
            $0 + language.speechUnitCount(in: $1.text)
        }

        guard !orderedSegments.isEmpty,
              segmentUnits >= max(2, Int(Double(transcriptUnits) * 0.6)),
              hasPlausibleTiming(orderedSegments, units: segmentUnits, language: language) else {
            return proportionalSentences(
                in: capture.readableTranscript,
                duration: duration,
                language: language
            )
        }

        var groups: [[SpeechTextSegment]] = []
        var current: [SpeechTextSegment] = []

        func finishCurrentGroup() {
            guard !current.isEmpty else { return }
            groups.append(current)
            current.removeAll(keepingCapacity: true)
        }

        for segment in orderedSegments {
            if let previous = current.last {
                let previousEnd = previous.timestamp + previous.duration
                let gap = segment.timestamp - previousEnd
                let currentUnits = current.reduce(0) {
                    $0 + language.speechUnitCount(in: $1.text)
                }
                if gap >= pauseThreshold, currentUnits >= minimumPauseUnits(for: language) {
                    finishCurrentGroup()
                }
            }

            current.append(segment)
            if endsWithStrongBoundary(segment.text) {
                finishCurrentGroup()
            }
        }
        finishCurrentGroup()

        let timedSentences = groups.flatMap { group -> [TimedTranscriptSentence] in
            let text = joinedText(for: group, language: language)
            let refined = sentences(in: text, language: language)
            guard !refined.isEmpty else { return [] }
            let start = group.first?.timestamp ?? 0
            let end = group.map { $0.timestamp + $0.duration }.max() ?? start
            let groupDuration = max(0.8, end - start)
            let totalUnits = max(1, refined.reduce(0) {
                $0 + language.speechUnitCount(in: $1)
            })
            var cursor = start
            return refined.map { sentence in
                let units = max(1, language.speechUnitCount(in: sentence))
                let sentenceDuration = max(
                    0.8,
                    groupDuration * Double(units) / Double(totalUnits)
                )
                defer { cursor += sentenceDuration }
                return TimedTranscriptSentence(
                    text: sentence,
                    startTime: cursor,
                    duration: sentenceDuration,
                    pauseAfter: nil
                )
            }
        }

        return timedSentences.enumerated().map { index, sentence in
            let pauseAfter: TimeInterval?
            if timedSentences.indices.contains(index + 1) {
                let sentenceEnd = sentence.startTime + sentence.duration
                pauseAfter = max(0, timedSentences[index + 1].startTime - sentenceEnd)
            } else {
                pauseAfter = nil
            }
            return TimedTranscriptSentence(
                text: sentence.text,
                startTime: sentence.startTime,
                duration: sentence.duration,
                pauseAfter: pauseAfter
            )
        }
    }

    /// Whether the recognizer's word timings can be trusted for pace.
    ///
    /// While a recording is still in progress Apple Speech reports partial
    /// results whose segments all sit at time zero with no duration. Treating
    /// those as real would squeeze a whole sentence into a fraction of a
    /// second and report an absurdly fast pace.
    static func hasReliableTiming(
        capture: SpeechCapture,
        language: PracticeLanguage
    ) -> Bool {
        let segments = capture.segments.filter { language.speechUnitCount(in: $0.text) > 0 }
        let units = segments.reduce(0) { $0 + language.speechUnitCount(in: $1.text) }
        return hasPlausibleTiming(segments, units: units, language: language)
    }

    private static func hasPlausibleTiming(
        _ segments: [SpeechTextSegment],
        units: Int,
        language: PracticeLanguage
    ) -> Bool {
        guard let start = segments.map(\.timestamp).min(),
              let end = segments.map({ $0.timestamp + $0.duration }).max() else {
            return false
        }
        let span = end - start
        guard span > 0 else { return false }
        // Faster than anyone can speak means the timings are placeholders.
        let fastestPossible: Double = language == .traditionalChinese ? 10 : 6
        return Double(units) / span <= fastestPossible
    }

    private static func proportionalSentences(
        in transcript: String,
        duration: TimeInterval,
        language: PracticeLanguage
    ) -> [TimedTranscriptSentence] {
        let result = sentences(in: transcript, language: language)
        let totalUnits = max(1, result.reduce(0) {
            $0 + language.speechUnitCount(in: $1)
        })
        var cursor: TimeInterval = 0
        return result.map { sentence in
            let units = max(1, language.speechUnitCount(in: sentence))
            let sentenceDuration = max(
                0.8,
                duration * Double(units) / Double(totalUnits)
            )
            defer { cursor += sentenceDuration }
            return TimedTranscriptSentence(
                text: sentence,
                startTime: cursor,
                duration: sentenceDuration,
                pauseAfter: nil
            )
        }
    }

    private static func splitAtStrongBoundaries(_ transcript: String) -> [String] {
        var clauses: [String] = []
        var buffer = ""

        func flush() {
            let text = cleaned(buffer)
            if !text.isEmpty { clauses.append(text) }
            buffer.removeAll(keepingCapacity: true)
        }

        var index = transcript.startIndex
        while index < transcript.endIndex {
            let character = transcript[index]
            if character == "\n" || character == "\r" {
                flush()
            } else if isStrongBoundary(character) {
                flush()
            } else if character == "." {
                let next = transcript.index(after: index)
                let isSentencePeriod = next == transcript.endIndex
                    || transcript[next].isWhitespace
                if isSentencePeriod {
                    flush()
                } else {
                    buffer.append(character)
                }
            } else {
                buffer.append(character)
            }
            index = transcript.index(after: index)
        }
        flush()
        return clauses
    }

    private static func splitLongClause(
        _ clause: String,
        language: PracticeLanguage
    ) -> [String] {
        let limits = sentenceLimits(for: language)
        var remaining = cleaned(clause)
        var result: [String] = []

        while language.speechUnitCount(in: remaining) > limits.maximum {
            let candidates = breakCandidates(in: remaining, language: language)
                .filter { candidate in
                    let units = language.speechUnitCount(
                        in: String(remaining[..<candidate.index])
                    )
                    return units >= limits.minimum && units <= limits.maximum
                }

            let selected = candidates.min { lhs, rhs in
                candidateScore(lhs, in: remaining, target: limits.target, language: language)
                    < candidateScore(rhs, in: remaining, target: limits.target, language: language)
            } ?? hardCut(in: remaining, maximumUnits: limits.maximum, language: language)

            guard selected.index > remaining.startIndex,
                  selected.index < remaining.endIndex else {
                break
            }

            let head = cleaned(String(remaining[..<selected.index]))
            remaining = cleaned(String(remaining[selected.index...]))
            if !head.isEmpty { result.append(head) }
        }

        let tail = cleaned(remaining)
        if !tail.isEmpty { result.append(tail) }
        return result
    }

    private static func breakCandidates(
        in text: String,
        language: PracticeLanguage
    ) -> [BreakCandidate] {
        var candidates: [BreakCandidate] = []
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            let next = text.index(after: index)
            if isSoftBoundary(character) {
                candidates.append(BreakCandidate(index: next, priority: 0))
            } else if character.isWhitespace {
                candidates.append(BreakCandidate(index: next, priority: 1))
            } else if isCJK(character) || isEndOfLatinToken(at: index, in: text) {
                candidates.append(BreakCandidate(index: next, priority: 2))
            }
            index = next
        }

        let connectors: [String]
        switch language {
        case .traditionalChinese:
            connectors = ["然後", "但是", "所以", "接著", "另外", "不過", "而且", "其實"]
        case .english:
            connectors = ["and", "but", "so", "then", "because", "however", "also"]
        }
        for connector in connectors {
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let range = text.range(
                    of: connector,
                    options: language == .english ? [.caseInsensitive] : [],
                    range: searchStart..<text.endIndex
                  ) {
                if isConnectorBoundary(range, in: text, language: language) {
                    candidates.append(BreakCandidate(index: range.lowerBound, priority: 0))
                }
                searchStart = range.upperBound
            }
        }
        return candidates
    }

    private static func hardCut(
        in text: String,
        maximumUnits: Int,
        language: PracticeLanguage
    ) -> BreakCandidate {
        var index = text.startIndex
        var best = text.endIndex
        while index < text.endIndex {
            let next = text.index(after: index)
            if isCJK(text[index]) || text[index].isWhitespace || isEndOfLatinToken(at: index, in: text) {
                let units = language.speechUnitCount(in: String(text[..<next]))
                best = next
                if units >= maximumUnits { break }
            }
            index = next
        }
        return BreakCandidate(index: best, priority: 3)
    }

    private static func candidateScore(
        _ candidate: BreakCandidate,
        in text: String,
        target: Int,
        language: PracticeLanguage
    ) -> Int {
        let units = language.speechUnitCount(in: String(text[..<candidate.index]))
        return abs(units - target) * 10 + candidate.priority
    }

    private static func isConnectorBoundary(
        _ range: Range<String.Index>,
        in text: String,
        language: PracticeLanguage
    ) -> Bool {
        guard range.lowerBound > text.startIndex else { return false }
        guard language == .english else { return true }
        let before = text.index(before: range.lowerBound)
        let afterIsBoundary = range.upperBound == text.endIndex
            || !text[range.upperBound].isLetter
        return !text[before].isLetter && afterIsBoundary
    }

    private static func joinedText(
        for segments: [SpeechTextSegment],
        language: PracticeLanguage
    ) -> String {
        var result = ""
        for segment in segments {
            let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            if let last = result.last, let first = text.first,
               shouldInsertSpace(between: last, and: first, language: language) {
                result.append(" ")
            }
            result.append(text)
        }
        return result
    }

    private static func shouldInsertSpace(
        between lhs: Character,
        and rhs: Character,
        language: PracticeLanguage
    ) -> Bool {
        guard !isSoftBoundary(rhs), !isStrongBoundary(rhs), rhs != "." else { return false }
        if language == .english { return true }
        return isLatinOrDigit(lhs) || isLatinOrDigit(rhs)
    }

    private static func endsWithStrongBoundary(_ text: String) -> Bool {
        guard let last = text.trimmingCharacters(in: .whitespacesAndNewlines).last else {
            return false
        }
        return isStrongBoundary(last) || last == "."
    }

    private static func cleaned(_ text: String) -> String {
        text
            .trimmingCharacters(in: trimBoundaries.union(.whitespacesAndNewlines))
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static func sentenceLimits(
        for language: PracticeLanguage
    ) -> (minimum: Int, target: Int, maximum: Int) {
        switch language {
        case .traditionalChinese: (8, 22, 32)
        case .english: (5, 14, 20)
        }
    }

    private static func minimumPauseUnits(for language: PracticeLanguage) -> Int {
        language == .traditionalChinese ? 4 : 3
    }

    private static func isStrongBoundary(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(strongBoundaries.contains)
    }

    private static func isSoftBoundary(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(softBoundaries.contains)
    }

    private static func isCJK(_ character: Character) -> Bool {
        character.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) }
    }

    private static func isLatinOrDigit(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy {
            $0.isASCII && CharacterSet.alphanumerics.contains($0)
        }
    }

    private static func isEndOfLatinToken(
        at index: String.Index,
        in text: String
    ) -> Bool {
        guard isLatinOrDigit(text[index]) || text[index] == "'" else { return false }
        let next = text.index(after: index)
        return next == text.endIndex
            || (!isLatinOrDigit(text[next]) && text[next] != "'")
    }
}

private struct BreakCandidate {
    let index: String.Index
    let priority: Int
}
