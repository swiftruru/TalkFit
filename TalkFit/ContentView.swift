import SwiftUI

struct ContentView: View {
    let model: TalkFitModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PaperBackground()
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(TalkFitTheme.pine)
        .foregroundStyle(TalkFitTheme.ink)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.stage)
        .onOpenURL(perform: handleDeepLink)
    }

    @ViewBuilder
    private var screen: some View {
        switch model.stage {
        case .home:
            HomeView(model: model)
        case .recording(let round):
            RecordingView(model: model, round: round)
        case .analyzing(let round):
            AnalysisView(model: model, round: round)
        case .recognitionIssue(let round, let issue):
            RecognitionIssueView(model: model, round: round, issue: issue)
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

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "talkfit",
              url.host == "practice",
              url.path == "/start",
              model.stage == .home else {
            return
        }
        model.startPractice()
    }
}

private struct RecognitionIssueView: View {
    let model: TalkFitModel
    let round: PracticeRound
    let issue: RecognitionIssue

    var body: some View {
        VStack(spacing: 0) {
            GardenNavigationHeader(
                destination: round == .first ? "首頁" : "回饋",
                prompt: nil
            ) {
                if round == .first {
                    model.returnHome()
                } else {
                    model.returnToReport()
                }
            }
            .padding(.horizontal, TalkFitTheme.pageGutter)
            .padding(.top, TalkFitTheme.pageTop)

            ScrollView {
                VStack(spacing: 22) {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(TalkFitTheme.sageSoft.opacity(0.45))
                            .frame(width: 112, height: 112)
                        Image(systemName: "waveform")
                            .font(.system(size: 45, weight: .medium))
                            .foregroundStyle(TalkFitTheme.pine)
                            .frame(width: 112, height: 112)
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(TalkFitTheme.clay)
                            .background(TalkFitTheme.paperLight, in: Circle())
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        Text(issue.title)
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .multilineTextAlignment(.center)
                        Text(issue.message)
                            .font(.body)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.68))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    NotebookSection(title: "你的內容仍然是你的") {
                        Text("TalkFit 不會拿範例冒充這次錄音。你可以重新錄音；若只是想確認完整流程，也能由你主動改用示範練習。")
                            .font(.subheadline)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.76))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, TalkFitTheme.pageGutter)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }

            BottomActionBar {
                VStack(spacing: 12) {
                    Button {
                        model.retryAfterRecognitionIssue(round: round)
                    } label: {
                        Label(
                            round == .first ? "重新錄音" : "重新重練這一段",
                            systemImage: "mic.fill"
                        )
                    }
                    .buttonStyle(PrimaryActionStyle())
                    .accessibilityIdentifier("recognition.retry")

                    Button {
                        model.useDemoAfterRecognitionIssue(round: round)
                    } label: {
                        Label("改用示範練習", systemImage: "leaf.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TalkFitTheme.pine)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(TalkFitTheme.paperLight.opacity(0.76), in: Capsule())
                            .overlay { Capsule().stroke(TalkFitTheme.line, lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("recognition.use-demo")
                }
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
            GardenNavigationHeader(
                destination: round == .first ? "首頁" : "重練",
                prompt: leavePrompt
            ) {
                if round == .first {
                    model.returnHome()
                } else {
                    model.cancelRetryAndReturnToPreparation()
                }
            }

            VStack(spacing: 7) {
                Text(recordingTitle)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                Text(timerText)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel("錄音時間 \(timerText)")
            }

            WaveformView(
                level: model.audioLevel,
                time: model.elapsed,
                feedback: model.liveSentencePaces.last,
                language: model.selectedLanguage
            )

            if let notice = model.fallbackNotice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.moss)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            recordingTextSection

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

    private var leavePrompt: GardenLeavePrompt {
        if round == .first {
            GardenLeavePrompt(
                title: "要離開這次錄音嗎？",
                message: "目前錄下的內容不會保留。",
                leaveTitle: "離開練習",
                stayTitle: "繼續錄音"
            )
        } else {
            GardenLeavePrompt(
                title: "要放棄這次重練嗎？",
                message: "這次重練的錄音不會保留，但原本的練習回饋還在。",
                leaveTitle: "放棄這次重練",
                stayTitle: "繼續錄音"
            )
        }
    }

    private var recordingTitle: String {
        if round == .retry { return "正在重練這一段" }
        return model.usesScriptPractice ? "正在錄完整講稿" : "正在短講練習"
    }

    @ViewBuilder
    private var recordingTextSection: some View {
        if let session = model.scriptPractice {
            if round == .retry, let paragraph = model.retryParagraph {
                ScriptRecordingText(
                    title: "講稿第 \(paragraph.number) 段 · 本次只練這一段",
                    paragraphs: [paragraph]
                )
            } else {
                ScriptRecordingText(
                    title: "完整講稿 · \(session.paragraphs.count) 段",
                    paragraphs: session.paragraphs
                )
            }
        } else if round == .retry {
            RecordingReferenceText(
                title: "這次重練的句子",
                text: AttributedString(model.retryPrompt)
            )
        } else {
            let style = model.referenceScriptStyle
            RecordingReferenceText(
                title: "\(model.selectedContext.shortName)範例講稿 · \(style.title)",
                text: style.displayText(
                    model.referenceScript,
                    fillerWords: model.activeFillerWords,
                    language: model.selectedLanguage
                ),
                style: style,
                selectStyle: { model.referenceScriptStyle = $0 }
            )
        }
    }
}

private struct ScriptRecordingText: View {
    let title: String
    let paragraphs: [ScriptParagraph]

    var body: some View {
        NotebookSection(title: title) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(paragraphs) { paragraph in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(paragraph.number)")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(TalkFitTheme.moss)
                                .frame(width: 24, height: 24)
                                .background(TalkFitTheme.sageSoft.opacity(0.42), in: Circle())
                                .accessibilityHidden(true)
                            Text(paragraph.text)
                                .font(.subheadline.weight(.medium))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 82, maxHeight: 164)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(paragraphs.map(\.text).joined(separator: " "))")
    }
}

private struct RecordingReferenceText: View {
    let title: String
    let text: AttributedString
    /// When set, the card offers a switch between the two script versions.
    var style: ReferenceScriptStyle?
    var selectStyle: (ReferenceScriptStyle) -> Void = { _ in }

    var body: some View {
        NotebookSection(title: title) {
            VStack(alignment: .leading, spacing: 12) {
                if let style {
                    ReferenceScriptStyleSelector(
                        selection: style,
                        compact: true,
                        select: selectStyle
                    )
                }
                ScrollView {
                    Text(text)
                        .font(.body.weight(.medium))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("\(title)：\(String(text.characters))")
                }
                .frame(minHeight: 82, maxHeight: 176)
            }
        }
    }
}

private struct WaveformView: View {
    let level: Float
    let time: TimeInterval
    let feedback: SentencePaceFeedback?
    let language: PracticeLanguage

    private var paceState: PaceState? { feedback?.state }

    private var accentColor: Color {
        paceState?.recordingColor ?? TalkFitTheme.sage
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 4) {
                ForEach(0..<27, id: \.self) { index in
                    let phase = sin(Double(index) * 0.72 + time * 4.5)
                    let envelope = 0.48 + 0.52 * sin(Double(index) / 26 * .pi)
                    let height = 12 + CGFloat(max(0.08, level)) * CGFloat((phase + 1.35) / 2.35) * 58 * envelope
                    Capsule()
                        .fill(accentColor.opacity(index.isMultiple(of: 6) ? 1 : 0.72))
                        .frame(maxWidth: 7, minHeight: 4, idealHeight: height, maxHeight: height)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 66)

            paceSummary
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            accentColor.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.22), lineWidth: 1)
        }
        .animation(.linear(duration: 0.08), value: level)
        .animation(.easeInOut(duration: 0.2), value: paceState)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private var paceSummary: some View {
        if let feedback {
            HStack(spacing: 8) {
                Image(systemName: feedback.state.recordingSymbol)
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)

                Text("最新一句")
                    .font(.caption.weight(.semibold))

                Text("\(feedback.pace) \(language.paceUnit)")
                    .font(.caption.weight(.bold).monospacedDigit())

                Spacer(minLength: 4)

                Text(feedback.state.recordingLabel)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(accentColor.opacity(0.12), in: Capsule())
            }
            .foregroundStyle(accentColor)
        } else {
            HStack(spacing: 7) {
                Image(systemName: "waveform")
                    .accessibilityHidden(true)
                Text("說完一句後顯示語速")
                Spacer(minLength: 0)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(TalkFitTheme.ink.opacity(0.56))
        }
    }

    private var accessibilitySummary: String {
        guard let feedback else {
            return "即時音量波形，說完一句後顯示語速"
        }
        return "即時音量波形，最新一句語速 \(feedback.pace) \(language.paceUnit)，\(feedback.state.recordingLabel)"
    }
}

private extension PaceState {
    var recordingColor: Color {
        switch self {
        case .slow: TalkFitTheme.paceSlow
        case .steady: TalkFitTheme.paceNormal
        case .fast: TalkFitTheme.paceFast
        }
    }

    var recordingLabel: String {
        switch self {
        case .slow: "太慢"
        case .steady: "正常"
        case .fast: "太快"
        }
    }

    var recordingSymbol: String {
        switch self {
        case .slow: "arrow.down"
        case .steady: "checkmark"
        case .fast: "arrow.up"
        }
    }
}

private struct AnalysisView: View {
    let model: TalkFitModel
    let round: PracticeRound

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var growing = false

    var body: some View {
        VStack(spacing: 0) {
            GardenNavigationHeader(
                destination: round == .first ? "首頁" : "重練",
                prompt: leavePrompt,
                confirmationDidChange: model.setAnalysisPaused
            ) {
                if round == .first {
                    model.returnHome()
                } else {
                    model.cancelRetryAndReturnToPreparation()
                }
            }

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
                Text(analysisMessage)
                    .font(.subheadline)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                ProgressView()
                    .tint(TalkFitTheme.moss)
                    .accessibilityLabel("正在分析")
                Spacer()
            }
        }
        .talkFitPageInsets(bottom: 16)
        .onAppear { growing = true }
    }

    private var leavePrompt: GardenLeavePrompt {
        GardenLeavePrompt(
            title: round == .first ? "停止整理並離開嗎？" : "停止整理這次重練嗎？",
            message: round == .first
                ? "剛完成的錄音與分析結果不會保留。"
                : "這次重練結果不會保留，但原本的練習回饋還在。",
            leaveTitle: round == .first ? "離開練習" : "放棄這次重練",
            stayTitle: "繼續整理"
        )
    }

    private var analysisMessage: String {
        if round == .first, let scriptPractice = model.scriptPractice {
            return "正在整理 \(scriptPractice.paragraphs.count) 段講稿的個別建議"
        }
        return "整理一個最值得參考的小建議"
    }
}

