import SwiftUI

struct ContentView: View {
    @State private var model = TalkFitModel()

    var body: some View {
        ZStack {
            PaperBackground()
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(TalkFitTheme.pine)
        .foregroundStyle(TalkFitTheme.ink)
        .animation(.easeInOut(duration: 0.35), value: model.stage)
    }

    @ViewBuilder
    private var screen: some View {
        switch model.stage {
        case .home:
            HomeView(model: model)
        case .recording(let round):
            RecordingView(model: model, round: round)
        case .analyzing:
            AnalysisView()
        case .report:
            if let result = model.firstResult {
                ReportView(model: model, result: result)
            }
        case .retry:
            if let result = model.firstResult {
                RetryView(model: model, result: result)
            }
        case .comparison:
            if let comparison = model.comparison {
                ComparisonView(model: model, comparison: comparison)
            }
        }
    }
}

private struct HomeView: View {
    let model: TalkFitModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                BrandHeader()

                VStack(alignment: .leading, spacing: 8) {
                    Text("今天，讓表達自然長出來")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                    Text("用 30 秒，練習說得更清楚一點。")
                        .font(.subheadline)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.65))
                }

                growthStrip
                promptSheet

                VStack(alignment: .leading, spacing: 14) {
                    Text("最近的練習")
                        .font(.headline)
                    ForEach(TalkFitFixtures.history) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "leaf")
                                .foregroundStyle(TalkFitTheme.sage)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.subheadline.weight(.semibold))
                                Text(item.note).font(.caption).foregroundStyle(TalkFitTheme.moss)
                            }
                            Spacer()
                            Text(item.date).font(.caption2).foregroundStyle(TalkFitTheme.ink.opacity(0.48))
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                        if item.id != TalkFitFixtures.history.last?.id {
                            Divider().overlay(TalkFitTheme.line)
                        }
                    }
                }
            }
            .talkFitPageInsets(bottom: 132)
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                VStack(spacing: 10) {
                    Button {
                        model.startPractice()
                    } label: {
                        Label("開始 30 秒練習", systemImage: "mic.fill")
                    }
                    .buttonStyle(PrimaryActionStyle())
                    .accessibilityIdentifier("home.start")

                    Button("示範練習") {
                        model.startPractice(demo: true)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TalkFitTheme.moss)
                    .accessibilityHint("不使用麥克風，以固定內容體驗完整流程")
                    .accessibilityIdentifier("home.demo")
                }
            }
        }
    }

    private var growthStrip: some View {
        HStack(spacing: 0) {
            growthItem(value: "−35%", label: "贅字")
            Divider().frame(height: 34).overlay(TalkFitTheme.line)
            growthItem(value: "更穩", label: "語速")
            Divider().frame(height: 34).overlay(TalkFitTheme.line)
            growthItem(value: "3 次", label: "已練習")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 14)
        .background(TalkFitTheme.sageSoft.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("成長摘要：贅字減少百分之三十五，語速更穩，已完成三次練習")
    }

    private func growthItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(TalkFitTheme.pine)
            Text(label).font(.caption2).foregroundStyle(TalkFitTheme.ink.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
    }

    private var promptSheet: some View {
        NotebookSection(title: "今日推薦") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(TalkFitFixtures.promptTitle)
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .layoutPriority(1)
                    Spacer()
                    Text("30 秒")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TalkFitTheme.clay)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(TalkFitTheme.clay.opacity(0.12), in: Capsule())
                }
                Text(TalkFitFixtures.prompt)
                    .font(.body)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle()
                    .fill(TalkFitTheme.clay)
                    .frame(width: 66, height: 2)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct RecordingView: View {
    let model: TalkFitModel
    let round: PracticeRound

    private var timerText: String {
        let seconds = Int(model.elapsed)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        VStack(spacing: 26) {
            BrandHeader(compact: true)

            VStack(spacing: 7) {
                Text(round == .first ? "正在聽你說" : "正在重練這一段")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                Text(timerText)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel("錄音時間 \(timerText)")
            }

            WaveformView(level: model.audioLevel, time: model.elapsed)
                .frame(height: 104)
                .accessibilityLabel("即時音量波形")

            if let notice = model.fallbackNotice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.moss)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            NotebookSection(title: round == .first ? "題目" : "這次只練一句") {
                Text(round == .first ? TalkFitFixtures.prompt : (model.firstResult?.prioritySegment ?? ""))
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !model.liveTranscript.isEmpty {
                Text(model.liveTranscript)
                    .font(.footnote)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.6))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("即時逐字稿：\(model.liveTranscript)")
            } else {
                Text("不急，照自己的速度說完就好。")
                    .font(.footnote)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.55))
            }

            Spacer(minLength: 4)

            Button {
                model.stopRecording()
            } label: {
                Label("說完了，看看回饋", systemImage: "stop.fill")
            }
            .buttonStyle(PrimaryActionStyle())
            .accessibilityIdentifier("record.stop")
        }
        .talkFitPageInsets(bottom: 16)
    }
}

