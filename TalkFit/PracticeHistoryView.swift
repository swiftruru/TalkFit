import SwiftUI
import Charts

struct PracticeHistoryView: View {
    let model: TalkFitModel

    @Environment(\.dismiss) private var dismiss
    @State private var recordToDelete: PracticeHistorySummary?
    @State private var showsClearConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                        privacySection
                        trendSection
                        historySection
                    }
                    .talkFitPageInsets(bottom: 30)
                }
            }
            .navigationTitle("本機練習紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(TalkFitTheme.pine)
                }
            }
        }
        .tint(TalkFitTheme.pine)
        .alert("刪除這筆練習紀錄？", isPresented: deleteConfirmationBinding) {
            Button("保留", role: .cancel) { recordToDelete = nil }
            Button("刪除", role: .destructive) {
                if let recordToDelete {
                    model.deleteHistory(id: recordToDelete.id)
                }
                recordToDelete = nil
            }
        } message: {
            Text("只會刪除這筆摘要；這個動作無法復原。")
        }
        .alert("清除所有練習紀錄？", isPresented: $showsClearConfirmation) {
            Button("保留", role: .cancel) {}
            Button("全部清除", role: .destructive) {
                model.deleteAllHistory()
            }
        } message: {
            Text("所有保存在這台 iPhone 的練習摘要都會被刪除，且無法復原。")
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("慢慢長出的趨勢")
                .font(.headline)

            if model.practiceTrends.isEmpty {
                TrendAccumulationView(progress: model.trendProgress)
            } else {
                ForEach(model.practiceTrends) { trend in
                    PracticeTrendCard(trend: trend)
                }
            }
        }
        .accessibilityIdentifier("history.trends")
    }

    private var privacySection: some View {
        NotebookSection(title: "你的資料，由你決定") {
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: historyEnabledBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("保存練習摘要")
                            .font(.body.weight(.semibold))
                        Text(model.isHistoryEnabled ? "完成真實練習後，自動留下一筆" : "目前不會新增任何練習紀錄")
                            .font(.caption)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.6))
                    }
                }
                .tint(TalkFitTheme.moss)
                .accessibilityIdentifier("history.toggle")

                Divider().overlay(TalkFitTheme.line)

                Label {
                    Text("只保存日期、語言與前後指標。不保存錄音、逐字稿、逐句內容或贅字時間戳。")
                        .font(.caption)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(TalkFitTheme.sage)
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("所有練習")
                    .font(.headline)
                Spacer()
                if !model.practiceHistory.isEmpty {
                    Button("全部清除", role: .destructive) {
                        showsClearConfirmation = true
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TalkFitTheme.clay)
                    .accessibilityIdentifier("history.deleteAll")
                }
            }

            if model.practiceHistory.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.practiceHistory.enumerated()), id: \.element.id) { index, item in
                        historyRow(item)
                        if index < model.practiceHistory.count - 1 {
                            Divider().overlay(TalkFitTheme.line)
                                .padding(.leading, 42)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(
                    TalkFitTheme.paperLight.opacity(0.72),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(TalkFitTheme.line, lineWidth: 1)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "leaf")
                .foregroundStyle(TalkFitTheme.sage)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.isHistoryEnabled ? "第一筆紀錄正在等你" : "本機紀錄尚未開啟")
                    .font(.subheadline.weight(.semibold))
                Text(model.isHistoryEnabled
                     ? "完成一次真實練習與重練後，進步摘要會出現在這裡。"
                     : "開啟後，也只會保存不含錄音與逐字稿的摘要。")
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            TalkFitTheme.sageSoft.opacity(0.28),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private func historyRow(_ item: PracticeHistorySummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.caption)
                .foregroundStyle(TalkFitTheme.sage)
                .frame(width: 30, height: 30)
                .background(TalkFitTheme.sageSoft.opacity(0.3), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(item.promptTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(item.language.displayName)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(TalkFitTheme.moss)
                }
                Text(item.improvementNote)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.moss)
                Text(item.dateLabel)
                    .font(.caption2)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.5))
            }
            Spacer(minLength: 8)
            Button {
                recordToDelete = item
            } label: {
                Image(systemName: "trash")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(TalkFitTheme.clay)
            .accessibilityLabel("刪除 \(item.promptTitle) 紀錄")
            .accessibilityIdentifier("history.delete.\(item.id.uuidString)")
        }
        .padding(.vertical, 11)
    }

    private var historyEnabledBinding: Binding<Bool> {
        Binding(
            get: { model.isHistoryEnabled },
            set: model.setHistoryEnabled
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { recordToDelete != nil },
            set: { isPresented in
                if !isPresented { recordToDelete = nil }
            }
        )
    }
}

private struct TrendAccumulationView: View {
    let progress: PracticeTrendProgress?

