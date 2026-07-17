import AVFoundation
import Observation
import SwiftUI

struct RecordingArchiveView: View {
    let model: TalkFitModel

    @State private var filter: RecordingArchiveFilter = .all
    @State private var sessionToDelete: RecordingArchiveSessionSummary?

    private var visibleSessions: [RecordingArchiveSessionSummary] {
        model.recordingSessions.filter(filter.includes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                        Text("練習紀錄")
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .foregroundStyle(TalkFitTheme.ink)
                            .accessibilityAddTraits(.isHeader)
                        archiveSummary
                        privacyCard
                        sessionList
                    }
                    .talkFitPageInsets(bottom: 34)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(TalkFitTheme.pine)
        .alert("刪除這次練習？", isPresented: deleteConfirmationBinding) {
            Button("保留", role: .cancel) { sessionToDelete = nil }
            Button("刪除錄音", role: .destructive) {
                if let sessionToDelete {
                    model.deleteRecordingSession(id: sessionToDelete.id)
                }
                sessionToDelete = nil
            }
        } message: {
            Text("這次練習內的所有錄音都會從這台 iPhone 刪除，無法復原。")
        }
    }

    private var archiveSummary: some View {
        HStack(spacing: 10) {
            summaryMetric(
                value: "\(model.recordingSessions.count)",
                label: "練習",
                systemImage: "checkmark.seal.fill"
            )
            summaryMetric(
                value: "\(model.recordingSessions.reduce(0) { $0 + $1.attempts.count })",
                label: "錄音",
                systemImage: "waveform"
            )
            summaryMetric(
                value: compactDuration(model.recordingSessions.reduce(0) { $0 + $1.totalDuration }),
                label: "總時長",
                systemImage: "clock.fill"
            )
        }
        .accessibilityElement(children: .contain)
    }

