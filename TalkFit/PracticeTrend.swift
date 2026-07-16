import Foundation

struct PracticeTrendPoint: Identifiable, Equatable {
    let id: UUID
    let completedAt: Date
    let fillerCount: Int
    let pace: Int
    let stability: Int
}

struct PracticeTrend: Identifiable, Equatable {
    static let minimumPracticeCount = 3

    let id: String
    let promptIdentifier: String
    let promptTitle: String
    let language: PracticeLanguage
    let context: PracticeContext
    let points: [PracticeTrendPoint]

    var latest: PracticeTrendPoint { points[points.count - 1] }
    var earliest: PracticeTrendPoint { points[0] }

    var fillerChange: Int {
        latest.fillerCount - earliest.fillerCount
    }

    var stabilityChange: Int {
        latest.stability - earliest.stability
    }

    var paceDistanceImprovement: Int {
        paceDistance(fromComfortableRange: earliest.pace)
            - paceDistance(fromComfortableRange: latest.pace)
    }

    var priorityMessage: String {
        if fillerChange < 0 {
            return "贅字正慢慢變少"
        }
        if stabilityChange > 0 {
            return "表達穩定度正在長高"
        }
        if paceDistanceImprovement > 0 {
            return "語速更靠近舒服區間"
        }
        return "節奏正在累積成自己的樣子"
    }

    var fillerChangeLabel: String {
        if fillerChange < 0 { return "少了 \(-fillerChange) 個" }
        if fillerChange > 0 { return "多了 \(fillerChange) 個" }
        return "保持一樣"
    }

    var stabilityChangeLabel: String {
        if stabilityChange > 0 { return "+\(stabilityChange)%" }
        if stabilityChange < 0 { return "\(stabilityChange)%" }
        return "保持一樣"
    }

    var paceChangeLabel: String {
        if language.paceState(for: latest.pace) == .steady {
            return language.paceState(for: earliest.pace) == .steady
                ? "維持舒服區間"
                : "來到舒服區間"
        }
        if paceDistanceImprovement > 0 {
            return "更靠近舒服區間"
        }
        if paceDistanceImprovement < 0 {
            return "稍微偏離舒服區間"
        }
        return "節奏持平"
    }

    var accessibilitySummary: String {
        "\(promptTitle)，\(points.count) 次練習。贅字 \(fillerChangeLabel)，語速 \(paceChangeLabel)，穩定度 \(stabilityChangeLabel)。"
    }

    static func make(from history: [PracticeHistorySummary]) -> [PracticeTrend] {
        let groups = Dictionary(grouping: history) { item in
            "\(item.language.rawValue)|\(item.promptIdentifier)"
        }

        return groups.compactMap { key, items in
            guard items.count >= minimumPracticeCount,
                  let newest = items.max(by: { $0.completedAt < $1.completedAt }) else {
                return nil
            }
            let sorted = items.sorted { $0.completedAt < $1.completedAt }
            return PracticeTrend(
                id: key,
                promptIdentifier: newest.promptIdentifier,
                promptTitle: newest.promptTitle,
                language: newest.language,
                context: PracticeContext(rawValue: newest.promptIdentifier) ?? .selfIntroduction,
                points: sorted.map { item in
                    PracticeTrendPoint(
                        id: item.id,
                        completedAt: item.completedAt,
                        fillerCount: item.afterFillerCount,
                        pace: item.afterPace,
                        stability: item.afterStability
                    )
                }
            )
        }
        .sorted { $0.latest.completedAt > $1.latest.completedAt }
    }

    private func paceDistance(fromComfortableRange pace: Int) -> Int {
        let range = context.comfortablePace(for: language)
        if pace < range.lowerBound { return range.lowerBound - pace }
        if pace > range.upperBound { return pace - range.upperBound }
        return 0
    }
}

struct PracticeTrendProgress: Equatable {
    let promptTitle: String
    let language: PracticeLanguage
    let count: Int

    var remainingCount: Int {
        max(0, PracticeTrend.minimumPracticeCount - count)
    }

    static func closest(from history: [PracticeHistorySummary]) -> PracticeTrendProgress? {
        let groups = Dictionary(grouping: history) { item in
            "\(item.language.rawValue)|\(item.promptIdentifier)"
        }
        guard let closest = groups.values.max(by: { lhs, rhs in
            if lhs.count == rhs.count {
                let lhsDate = lhs.map(\.completedAt).max() ?? .distantPast
                let rhsDate = rhs.map(\.completedAt).max() ?? .distantPast
                return lhsDate < rhsDate
            }
            return lhs.count < rhs.count
        }), let newest = closest.max(by: { $0.completedAt < $1.completedAt }) else {
            return nil
        }
        return PracticeTrendProgress(
            promptTitle: newest.promptTitle,
            language: newest.language,
            count: min(closest.count, PracticeTrend.minimumPracticeCount)
        )
    }
}