private struct ReportView: View {
    let model: TalkFitModel
    let result: PracticeResult

    @Bindable private var bindableModel: TalkFitModel

    init(model: TalkFitModel, result: PracticeResult) {
        self.model = model
        self.result = result
        _bindableModel = Bindable(model)
    }

    private var isFullScript: Bool {
        result.scriptReference?.isWholeScript == true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GardenNavigationHeader(
                    destination: "首頁",
                    prompt: GardenLeavePrompt(
                        title: "要離開這份回饋嗎？",
                        message: "這次練習尚未收下，返回首頁後回饋不會保留。",
                        leaveTitle: "返回首頁",
                        stayTitle: "繼續查看"
                    )
                ) {
                    model.returnHome()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(result.practiceTitle) · \(result.source.label)")
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(TalkFitTheme.moss)
                    Text(isFullScript ? "講稿練習完成" : "這次練習完成")
                        .font(.system(.title, design: .serif, weight: .bold))
                    Text(
                        isFullScript
                            ? "你可以收下整次練習，也可以只挑一段再說一次。"
                            : "先看看一個小建議；要不要再錄一次，由你決定。"
                    )
                        .font(.subheadline)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.68))
                }

                ReportMetricsStrip(result: result, isFullScript: isFullScript)

                if let recordingURL = model.reportRecordingURL {
                    ResultRecordingPlaybackSection(
                        title: "回放剛剛的錄音",
                        helperText: "播放剛才錄下的原音，方便對照逐字稿與建議。",
                        audioURL: recordingURL,
                        duration: result.duration,
                        accessibilityIdentifier: "report.playback"
                    )
                }

                if isFullScript {
                    ScriptParagraphReviewSection(
                        feedback: model.scriptParagraphFeedback,
                        choose: model.chooseScriptParagraph
                    )
                } else {
                    NotebookSection(title: "TALKFIT 的建議 · 可略過") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Rectangle()
                                    .fill(TalkFitTheme.clay)
                                    .frame(width: 3)
                                Text("「\(result.prioritySegment)」")
                                    .font(.body.weight(.semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Label(result.coachingCue, systemImage: "leaf.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(TalkFitTheme.moss)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if let scriptComparison = result.scriptComparison, !isFullScript {
                    ScriptComparisonSection(comparison: scriptComparison)
                }

                NotebookSection(title: "錄音完成後的逐字稿 · 橘色是文字中的贅字") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(result.highlightedTranscript)
                            .font(.body)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)

                        if !result.additionalFillerEvidence.isEmpty {
                            Divider().overlay(TalkFitTheme.line)
                            VStack(alignment: .leading, spacing: 10) {
                                Label("聲音裡還聽到", systemImage: "waveform")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(TalkFitTheme.clay)
                                VStack(alignment: .leading, spacing: 7) {
                                    ForEach(result.additionalFillerEvidence) { event in
                                        HStack(spacing: 8) {
                                            Text(event.word)
                                                .font(.caption.weight(.bold))
                                            Text(event.timestampLabel)
                                                .font(.caption.monospacedDigit())
                                            Spacer(minLength: 0)
                                        }
                                        .foregroundStyle(TalkFitTheme.clay)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(TalkFitTheme.clay.opacity(0.1), in: Capsule())
                                    }
                                }
                                Text("逐字稿省略的語氣聲，也已計入這次練習。")
                                    .font(.caption)
                                    .foregroundStyle(TalkFitTheme.ink.opacity(0.6))
                            }
                        }
                    }
                }

                NotebookSection(title: "這次的節奏") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(result.pace)")
                                .font(.system(.title, design: .rounded, weight: .bold))
                            Text("\(result.paceUnit) · \(result.paceLabel)")
                                .font(.subheadline)
                                .foregroundStyle(TalkFitTheme.moss)
                            Spacer()
                            Text("\(result.durationLabel)")
                                .font(.caption)
                                .foregroundStyle(TalkFitTheme.ink.opacity(0.55))
                        }
                        PaceScale(
                            pace: result.pace,
                            language: result.language,
                            context: result.context
                        )
                        RhythmSummaryNote(summary: result.rhythmSummary)
                        Text("贅字 \(result.fillerTotal) 個 · 穩定度 \(result.stability)%")
                            .font(.caption)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                    }
                }

                if !result.sentencePaces.isEmpty {
                    NotebookSection(title: "逐句語速建議") {
                        SentencePaceList(
                            feedback: result.sentencePaces,
                            language: result.language
                        )
                    }
                }
            }
            .talkFitPageInsets(bottom: isFullScript ? 116 : 132)
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                if isFullScript {
                    Button("收下整次進步") {
                        model.acceptResult()
                    }
                    .buttonStyle(PrimaryActionStyle())
                    .accessibilityIdentifier("report.done")
                } else {
                    HStack(spacing: 10) {
                        Button("重錄這一段") {
                            model.choosePrioritySegment()
                        }
                        .buttonStyle(SecondaryActionStyle())
                        .accessibilityIdentifier("report.retry.bottom")

                        Button("收下這次進步") {
                            model.acceptResult()
                        }
                        .buttonStyle(PrimaryActionStyle())
                        .accessibilityIdentifier("report.done")
                    }
                }
            }
        }
        .alert("要把進步留在這台 iPhone 嗎？", isPresented: $bindableModel.isHistoryChoicePresented) {
            Button("暫時不要") {
                model.declineHistoryAndFinish()
            }
            Button("開啟並保存") {
                model.enableHistoryAndSave()
            }
            Button("留在回饋頁", role: .cancel) {}
        } message: {
            Text("保存日期、語言、摘要指標、真實錄音與辨識逐字稿；不保存你貼上的講稿或贅字時間戳。資料只留在這台 iPhone，之後可隨時關閉或刪除。")
        }
    }
}