private struct WaveformView: View {
    let level: Float
    let time: TimeInterval

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<27, id: \.self) { index in
                let phase = sin(Double(index) * 0.72 + time * 4.5)
                let envelope = 0.48 + 0.52 * sin(Double(index) / 26 * .pi)
                let height = 12 + CGFloat(max(0.08, level)) * CGFloat((phase + 1.35) / 2.35) * 78 * envelope
                Capsule()
                    .fill(index.isMultiple(of: 6) ? TalkFitTheme.clay : TalkFitTheme.sage)
                    .frame(maxWidth: 7, minHeight: 4, idealHeight: height, maxHeight: height)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.linear(duration: 0.08), value: level)
    }
}

private struct AnalysisView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var growing = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(TalkFitTheme.sage.opacity(0.25), lineWidth: 2)
                    .frame(width: 116, height: 116)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(TalkFitTheme.moss)
                    .scaleEffect(growing ? 1.08 : 0.82)
                    .rotationEffect(.degrees(growing ? 7 : -7))
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: growing)
            Text("正在整理你的表達")
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text("找出最值得先重練的一小段")
                .font(.subheadline)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
            ProgressView()
                .tint(TalkFitTheme.moss)
                .accessibilityLabel("正在分析")
            Spacer()
        }
        .padding(.horizontal, TalkFitTheme.pageGutter)
        .onAppear { growing = true }
    }
}

private struct ReportView: View {
    let model: TalkFitModel
    let result: PracticeResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BrandHeader(compact: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(result.source.label)
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(TalkFitTheme.moss)
                    Text("先把這一段說得更直接")
                        .font(.system(.title, design: .serif, weight: .bold))
                    Text("不用一次改很多，先拿掉停頓詞，重點就會更清楚。")
                        .font(.subheadline)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.68))
                }

                NotebookSection(title: "最值得先改善") {
                    Button {
                        model.choosePrioritySegment()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Rectangle()
                                .fill(TalkFitTheme.clay)
                                .frame(width: 3)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("「\(result.prioritySegment)」")
                                    .font(.body.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                Label("點一下，立即重練", systemImage: "arrow.up.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(TalkFitTheme.clay)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("report.retry")
                }

                NotebookSection(title: "逐字稿 · 橘色是贅字") {
                    Text(result.highlightedTranscript)
                        .font(.body)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                NotebookSection(title: "這次的節奏") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(result.pace)")
                                .font(.system(.title, design: .rounded, weight: .bold))
                            Text("字／分鐘 · \(result.paceLabel)")
                                .font(.subheadline)
                                .foregroundStyle(TalkFitTheme.moss)
                            Spacer()
                            Text("\(result.durationLabel)")
                                .font(.caption)
                                .foregroundStyle(TalkFitTheme.ink.opacity(0.55))
                        }
                        PaceScale(pace: result.pace)
                        Text("贅字 \(result.fillerTotal) 個 · 穩定度 \(result.stability)%")
                            .font(.caption)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                    }
                }
            }
            .talkFitPageInsets(bottom: 118)
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                Button("重練最重要的一段") {
                    model.choosePrioritySegment()
                }
                .buttonStyle(PrimaryActionStyle())
                .accessibilityIdentifier("report.retry.bottom")
            }
        }
    }
}

