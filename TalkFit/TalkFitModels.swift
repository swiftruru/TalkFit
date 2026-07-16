import Foundation
import SwiftUI

enum PracticeRound: Equatable {
    case first
    case retry
}

enum PracticeStage: Equatable {
    case home
    case recording(PracticeRound)
    case analyzing(PracticeRound)
    case report
    case retry
    case comparison
}

enum ResultSource: Equatable {
    case recognized
    case sample

    var label: String {
        switch self {
        case .recognized: "你的練習"
        case .sample: "示範結果"
        }
    }
}

enum FillerEvidenceSource: Equatable {
    case partial
    case alternative
    case final
    case sample
}

struct FillerEvidence: Identifiable, Equatable {
    let id: UUID
    let word: String
    let timestamp: TimeInterval
    let confidence: Float
    let source: FillerEvidenceSource

    init(
        id: UUID = UUID(),
        word: String,
        timestamp: TimeInterval,
        confidence: Float,
        source: FillerEvidenceSource
    ) {
        self.id = id
        self.word = word
        self.timestamp = timestamp
        self.confidence = confidence
        self.source = source
    }

    var timestampLabel: String {
        let seconds = max(0, Int(timestamp.rounded()))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct SpeechCapture: Equatable {
    var readableTranscript: String
    var analysisTranscript: String
    var fillerEvidence: [FillerEvidence]
    var segments: [SpeechTextSegment]
    var source: ResultSource

    static let empty = SpeechCapture(
        readableTranscript: "",
        analysisTranscript: "",
        fillerEvidence: [],
        segments: [],
        source: .recognized
    )
}

struct PracticeResult: Equatable {
    let transcript: String
    let duration: TimeInterval
    let fillerCounts: [String: Int]
    let fillerEvidence: [FillerEvidence]
    let fillerWords: [String]
    let language: PracticeLanguage
    let sentencePaces: [SentencePaceFeedback]
    let pace: Int
    let stability: Int
    let prioritySegment: String
    let coachingCue: String
    let source: ResultSource

    var fillerTotal: Int { fillerCounts.values.reduce(0, +) }

    var additionalFillerEvidence: [FillerEvidence] {
        var visibleCounts = TalkFitAnalyzer.fillerCounts(
            in: transcript,
            fillerWords: fillerWords,
            language: language
        )
        return fillerEvidence
            .sorted { $0.timestamp < $1.timestamp }
            .filter { event in
                if (visibleCounts[event.word] ?? 0) > 0 {
                    visibleCounts[event.word, default: 0] -= 1
                    return false
                }
                return true
            }
    }

    var paceLabel: String {
        language.paceState(for: pace).label
    }

    var paceUnit: String { language.paceUnit }

    var durationLabel: String {
        let seconds = max(1, Int(duration.rounded()))
        return "\(seconds) 秒"
    }

    var highlightedTranscript: AttributedString {
        var attributed = AttributedString(transcript)
        for filler in fillerWords {
            for range in TalkFitAnalyzer.ranges(
                of: filler,
                in: transcript,
                language: language
            ) {
                if let attributedRange = Range(range, in: attributed) {
                    attributed[attributedRange].backgroundColor = TalkFitTheme.clay.opacity(0.2)
                    attributed[attributedRange].foregroundColor = TalkFitTheme.clay
                    attributed[attributedRange].font = .body.bold()
                }
            }
        }
        return attributed
    }
}

struct ComparisonResult: Equatable {
    let before: PracticeResult
    let after: PracticeResult

    var fillerImprovement: Int { max(0, before.fillerTotal - after.fillerTotal) }
    var stabilityImprovement: Int { max(0, after.stability - before.stability) }
}

struct PracticeHistory: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let note: String
}

enum TalkFitFixtures {
    static func sampleCapture(
        for round: PracticeRound,
        language: PracticeLanguage,
        fillerWords: [String]
    ) -> SpeechCapture {
        let evidenceTranscript = round == .first
            ? language.sampleFirstTranscript
            : language.sampleRetryTranscript
        let readableTranscript: String
        if round == .first, language == .traditionalChinese {
            readableTranscript = evidenceTranscript.replacingOccurrences(of: "嗯，", with: "")
        } else if round == .first {
            readableTranscript = evidenceTranscript.replacingOccurrences(
                of: "Um, ",
                with: "",
                options: [.caseInsensitive]
            )
        } else {
            readableTranscript = evidenceTranscript
        }
        let duration: TimeInterval = round == .first ? 31 : 22
        return SpeechCapture(
            readableTranscript: readableTranscript,
            analysisTranscript: evidenceTranscript,
            fillerEvidence: TalkFitAnalyzer.sampleEvidence(
                in: evidenceTranscript,
                duration: duration,
                fillerWords: fillerWords,
                language: language
            ),
            segments: TalkFitAnalyzer.sampleSegments(
                in: readableTranscript,
                duration: duration,
                language: language
            ),
            source: .sample
        )
    }

    static let history = [
        PracticeHistory(title: "專案近況", date: "昨天", note: "開頭更俐落了"),
        PracticeHistory(title: "30 秒自我介紹", date: "3 天前", note: "少了 2 個「然後」"),
        PracticeHistory(title: "會議提案", date: "上週", note: "語速更穩定")
    ]
}
