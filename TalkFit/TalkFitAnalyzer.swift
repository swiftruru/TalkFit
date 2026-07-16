import Foundation

enum TalkFitAnalyzer {
    static func makeResult(
        capture: SpeechCapture,
        duration: TimeInterval,
        round: PracticeRound
    ) -> PracticeResult {
        let trimmed = capture.readableTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let isUsable = capture.source == .sample || speechCharacterCount(in: trimmed) >= 8
        let effectiveCapture = isUsable ? capture : TalkFitFixtures.sampleCapture(for: round)
        let transcript = effectiveCapture.readableTranscript
        let source = effectiveCapture.source
        let effectiveDuration = source == .sample
            ? (round == .first ? 31 : 22)
            : max(duration, 4)

        let visibleCounts = fillerCounts(in: transcript)
        let evidenceCounts = Dictionary(grouping: effectiveCapture.fillerEvidence, by: \FillerEvidence.word)
            .mapValues(\.count)
        let counts = Dictionary(uniqueKeysWithValues: TalkFitFixtures.fillerWords.map { word in
            (word, max(visibleCounts[word] ?? 0, evidenceCounts[word] ?? 0))
        })
        let fillerTotal = counts.values.reduce(0, +)
        let characters = speechCharacterCount(in: transcript)
        let pace = Int((Double(characters) / effectiveDuration * 60).rounded())
        let paceDeviation = abs(pace - 205)
        let stability = max(42, min(96, 91 - fillerTotal * 8 - paceDeviation / 7))

        let evidenceTranscript = effectiveCapture.analysisTranscript
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let segmentSource = fillerScore(in: evidenceTranscript) > fillerScore(in: transcript)
            ? evidenceTranscript
            : transcript

        return PracticeResult(
            transcript: transcript,
            duration: effectiveDuration,
            fillerCounts: counts,
            fillerEvidence: effectiveCapture.fillerEvidence.sorted { $0.timestamp < $1.timestamp },
            pace: pace,
            stability: stability,
            prioritySegment: prioritySegment(in: segmentSource),
            coachingCue: "先停半拍，再用一句話直接說出重點。",
            source: source
        )
    }

    static func fillerCounts(in transcript: String) -> [String: Int] {
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

    static func speechCharacterCount(in text: String) -> Int {
        text.unicodeScalars.reduce(into: 0) { count, scalar in
            if (0x4E00...0x9FFF).contains(scalar.value) || CharacterSet.alphanumerics.contains(scalar) {
                count += 1
            }
        }
    }

    static func sampleEvidence(in transcript: String, duration: TimeInterval) -> [FillerEvidence] {
        let characterCount = max(1, transcript.count)
        return TalkFitFixtures.fillerWords.flatMap { filler -> [FillerEvidence] in
            var events: [FillerEvidence] = []
            var searchStart = transcript.startIndex
            while searchStart < transcript.endIndex,
                  let range = transcript.range(of: filler, range: searchStart..<transcript.endIndex) {
                let offset = transcript.distance(from: transcript.startIndex, to: range.lowerBound)
                events.append(
                    FillerEvidence(
                        word: filler,
                        timestamp: Double(offset) / Double(characterCount) * duration,
                        confidence: 1,
                        source: .sample
                    )
                )
                searchStart = range.upperBound
            }
            return events
        }
        .sorted { $0.timestamp < $1.timestamp }
    }

    private static func prioritySegment(in transcript: String) -> String {
        let segments = transcript
            .components(separatedBy: CharacterSet(charactersIn: "。！？!?，,\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return segments.max { lhs, rhs in
            score(lhs) < score(rhs)
        }.map { $0 + "。" } ?? transcript
    }

    private static func score(_ segment: String) -> Int {
        fillerScore(in: segment) * 5 + min(segment.count, 36) / 7
    }

    private static func fillerScore(in text: String) -> Int {
        TalkFitFixtures.fillerWords.reduce(0) { partial, filler in
            partial + text.components(separatedBy: filler).count - 1
        }
    }

}