    private func summaryMetric(value: String, label: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(TalkFitTheme.sage)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(TalkFitTheme.pine)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.caption2)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.58))
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(
            TalkFitTheme.paperLight.opacity(0.8),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TalkFitTheme.line, lineWidth: 1)
        }
    }

    private var privacyCard: some View {
        NotebookSection(title: "只留在這台 iPhone") {
            Toggle(isOn: historyEnabledBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("保存練習摘要與錄音")
                        .font(.body.weight(.semibold))
                    Text(model.isHistoryEnabled
                         ? "收下真實練習時，會保存這次的每段錄音"
                         : "目前不會新增紀錄；已保存的內容仍會保留")
                        .font(.caption)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(TalkFitTheme.moss)
            .accessibilityIdentifier("recordings.toggle")

            Label("講稿與逐字稿不會寫入紀錄；示範練習也永遠不會保存。", systemImage: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("每一次練習")
                .font(.headline)

            Picker("紀錄類型", selection: $filter) {
                ForEach(RecordingArchiveFilter.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("recordings.filter")

            if visibleSessions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(visibleSessions) { session in
                        sessionRow(session)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 13) {
            Image(systemName: filter == .all ? "waveform.badge.plus" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(TalkFitTheme.sage)
            Text(filter == .all ? "還沒有保存的錄音" : "這個分類還沒有紀錄")
                .font(.headline)
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 26)
        .padding(.vertical, 34)
        .background(
            TalkFitTheme.sageSoft.opacity(0.25),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    private func sessionRow(_ session: RecordingArchiveSessionSummary) -> some View {
        HStack(spacing: 8) {
            NavigationLink {
                RecordingSessionDetailView(model: model, session: session)
            } label: {
                HStack(spacing: 13) {
                    Image(systemName: session.kind == .shortPractice ? "quote.bubble.fill" : "doc.text.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.pine)
                        .frame(width: 42, height: 42)
                        .background(TalkFitTheme.sageSoft.opacity(0.4), in: Circle())
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 7) {
                            Text(session.typeLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(TalkFitTheme.moss)
                            Text("·")
                                .foregroundStyle(TalkFitTheme.ink.opacity(0.3))
                            Text(session.completedAt.talkFitRecordingDateLabel)
                                .font(.caption2)
                                .foregroundStyle(TalkFitTheme.ink.opacity(0.5))
                        }
                        Text(session.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TalkFitTheme.ink)
                            .lineLimit(1)
                        Text("\(session.attempts.count) 段錄音 · \(durationLabel(session.totalDuration))")
                            .font(.caption)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.58))
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TalkFitTheme.sage)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                sessionToDelete = session
            } label: {
                Image(systemName: "trash")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(TalkFitTheme.clay)
            .accessibilityLabel("刪除 \(session.title) 的所有錄音")
        }
        .padding(14)
        .background(
            TalkFitTheme.paperLight.opacity(0.78),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TalkFitTheme.line, lineWidth: 1)
        }
    }

    private var emptyMessage: String {
        if filter != .all {
            return "完成一場\(filter == .shortPractice ? "短講" : "完整講稿")練習後，就會出現在這裡。"
        }
        return model.isHistoryEnabled
            ? "完成一次真實練習並選擇收下，之後就能在這裡回聽。"
            : "先開啟保存；之後收下的真實練習才會留在裝置中。"
    }

    private var historyEnabledBinding: Binding<Bool> {
        Binding(
            get: { model.isHistoryEnabled },
            set: model.setHistoryEnabled
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { sessionToDelete != nil },
            set: { isPresented in
                if !isPresented { sessionToDelete = nil }
            }
        )
    }
}

private struct RecordingSessionDetailView: View {
    let model: TalkFitModel
    let session: RecordingArchiveSessionSummary

    @Environment(\.dismiss) private var dismiss
    @State private var playback = RecordingPlaybackController()
    @State private var showsDeleteConfirmation = false

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                    sessionHeader
                    VStack(alignment: .leading, spacing: 13) {
                        Text("這次的錄音")
                            .font(.headline)
                        ForEach(session.attempts) { attempt in
                            RecordingAttemptCard(
                                attempt: attempt,
                                sessionKind: session.kind,
                                playback: playback
                            )
                        }
                    }
                }
                .talkFitPageInsets(bottom: 34)
            }
        }
        .navigationTitle(session.kind.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .foregroundStyle(TalkFitTheme.clay)
                .accessibilityLabel("刪除這次練習")
            }
        }
        .alert("刪除這次練習？", isPresented: $showsDeleteConfirmation) {
            Button("保留", role: .cancel) {}
            Button("刪除錄音", role: .destructive) {
                playback.stop()
                model.deleteRecordingSession(id: session.id)
                dismiss()
            }
        } message: {
            Text("這次練習內的 \(session.attempts.count) 段錄音都會刪除，無法復原。")
        }
        .onDisappear { playback.stop() }
    }

    private var sessionHeader: some View {
        NotebookSection(title: session.typeLabel) {
            VStack(alignment: .leading, spacing: 10) {
                Text(session.title)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                Label(session.completedAt.formatted(
                    Date.FormatStyle(date: .long, time: .shortened)
                        .locale(Locale(identifier: "zh-Hant-TW"))
                ), systemImage: "calendar")
                Label("\(session.attempts.count) 段錄音 · \(durationLabel(session.totalDuration))", systemImage: "waveform")
                Label("只保存在這台 iPhone", systemImage: "lock.fill")
            }
            .font(.subheadline)
            .foregroundStyle(TalkFitTheme.ink.opacity(0.68))
        }
    }
}

private struct RecordingAttemptCard: View {
    let attempt: RecordingArchiveAttemptSummary
    let sessionKind: RecordingArchiveSessionKind
    let playback: RecordingPlaybackController

    private var isActive: Bool { playback.activeAttemptID == attempt.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 13) {
                Button {
                    playback.toggle(attempt)
                } label: {
                    Image(systemName: isActive && playback.isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(attempt.audioIsAvailable ? TalkFitTheme.pine : TalkFitTheme.sage, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!attempt.audioIsAvailable)
                .accessibilityLabel(isActive && playback.isPlaying ? "暫停" : "播放 \(attemptTitle)")

                VStack(alignment: .leading, spacing: 4) {
                    Text(attemptTitle)
                        .font(.subheadline.weight(.semibold))
                    Text("\(durationLabel(attempt.duration)) · \(attempt.capturedAt.talkFitRecordingTimeLabel)")
                        .font(.caption)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.55))
                }
                Spacer()
                if !attempt.audioIsAvailable {
                    Text("音檔遺失")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(TalkFitTheme.clay)
                }
            }

            ProgressView(value: isActive ? playback.progress : 0)
                .tint(TalkFitTheme.moss)

            HStack(spacing: 12) {
                attemptMetric(label: "贅字", value: attempt.fillerCount.map { "\($0) 個" } ?? "—")
                attemptMetric(label: "語速", value: attempt.pace.map(String.init) ?? "—")
                attemptMetric(label: "穩定度", value: attempt.stability.map { "\($0)%" } ?? "—")
            }

            if isActive, let message = playback.failureMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.clay)
            }
        }
        .padding(17)
        .background(
            TalkFitTheme.paperLight.opacity(0.8),
            in: RoundedRectangle(cornerRadius: 21, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(isActive ? TalkFitTheme.moss.opacity(0.55) : TalkFitTheme.line, lineWidth: isActive ? 1.5 : 1)
        }
    }

    private var attemptTitle: String {
        switch (sessionKind, attempt.kind) {
        case (.shortPractice, .initial):
            "第一次短講"
        case (.shortPractice, .fullRetry):
            "第 \(attempt.sequence + 1) 次短講"
        case (.scriptPractice, .initial):
            "完整講稿"
        default:
            attempt.displayName
        }
    }

    private func attemptMetric(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(TalkFitTheme.pine)
            Text(label)
                .font(.caption2)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.48))
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
@Observable
private final class RecordingPlaybackController {
    private var player: AVAudioPlayer?
    private var progressTask: Task<Void, Never>?

