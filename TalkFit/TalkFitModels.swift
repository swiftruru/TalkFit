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
    var source: ResultSource

    static let empty = SpeechCapture(
        readableTranscript: "",
        analysisTranscript: "",
        fillerEvidence: [],
        source: .recognized
    )
}

struct PracticeResult: Equatable {
    let transcript: String
    let duration: TimeInterval
    let fillerCounts: [String: Int]
    let fillerEvidence: [FillerEvidence]
    let pace: Int
    let stability: Int
    let prioritySegment: String
    let coachingCue: String
    let source: ResultSource

    var fillerTotal: Int { fillerCounts.values.reduce(0, +) }

    var additionalFillerEvidence: [FillerEvidence] {
        var visibleCounts = TalkFitAnalyzer.fillerCounts(in: transcript)
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
        switch pace {
        case ..<170: "稍慢"
        case 170...235: "舒服"
        default: "稍快"
        }
    }

    var durationLabel: String {
        let seconds = max(1, Int(duration.rounded()))
        return "\(seconds) 秒"
    }

    var highlightedTranscript: AttributedString {
        var attributed = AttributedString(transcript)
        for filler in TalkFitFixtures.fillerWords {
            var searchStart = transcript.startIndex
            while searchStart < transcript.endIndex,
                  let range = transcript.range(of: filler, range: searchStart..<transcript.endIndex) {
                if let attributedRange = Range(range, in: attributed) {
                    attributed[attributedRange].backgroundColor = TalkFitTheme.clay.opacity(0.2)
                    attributed[attributedRange].foregroundColor = TalkFitTheme.clay
                    attributed[attributedRange].font = .body.bold()
                }
                searchStart = range.upperBound
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
    static let promptTitle = "30 秒自我介紹"
    static let prompt = "介紹你是誰、最近在做什麼，以及一件你想讓別人記住的事。"
    static let fillerWords = ["嗯", "呃", "然後", "就是", "這個", "那個", "其實", "對"]
    static let recognitionHints = fillerWords + [
        "嗯，我最近", "呃，我想", "然後我", "就是說", "這個部分", "那個時候", "其實我", "對，我覺得",
        promptTitle
    ]
    static let fillerLanguageModelPhrases: [(phrase: String, count: Int)] = [
        ("嗯", 3_000), ("呃", 3_000),
        ("嗯，我", 1_500), ("嗯，我最近", 1_200), ("嗯，然後", 1_000),
        ("呃，我", 1_500), ("呃，我想", 1_200), ("呃，然後", 1_000),
        ("然後我", 700), ("就是說", 700), ("這個部分", 500), ("那個時候", 500),
        ("其實我", 500), ("對，我覺得", 500)
    ]

    static let sampleFirstTranscript = "大家好，我是小安。嗯，我最近正在學習產品設計，然後也開始練習把想法說得更清楚。其實我很喜歡觀察生活裡的小細節，就是希望未來能做出讓人感到貼心的產品。"
    static let sampleRetryTranscript = "大家好，我是小安。我最近正在學習產品設計，也開始練習把想法說得更清楚。我希望未來能做出讓人感到貼心的產品。"

    static func sampleCapture(for round: PracticeRound) -> SpeechCapture {
        let evidenceTranscript = round == .first ? sampleFirstTranscript : sampleRetryTranscript
        let readableTranscript = round == .first
            ? sampleFirstTranscript.replacingOccurrences(of: "嗯，", with: "")
            : sampleRetryTranscript
        let duration: TimeInterval = round == .first ? 31 : 22
        return SpeechCapture(
            readableTranscript: readableTranscript,
            analysisTranscript: evidenceTranscript,
            fillerEvidence: TalkFitAnalyzer.sampleEvidence(in: evidenceTranscript, duration: duration),
            source: .sample
        )
    }

    static let history = [
        PracticeHistory(title: "專案近況", date: "昨天", note: "開頭更俐落了"),
        PracticeHistory(title: "30 秒自我介紹", date: "3 天前", note: "少了 2 個「然後」"),
        PracticeHistory(title: "會議提案", date: "上週", note: "語速更穩定")
    ]
}
