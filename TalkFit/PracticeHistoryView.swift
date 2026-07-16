import SwiftUI

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