private struct PaceScale: View {
    let pace: Int

    var body: some View {
        GeometryReader { geometry in
            let progress = min(1, max(0, CGFloat(pace - 110) / 190))
            ZStack(alignment: .leading) {
                Capsule().fill(TalkFitTheme.sageSoft.opacity(0.72)).frame(height: 10)
                Capsule().fill(TalkFitTheme.moss).frame(width: max(12, geometry.size.width * progress), height: 10)
                Circle()
                    .fill(TalkFitTheme.clay)
                    .frame(width: 18, height: 18)
                    .offset(x: min(geometry.size.width - 18, max(0, geometry.size.width * progress - 9)))
            }
        }
        .frame(height: 18)
        .accessibilityLabel("語速每分鐘 \(pace) 字")
    }
}

private struct RetryView: View {
    let model: TalkFitModel
    let result: PracticeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            BrandHeader(compact: true)
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("只重練這一小段")
                    .font(.system(.title, design: .serif, weight: .bold))
                Text("這次不求完美，只讓重點先出現。")
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.66))
            }

            NotebookSection(title: "原本的說法") {
                Text("「\(result.prioritySegment)」")
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "pencil.and.scribble")
                    .font(.title2)
                    .foregroundStyle(TalkFitTheme.clay)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("這次的提醒").font(.caption.weight(.bold)).foregroundStyle(TalkFitTheme.clay)
                    Text(result.coachingCue).font(.body.weight(.medium))
                }
            }
            .padding(.horizontal, 4)

            Spacer()

            Button {
                model.startRetry()
            } label: {
                Label("開始重練", systemImage: "mic.fill")
            }
            .buttonStyle(PrimaryActionStyle())
            .accessibilityIdentifier("retry.start")
        }
        .talkFitPageInsets(bottom: 16)
    }
}

private struct ComparisonView: View {
    let model: TalkFitModel
    let comparison: ComparisonResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                BrandHeader(compact: true)

                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                        Image(systemName: "leaf.fill")
                        Image(systemName: "leaf.fill")
                    }
                    .font(.title3)
                    .foregroundStyle(TalkFitTheme.sage, TalkFitTheme.moss)
                    .accessibilityHidden(true)
                    Text("這次，重點真的更快出現了")
                        .font(.system(.title, design: .serif, weight: .bold))
                    Text("你沒有重說整段，只改了一個小地方，表達就更清楚。")
                        .font(.subheadline)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.66))
                }

                NotebookSection(title: "前後比較") {
                    VStack(spacing: 14) {
                        MetricPair(
                            title: "贅字",
                            before: "\(comparison.before.fillerTotal) 個",
                            after: "\(comparison.after.fillerTotal) 個",
                            improvement: comparison.fillerImprovement > 0 ? "少了 \(comparison.fillerImprovement) 個" : "更俐落"
                        )
                        Divider().overlay(TalkFitTheme.line)
                        MetricPair(
                            title: "語速",
                            before: "\(comparison.before.pace)",
                            after: "\(comparison.after.pace)",
                            improvement: "節奏更自然"
                        )
                        Divider().overlay(TalkFitTheme.line)
                        MetricPair(
                            title: "穩定度",
                            before: "\(comparison.before.stability)%",
                            after: "\(comparison.after.stability)%",
                            improvement: "+\(comparison.stabilityImprovement)%"
                        )
                    }
                }

                NotebookSection(title: "重練後的說法") {
                    Text(comparison.after.transcript)
                        .font(.body)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("停頓詞減少，句子更有方向。")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TalkFitTheme.moss)
                }
            }
            .talkFitPageInsets(bottom: 116)
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                Button("收下這次進步") {
                    model.returnHome()
                }
                .buttonStyle(PrimaryActionStyle())
                .accessibilityIdentifier("comparison.done")
            }
        }
    }
}

#Preview("首頁") {
    ContentView()
}