private struct ResultRecordingPlaybackSection: View {
    let title: String
    let helperText: String
    let audioURL: URL
    let duration: TimeInterval
    let accessibilityIdentifier: String

    @State private var playback = AudioPlaybackController()

    private var isActive: Bool {
        playback.activeURL == audioURL
    }

    var body: some View {
        NotebookSection(title: title) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 13) {
                    Button {
                        playback.toggle(url: audioURL)
                    } label: {
                        Image(systemName: isActive && playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(TalkFitTheme.pine, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isActive && playback.isPlaying ? "暫停剛剛的錄音" : "播放剛剛的錄音")
                    .accessibilityIdentifier(accessibilityIdentifier)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isActive && playback.isPlaying ? "正在播放" : "聽聽剛才怎麼說")
                            .font(.subheadline.weight(.semibold))
                        Text(timeSummary)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.56))
                    }
                    Spacer(minLength: 0)
                }

                ProgressView(value: isActive ? playback.progress : 0)
                    .tint(TalkFitTheme.moss)

                Text(helperText)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)

                if isActive, let failureMessage = playback.failureMessage {
                    Text(failureMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.clay)
                }
            }
        }
        .onDisappear {
            playback.stop()
        }
    }

    private var timeSummary: String {
        let current = isActive ? playback.currentTime : 0
        let total = isActive && playback.duration > 0 ? playback.duration : duration
        return "\(playbackTimeLabel(current)) / \(playbackTimeLabel(total))"
    }

    private func playbackTimeLabel(_ value: TimeInterval) -> String {
        let seconds = max(0, Int(value.rounded()))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct ReportMetricsStrip: View {
    let result: PracticeResult
    let isFullScript: Bool

    var body: some View {
        HStack(spacing: 10) {
            if isFullScript {
                metric(
                    title: "內容涵蓋",
                    value: "\(result.scriptComparison?.coverage ?? 0)%",
                    systemImage: "doc.text"
                )
            } else {
                metric(title: "贅字", value: "\(result.fillerTotal) 個", systemImage: "quote.bubble")
            }
            metric(
                title: isFullScript ? "贅字" : "語速",
                value: isFullScript ? "\(result.fillerTotal) 個" : "\(result.pace)",
                systemImage: isFullScript ? "quote.bubble" : "metronome"
            )
            metric(title: "穩定度", value: "\(result.stability)%", systemImage: "waveform.path")
        }
        .accessibilityElement(children: .contain)
    }

    private func metric(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(TalkFitTheme.clay)
                .accessibilityHidden(true)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(TalkFitTheme.pine)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TalkFitTheme.ink.opacity(0.58))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(12)
        .background(
            TalkFitTheme.paperLight.opacity(0.82),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TalkFitTheme.line, lineWidth: 1)
        }
    }
}