    private var completedCount: Int { progress?.count ?? 0 }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            HStack(spacing: 5) {
                ForEach(0..<PracticeTrend.minimumPracticeCount, id: \.self) { index in
                    Image(systemName: index < completedCount ? "leaf.fill" : "leaf")
                        .foregroundStyle(index < completedCount ? TalkFitTheme.moss : TalkFitTheme.sage)
                }
            }
            .font(.caption)
            .padding(.top, 2)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            TalkFitTheme.sageSoft.opacity(0.28),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var title: String {
        guard let progress else { return "完成 3 次，看見變化" }
        return "再 \(progress.remainingCount) 次，就能看見趨勢"
    }

    private var message: String {
        guard let progress else {
            return "相同題目與語言累積 3 次後，才會整理贅字、語速與穩定度的長期變化。"
        }
        return "\(progress.language.displayName) · \(progress.promptTitle)，目前已累積 \(progress.count) 次。"
    }

    private var accessibilityLabel: String {
        guard let progress else { return "成長趨勢尚未開始，需要三次相同練習" }
        return "\(progress.promptTitle)已累積 \(progress.count) 次，再 \(progress.remainingCount) 次顯示趨勢"
    }
}

private struct PracticeTrendCard: View {
    let trend: PracticeTrend

    var body: some View {
        NotebookSection(title: "\(trend.language.displayName) · 最近 \(trend.points.count) 次") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(trend.promptTitle)
                        .font(.body.weight(.semibold))
                    Text(trend.priorityMessage)
                        .font(.caption)
                        .foregroundStyle(TalkFitTheme.moss)
                }

                TrendMetricChart(
                    title: "贅字",
                    latestValue: "\(trend.latest.fillerCount) 個",
                    changeLabel: trend.fillerChangeLabel,
                    values: trend.points.map(\.fillerCount),
                    color: TalkFitTheme.clay,
                    highlightsImprovement: trend.fillerChange < 0
                )

                Divider().overlay(TalkFitTheme.line)

                TrendMetricChart(
                    title: "語速",
                    latestValue: "\(trend.latest.pace) \(trend.language.paceUnit)",
                    changeLabel: trend.paceChangeLabel,
                    values: trend.points.map(\.pace),
                    color: TalkFitTheme.sage,
                    highlightsImprovement: trend.paceDistanceImprovement > 0
                        || trend.language.paceState(for: trend.latest.pace) == .steady,
                    comfortableRange: trend.context.comfortablePace(for: trend.language)
                )

                Divider().overlay(TalkFitTheme.line)

                TrendMetricChart(
                    title: "穩定度",
                    latestValue: "\(trend.latest.stability)%",
                    changeLabel: trend.stabilityChangeLabel,
                    values: trend.points.map(\.stability),
                    color: TalkFitTheme.moss,
                    highlightsImprovement: trend.stabilityChange > 0
                )

                HStack {
                    Text(shortDate(trend.earliest.completedAt))
                    Spacer()
                    Text(shortDate(trend.latest.completedAt))
                }
                .font(.caption2)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.48))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(trend.accessibilitySummary)
        .accessibilityIdentifier("history.trend.\(trend.id)")
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(Locale(identifier: "zh-Hant-TW"))
        )
    }
}

private struct TrendMetricChart: View {
    let title: String
    let latestValue: String
    let changeLabel: String
    let values: [Int]
    let color: Color
    let highlightsImprovement: Bool
    var comfortableRange: ClosedRange<Int>?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(latestValue)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TalkFitTheme.pine)
                Spacer(minLength: 8)
                Text(changeLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(changeColor)
            }

            Chart {
                if let comfortableRange {
                    RuleMark(y: .value("舒服下限", comfortableRange.lowerBound))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(TalkFitTheme.sage.opacity(0.35))
                    RuleMark(y: .value("舒服上限", comfortableRange.upperBound))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(TalkFitTheme.sage.opacity(0.35))
                }

                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("第幾次", index + 1),
                        y: .value(title, value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round))

                    PointMark(
                        x: .value("第幾次", index + 1),
                        y: .value(title, value)
                    )
                    .symbolSize(index == values.count - 1 ? 44 : 24)
                    .foregroundStyle(index == values.count - 1 ? TalkFitTheme.clay : color)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: chartDomain)
            .frame(height: 54)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，目前 \(latestValue)，相較第一次 \(changeLabel)")
    }

    private var chartDomain: ClosedRange<Int> {
        var bounds = values
        if let comfortableRange {
            bounds.append(contentsOf: [comfortableRange.lowerBound, comfortableRange.upperBound])
        }
        let minimum = bounds.min() ?? 0
        let maximum = bounds.max() ?? 1
        let padding = max(2, (maximum - minimum) / 5)
        return max(0, minimum - padding)...max(minimum + 1, maximum + padding)
    }

    private var changeColor: Color {
        highlightsImprovement ? TalkFitTheme.moss : TalkFitTheme.ink.opacity(0.58)
    }
}
