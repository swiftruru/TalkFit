import Foundation
import SwiftData

enum HistoryPreference: String, Equatable {
    case undecided
    case enabled
    case disabled
}

@Model
final class PracticeHistoryRecord {
    @Attribute(.unique) var id: UUID
    var completedAt: Date
    var languageIdentifier: String
    var promptIdentifier: String
    var promptTitle: String
    var duration: TimeInterval
    var beforeFillerCount: Int
    var afterFillerCount: Int
    var beforePace: Int
    var afterPace: Int
    var beforeStability: Int
    var afterStability: Int
    var beforeRhythmIssueCount: Int
    var afterRhythmIssueCount: Int

    init(
        id: UUID = UUID(),
        completedAt: Date = .now,
        language: PracticeLanguage,
        promptIdentifier: String = "self-introduction-30",
        promptTitle: String,
        duration: TimeInterval,
        beforeFillerCount: Int,
        afterFillerCount: Int,
        beforePace: Int,
        afterPace: Int,
        beforeStability: Int,
        afterStability: Int,
        beforeRhythmIssueCount: Int,
        afterRhythmIssueCount: Int
    ) {
        self.id = id
        self.completedAt = completedAt
        languageIdentifier = language.rawValue
        self.promptIdentifier = promptIdentifier
        self.promptTitle = promptTitle
        self.duration = duration
        self.beforeFillerCount = beforeFillerCount
        self.afterFillerCount = afterFillerCount
        self.beforePace = beforePace
        self.afterPace = afterPace
        self.beforeStability = beforeStability
        self.afterStability = afterStability
        self.beforeRhythmIssueCount = beforeRhythmIssueCount
        self.afterRhythmIssueCount = afterRhythmIssueCount
    }
}

struct PracticeHistorySummary: Identifiable, Equatable {
    let id: UUID
    let completedAt: Date
    let language: PracticeLanguage
    let promptIdentifier: String
    let promptTitle: String
    let duration: TimeInterval
    let beforeFillerCount: Int
    let afterFillerCount: Int
    let beforePace: Int
    let afterPace: Int
    let beforeStability: Int
    let afterStability: Int
    let beforeRhythmIssueCount: Int
    let afterRhythmIssueCount: Int

    init(record: PracticeHistoryRecord) {
        id = record.id
        completedAt = record.completedAt
        language = PracticeLanguage(rawValue: record.languageIdentifier) ?? .traditionalChinese
        promptIdentifier = record.promptIdentifier
        promptTitle = record.promptTitle
        duration = record.duration
        beforeFillerCount = record.beforeFillerCount
        afterFillerCount = record.afterFillerCount
        beforePace = record.beforePace
        afterPace = record.afterPace
        beforeStability = record.beforeStability
        afterStability = record.afterStability
        beforeRhythmIssueCount = record.beforeRhythmIssueCount
        afterRhythmIssueCount = record.afterRhythmIssueCount
    }

    init(
        id: UUID = UUID(),
        completedAt: Date,
        language: PracticeLanguage,
        promptIdentifier: String = "self-introduction-30",
        promptTitle: String? = nil,
        duration: TimeInterval = 48,
        beforeFillerCount: Int,
        afterFillerCount: Int,
        beforePace: Int,
        afterPace: Int,
        beforeStability: Int,
        afterStability: Int,
        beforeRhythmIssueCount: Int = 0,
        afterRhythmIssueCount: Int = 0
    ) {
        self.id = id
        self.completedAt = completedAt
        self.language = language
        self.promptIdentifier = promptIdentifier
        let context = PracticeContext(rawValue: promptIdentifier) ?? .selfIntroduction
        self.promptTitle = promptTitle ?? context.promptTitle(for: language)
        self.duration = duration
        self.beforeFillerCount = beforeFillerCount
        self.afterFillerCount = afterFillerCount
        self.beforePace = beforePace
        self.afterPace = afterPace
        self.beforeStability = beforeStability
        self.afterStability = afterStability
        self.beforeRhythmIssueCount = beforeRhythmIssueCount
        self.afterRhythmIssueCount = afterRhythmIssueCount
    }

    var fillerImprovement: Int {
        max(0, beforeFillerCount - afterFillerCount)
    }

    var stabilityImprovement: Int {
        max(0, afterStability - beforeStability)
    }

    var rhythmImprovement: Int {
        max(0, beforeRhythmIssueCount - afterRhythmIssueCount)
    }

    var improvementNote: String {
        if fillerImprovement > 0 {
            return "贅字少了 \(fillerImprovement) 個"
        }
        if rhythmImprovement > 0 {
            return "節奏提醒少了 \(rhythmImprovement) 個"
        }
        if stabilityImprovement > 0 {
            return "穩定度增加 \(stabilityImprovement)%"
        }
        return "完成一次專注重練"
    }

    var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(completedAt) { return "今天" }
        if calendar.isDateInYesterday(completedAt) { return "昨天" }
        let days = calendar.dateComponents([.day], from: completedAt, to: .now).day ?? 0
        if (2...6).contains(days) { return "\(days) 天前" }
        return completedAt.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(Locale(identifier: "zh-Hant-TW"))
        )
    }
}

@MainActor
final class PracticeHistoryStore {
    private static let preferenceKey = "talkfit.practice-history.preference.v1"

    private let modelContext: ModelContext
    private let defaults: UserDefaults

    init(modelContext: ModelContext, defaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.defaults = defaults
    }

    var preference: HistoryPreference {
        guard let rawValue = defaults.string(forKey: Self.preferenceKey) else {
            return .undecided
        }
        return HistoryPreference(rawValue: rawValue) ?? .undecided
    }

    func setPreference(_ preference: HistoryPreference) {
        defaults.set(preference.rawValue, forKey: Self.preferenceKey)
    }

    func fetchAll() -> [PracticeHistorySummary] {
        let descriptor = FetchDescriptor<PracticeHistoryRecord>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor))?.map(PracticeHistorySummary.init) ?? []
    }

    @discardableResult
    func save(_ comparison: ComparisonResult, completedAt: Date = .now) -> Bool {
        guard preference == .enabled,
              comparison.before.source == .recognized,
              comparison.after.source == .recognized else {
            return false
        }

        let before = comparison.before
        let after = comparison.after
        let record = PracticeHistoryRecord(
            completedAt: completedAt,
            language: before.language,
            promptIdentifier: before.historyPromptIdentifier,
            promptTitle: before.historyPromptTitle,
            duration: before.duration + after.duration,
            beforeFillerCount: before.fillerTotal,
            afterFillerCount: after.fillerTotal,
            beforePace: before.pace,
            afterPace: after.pace,
            beforeStability: before.stability,
            afterStability: after.stability,
            beforeRhythmIssueCount: before.rhythmSummary.issueCount,
            afterRhythmIssueCount: after.rhythmSummary.issueCount
        )
        modelContext.insert(record)
        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            return false
        }
    }

    func delete(id: UUID) {
        let descriptor = FetchDescriptor<PracticeHistoryRecord>()
        guard let records = try? modelContext.fetch(descriptor),
              let record = records.first(where: { $0.id == id }) else {
            return
        }
        modelContext.delete(record)
        try? modelContext.save()
    }

    func deleteAll() {
        let descriptor = FetchDescriptor<PracticeHistoryRecord>()
        guard let records = try? modelContext.fetch(descriptor) else { return }
        records.forEach(modelContext.delete)
        try? modelContext.save()
    }
}
