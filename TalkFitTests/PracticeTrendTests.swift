import Foundation
import Testing
@testable import TalkFit

struct PracticeTrendTests {
    @Test("相同題目未滿三次時只顯示累積進度")
    func requiresThreeMatchingPractices() throws {
        let history = [
            summary(day: 1, language: .traditionalChinese),
            summary(day: 2, language: .traditionalChinese)
        ]

        #expect(PracticeTrend.make(from: history).isEmpty)
        let progress = try #require(PracticeTrendProgress.closest(from: history))
        #expect(progress.count == 2)
        #expect(progress.remainingCount == 1)
    }

    @Test("趨勢依完成時間排序並使用重練後指標")
    func buildsChronologicalTrendFromAfterMetrics() throws {
        let history = [
            summary(day: 3, afterFillers: 1, afterPace: 205, afterStability: 84),
            summary(day: 1, afterFillers: 4, afterPace: 260, afterStability: 60),
            summary(day: 2, afterFillers: 2, afterPace: 230, afterStability: 72)
        ]

        let trend = try #require(PracticeTrend.make(from: history).first)

        #expect(trend.points.map(\.completedAt) == [date(day: 1), date(day: 2), date(day: 3)])
        #expect(trend.points.map(\.fillerCount) == [4, 2, 1])
        #expect(trend.points.map(\.pace) == [260, 230, 205])
        #expect(trend.points.map(\.stability) == [60, 72, 84])
        #expect(trend.fillerChange == -3)
        #expect(trend.stabilityChange == 24)
        #expect(trend.paceDistanceImprovement == 25)
        #expect(trend.paceChangeLabel == "來到舒服區間")
    }

    @Test("不同語言與題目不會混入同一條趨勢")
    func groupsByLanguageAndPrompt() {
        let history = [
            summary(day: 1, language: .traditionalChinese),
            summary(day: 2, language: .traditionalChinese),
            summary(day: 3, language: .traditionalChinese),
            summary(day: 4, language: .english),
            summary(day: 5, language: .english),
            summary(day: 6, language: .traditionalChinese, promptIdentifier: "interview", promptTitle: "面試回答"),
            summary(day: 7, language: .traditionalChinese, promptIdentifier: "interview", promptTitle: "面試回答"),
            summary(day: 8, language: .traditionalChinese, promptIdentifier: "interview", promptTitle: "面試回答")
        ]

        let trends = PracticeTrend.make(from: history)

        #expect(trends.count == 2)
        #expect(trends[0].promptIdentifier == "interview")
        #expect(trends[0].points.count == 3)
        #expect(trends[1].promptIdentifier == "self-introduction-30")
        #expect(trends[1].language == .traditionalChinese)
        #expect(trends[1].paceChangeLabel == "維持舒服區間")
    }

    @Test("累積提示優先選擇筆數較多且最近的分組")
    func progressChoosesClosestRecentGroup() throws {
        let history = [
            summary(day: 1, language: .traditionalChinese),
            summary(day: 2, language: .traditionalChinese),
            summary(day: 4, language: .english),
            summary(day: 5, language: .english)
        ]

        let progress = try #require(PracticeTrendProgress.closest(from: history))

        #expect(progress.language == .english)
        #expect(progress.count == 2)
    }

    private func summary(
        day: Int,
        language: PracticeLanguage = .traditionalChinese,
        promptIdentifier: String = "self-introduction-30",
        promptTitle: String? = nil,
        afterFillers: Int = 2,
        afterPace: Int = 200,
        afterStability: Int = 76
    ) -> PracticeHistorySummary {
        PracticeHistorySummary(
            completedAt: date(day: day),
            language: language,
            promptIdentifier: promptIdentifier,
            promptTitle: promptTitle,
            beforeFillerCount: afterFillers + 2,
            afterFillerCount: afterFillers,
            beforePace: afterPace + 30,
            afterPace: afterPace,
            beforeStability: max(0, afterStability - 18),
            afterStability: afterStability
        )
    }

    private func date(day: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(day * 86_400))
    }
}
