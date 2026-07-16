import SwiftUI

struct HomeView: View {
    let model: TalkFitModel

    @State private var presentedSheet: HomeSheet?

    private var languageSelection: Binding<PracticeLanguage> {
        Binding(
            get: { model.selectedLanguage },
            set: model.selectLanguage
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                BrandHeader()
                HomeIntroduction()
                GrowthStrip()
                practiceSetup
                promptSheet
                PracticeHistoryList()
            }
            .talkFitPageInsets(bottom: 132)
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                VStack(spacing: 10) {
                    Button(action: startPractice) {
                        Label("開始 \(model.selectedLanguage.displayName) 30 秒練習", systemImage: "mic.fill")
                    }
                    .buttonStyle(PrimaryActionStyle())
                    .accessibilityIdentifier("home.start")

                    Button("示範練習", action: startDemo)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.moss)
                        .accessibilityHint("不使用麥克風，以固定內容體驗完整流程")
                        .accessibilityIdentifier("home.demo")
                }
            }
        }
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .fillerLibrary:
                FillerLibraryView(model: model)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var practiceSetup: some View {
        NotebookSection(title: "練習設定") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("口說語言", selection: languageSelection) {
                    ForEach(PracticeLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("切換 Apple 語音辨識與分析使用的語言")

                Button(action: showFillerLibrary) {
                    HStack(spacing: 10) {
                        Image(systemName: "text.badge.plus")
                            .foregroundStyle(TalkFitTheme.clay)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("調整贅字庫")
                                .font(.subheadline.weight(.semibold))
                            Text("目前 \(model.activeFillerWords.count) 個 · 可加入自己的口頭習慣")
                                .font(.caption)
                                .foregroundStyle(TalkFitTheme.ink.opacity(0.58))
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TalkFitTheme.sage)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home.fillers")
            }
        }
    }

    private var promptSheet: some View {
        NotebookSection(title: "今日推薦") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(model.selectedLanguage.promptTitle)
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
                Text(model.selectedLanguage.prompt)
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

    private func showFillerLibrary() {
        presentedSheet = .fillerLibrary
    }

    private func startPractice() {
        model.startPractice()
    }

    private func startDemo() {
        model.startPractice(demo: true)
    }
}

private enum HomeSheet: String, Identifiable {
    case fillerLibrary

    var id: String { rawValue }
}

private struct HomeIntroduction: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今天，讓表達自然長出來")
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text("選一種語言，用 30 秒練習說得更清楚。")
                .font(.subheadline)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.65))
        }
    }
}

private struct GrowthStrip: View {
    var body: some View {
        HStack(spacing: 0) {
            GrowthItem(value: "−35%", label: "贅字")
            Divider().frame(height: 34).overlay(TalkFitTheme.line)
            GrowthItem(value: "更穩", label: "語速")
            Divider().frame(height: 34).overlay(TalkFitTheme.line)
            GrowthItem(value: "3 次", label: "已練習")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 14)
        .background(
            TalkFitTheme.sageSoft.opacity(0.45),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("成長摘要：贅字減少百分之三十五，語速更穩，已完成三次練習")
    }
}

private struct GrowthItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(TalkFitTheme.pine)
            Text(label).font(.caption2).foregroundStyle(TalkFitTheme.ink.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PracticeHistoryList: View {
    var body: some View {
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
}
