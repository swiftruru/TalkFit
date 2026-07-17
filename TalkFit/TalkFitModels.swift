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
    case recognitionIssue(PracticeRound, RecognitionIssue)
    case report
    case retry
    case comparison
}

enum RecognitionIssue: Equatable {
    case serviceUnavailable
    case noTranscript

    var title: String {
        switch self {
        case .serviceUnavailable:
            "目前無法開始語音辨識"
        case .noTranscript:
            "這次沒有取得逐字稿"
        }
    }

    var message: String {
        switch self {
        case .serviceUnavailable:
            "麥克風或 Apple 語音辨識目前無法使用。你的內容不會被替換成示範逐字稿。"
        case .noTranscript:
            "我們沒有收到足夠清楚的辨識文字。這次錄音不會被換成「小安」的範例內容。"
        }
    }
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
    var recordedFileURL: URL? = nil

    static let empty = SpeechCapture(
        readableTranscript: "",
        analysisTranscript: "",
        fillerEvidence: [],
        segments: [],
        source: .recognized
    )

    var preservingBestTranscript: SpeechCapture {
        var capture = self
        let readable = readableTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard readable.isEmpty else {
            capture.readableTranscript = readable
            return capture
        }
        capture.readableTranscript = analysisTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        return capture
    }

    var hasReadableTranscript: Bool {
        !readableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct PracticeResult: Equatable {
    let transcript: String
    let transcriptSegments: [SpeechTextSegment]
    let duration: TimeInterval
    let fillerCounts: [String: Int]
    let fillerEvidence: [FillerEvidence]
    let fillerWords: [String]
    let language: PracticeLanguage
    let context: PracticeContext
    let scriptReference: ScriptPracticeReference?
    let scriptComparison: ScriptSpeechComparison?
    let sentencePaces: [SentencePaceFeedback]
    let pace: Int
    let stability: Int
    let prioritySegment: String
    let coachingCue: String
    let source: ResultSource

    init(
        transcript: String,
        transcriptSegments: [SpeechTextSegment] = [],
        duration: TimeInterval,
        fillerCounts: [String: Int],
        fillerEvidence: [FillerEvidence],
        fillerWords: [String],
        language: PracticeLanguage,
        context: PracticeContext = .selfIntroduction,
        scriptReference: ScriptPracticeReference? = nil,
        scriptComparison: ScriptSpeechComparison? = nil,
        sentencePaces: [SentencePaceFeedback],
        pace: Int,
        stability: Int,
        prioritySegment: String,
        coachingCue: String,
        source: ResultSource
    ) {
        self.transcript = transcript
        self.transcriptSegments = transcriptSegments
        self.duration = duration
        self.fillerCounts = fillerCounts
        self.fillerEvidence = fillerEvidence
        self.fillerWords = fillerWords
        self.language = language
        self.context = context
        self.scriptReference = scriptReference
        self.scriptComparison = scriptComparison
        self.sentencePaces = sentencePaces
        self.pace = pace
        self.stability = stability
        self.prioritySegment = prioritySegment
        self.coachingCue = coachingCue
        self.source = source
    }

    var fillerTotal: Int { fillerCounts.values.reduce(0, +) }

    var practiceTitle: String {
        scriptReference?.title ?? context.displayName
    }

    var historyPromptIdentifier: String {
        scriptReference == nil ? context.rawValue : "custom-script"
    }

    var historyPromptTitle: String {
        scriptReference == nil ? context.promptTitle(for: language) : "自訂講稿"
    }

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
        context.paceState(for: pace, language: language).label
    }

    var paceUnit: String { language.paceUnit }

    var rhythmSummary: RhythmSummary {
        RhythmSummary(feedback: sentencePaces)
    }

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
    var rhythmIssueImprovement: Int {
        max(0, before.rhythmSummary.issueCount - after.rhythmSummary.issueCount)
    }

    var rhythmImprovementLabel: String {
        rhythmIssueImprovement > 0
            ? "少了 \(rhythmIssueImprovement) 個節奏提醒"
            : "停頓更自然"
    }
}

enum TalkFitFixtures {
    static func sampleCapture(
        for round: PracticeRound,
        language: PracticeLanguage,
        context: PracticeContext = .selfIntroduction,
        fillerWords: [String]
    ) -> SpeechCapture {
        let evidenceTranscript = context.sampleTranscript(for: round, language: language)
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
                language: language,
                round: round
            ),
            source: .sample
        )
    }

    static func scriptCapture(
        for round: PracticeRound,
        language: PracticeLanguage,
        script: String,
        fillerWords: [String]
    ) -> SpeechCapture {
        let trimmedScript = script.trimmingCharacters(in: .whitespacesAndNewlines)
        // A user's script is reference content, so demo mode must never rewrite
        // legitimate words merely because they also appear in the filler library.
        let cleanScript = trimmedScript
        let evidenceTranscript: String
        if round == .first {
            evidenceTranscript = language == .traditionalChinese
                ? "嗯，\(cleanScript)"
                : "Um, \(cleanScript)"
        } else {
            evidenceTranscript = cleanScript
        }
        let duration: TimeInterval = round == .first ? 31 : 22
        return SpeechCapture(
            readableTranscript: cleanScript,
            analysisTranscript: evidenceTranscript,
            fillerEvidence: TalkFitAnalyzer.sampleEvidence(
                in: evidenceTranscript,
                duration: duration,
                fillerWords: fillerWords,
                language: language
            ),
            segments: TalkFitAnalyzer.sampleSegments(
                in: cleanScript,
                duration: duration,
                language: language,
                round: round
            ),
            source: .sample
        )
    }
}