private struct ScriptParagraphReviewSection: View {
    let feedback: [ScriptParagraphFeedback]
    let choose: (ScriptParagraph) -> Void

    var body: some View {
        NotebookSection(title: "選一段再練 · 可略過") {
            VStack(spacing: 14) {
                ForEach(feedback) { item in
                    Button {
                        choose(item.paragraph)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text("\(item.paragraph.number)")
                                    .font(.caption.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(TalkFitTheme.pine, in: Circle())
                                Text(item.paragraph.text)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TalkFitTheme.ink)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }

                            Text(item.suggestion)
                                .font(.caption)
                                .foregroundStyle(TalkFitTheme.ink.opacity(0.66))
                                .fixedSize(horizontal: false, vertical: true)

                            HStack {
                                Text("內容涵蓋 \(item.comparison.coverage)%")
                                    .font(.caption2.weight(.bold).monospacedDigit())
                                    .foregroundStyle(TalkFitTheme.moss)
                                Spacer()
                                Label("重錄這一段", systemImage: "mic.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(TalkFitTheme.clay)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(15)
                        .background(
                            TalkFitTheme.sageSoft.opacity(0.22),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(TalkFitTheme.moss.opacity(0.22), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("report.script.retry.\(item.paragraph.number)")
                }
            }

            Label("選取後會進入短講模式，只錄你選的那一段。", systemImage: "arrow.turn.down.right")
                .font(.caption)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ScriptComparisonSection: View {
    let comparison: ScriptSpeechComparison

    var body: some View {
        NotebookSection(title: "講稿對照 · 不要求逐字背誦") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("內容涵蓋")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TalkFitTheme.moss)
                        Text("\(comparison.coverage)%")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(TalkFitTheme.pine)
                    }
                    Spacer()
                    Image(systemName: comparison.coverage >= 85 ? "leaf.fill" : "leaf")
                        .font(.title2)
                        .foregroundStyle(TalkFitTheme.sage)
                        .accessibilityHidden(true)
                }

                ProgressView(value: Double(comparison.coverage), total: 100)
                    .tint(TalkFitTheme.moss)
                    .accessibilityLabel("講稿內容涵蓋百分比")
                    .accessibilityValue("\(comparison.coverage)%")

                Text(comparison.summary)
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                if !comparison.missingKeywords.isEmpty {
                    Divider().overlay(TalkFitTheme.line)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("可以補回的關鍵詞")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.58))
                        ForEach(comparison.missingKeywords, id: \.self) { keyword in
                            Label(keyword, systemImage: "plus.circle")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TalkFitTheme.clay)
                        }
                    }
                }

                DisclosureGroup("查看這次的講稿段落") {
                    Text(comparison.reference)
                        .font(.footnote)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.68))
                        .lineSpacing(4)
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.caption.weight(.semibold))
                .tint(TalkFitTheme.moss)
            }
        }
        .accessibilityIdentifier("report.script-comparison")
    }
}