    var activeAttemptID: UUID?
    var isPlaying = false
    var progress = 0.0
    var failureMessage: String?

    func toggle(_ attempt: RecordingArchiveAttemptSummary) {
        if activeAttemptID == attempt.id, let player {
            if player.isPlaying {
                player.pause()
                isPlaying = false
                progressTask?.cancel()
            } else {
                player.play()
                isPlaying = true
                startProgressUpdates()
            }
            return
        }

        stop()
        activeAttemptID = attempt.id
        guard attempt.audioIsAvailable else {
            failureMessage = "找不到這段錄音。"
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: attempt.audioURL)
            player.prepareToPlay()
            guard player.play() else {
                failureMessage = "目前無法播放這段錄音。"
                return
            }
            self.player = player
            isPlaying = true
            failureMessage = nil
            startProgressUpdates()
        } catch {
            isPlaying = false
            failureMessage = "目前無法播放這段錄音。"
        }
    }

    func stop() {
        progressTask?.cancel()
        progressTask = nil
        player?.stop()
        player = nil
        activeAttemptID = nil
        isPlaying = false
        progress = 0
        failureMessage = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startProgressUpdates() {
        progressTask?.cancel()
        progressTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let player = self.player else { return }
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
                if !player.isPlaying {
                    self.isPlaying = false
                    self.progress = 1
                    self.progressTask = nil
                    return
                }
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }
}

private enum RecordingArchiveFilter: String, CaseIterable, Identifiable {
    case all
    case shortPractice
    case scriptPractice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .shortPractice: "短講"
        case .scriptPractice: "講稿"
        }
    }

    func includes(_ session: RecordingArchiveSessionSummary) -> Bool {
        switch self {
        case .all: true
        case .shortPractice: session.kind == .shortPractice
        case .scriptPractice: session.kind == .scriptPractice
        }
    }
}

private extension Date {
    var talkFitRecordingDateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "今天" }
        if calendar.isDateInYesterday(self) { return "昨天" }
        return formatted(
            Date.FormatStyle(date: .numeric, time: .omitted)
                .locale(Locale(identifier: "zh-Hant-TW"))
        )
    }

    var talkFitRecordingTimeLabel: String {
        formatted(
            Date.FormatStyle(date: .omitted, time: .shortened)
                .locale(Locale(identifier: "zh-Hant-TW"))
        )
    }
}

private func durationLabel(_ duration: TimeInterval) -> String {
    let seconds = max(0, Int(duration.rounded()))
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
}

private func compactDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration / 60)
    if minutes >= 60 {
        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
    return "\(minutes) 分"
}

#Preview("錄音紀錄") {
    RecordingArchiveView(model: TalkFitModel())
}