private struct RetryView: View {
    let model: TalkFitModel
    let result: PracticeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            GardenNavigationHeader(destination: "回饋", prompt: nil) {
                model.returnToReport()
            }
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("只重練這一小段")
                    .font(.system(.title, design: .serif, weight: .bold))
                Text("這次不求完美，只讓重點先出現。")
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.66))
            }

            NotebookSection(title: "原本的說法") {
                Text("「\(model.retryPrompt)」")
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
                    Text(model.retryCoachingCue).font(.body.weight(.medium))
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

    @Bindable private var bindableModel: TalkFitModel

    init(model: TalkFitModel, comparison: ComparisonResult) {
        self.model = model
        self.comparison = comparison
        _bindableModel = Bindable(model)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                GardenNavigationHeader(
                    destination: "原始回饋",
                    prompt: GardenLeavePrompt(
                        title: "返回原始回饋嗎？",
                        message: "這次前後比較會離開畫面；你仍可以從原始回饋再次重練。",
                        leaveTitle: "返回原始回饋",
                        stayTitle: "留在比較頁"
                    )
                ) {
                    model.returnToReport()
                }

                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                        Image(systemName: "leaf.fill")
                        Image(systemName: "leaf.fill")
                    }
                    .font(.title3)
                    .foregroundStyle(TalkFitTheme.sage, TalkFitTheme.moss)
                    .accessibilityHidden(true)
                    Text("這一段練完了")
                        .font(.system(.title, design: .serif, weight: .bold))
                    Text("看看前後差異，再決定要收下進步，或把同一段再錄一次。")
                        .font(.subheadline)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.66))
                }

                if let recordingURL = model.comparisonRecordingURL {
                    ResultRecordingPlaybackSection(
                        title: "回放這次重錄",
                        helperText: "先聽一次重錄內容，再查看前後差異。",
                        audioURL: recordingURL,
                        duration: comparison.after.duration,
                        accessibilityIdentifier: "comparison.playback"
                    )
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
                            improvement: comparison.rhythmImprovementLabel
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
                HStack(spacing: 10) {
                    Button("再錄這一段") {
                        model.retryComparisonSegment()
                    }
                    .buttonStyle(SecondaryActionStyle())
                    .accessibilityIdentifier("comparison.retry")

                    Button("收下這次進步") {
                        model.acceptComparison()
                    }
                    .buttonStyle(PrimaryActionStyle())
                    .accessibilityIdentifier("comparison.done")
                }
            }
        }
        .alert("要把進步留在這台 iPhone 嗎？", isPresented: $bindableModel.isHistoryChoicePresented) {
            Button("暫時不要") {
                model.declineHistoryAndFinish()
            }
            Button("開啟並保存") {
                model.enableHistoryAndSave()
            }
            Button("留在比較頁", role: .cancel) {}
        } message: {
            Text("保存日期、語言、前後指標、真實錄音與辨識逐字稿；不保存你貼上的講稿或贅字時間戳。資料只留在這台 iPhone，之後可隨時關閉或刪除。")
        }
    }
}

#Preview("首頁") {
    ContentView(model: TalkFitModel())
}
