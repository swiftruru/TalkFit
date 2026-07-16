import SwiftUI

struct HomeView: View {
    let model: TalkFitModel

    @State private var presentedSheet: HomeSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                BrandHeader()
                HomeIntroduction()
                GrowthStrip()
                practiceSheet
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

    private var practiceSheet: some View {
        NotebookSection(title: "今日練習") {
            VStack(alignment: .leading, spacing: 18) {
                GardenLanguageSelector(
                    selectedLanguage: model.selectedLanguage,
                    selectLanguage: model.selectLanguage
                )

                Divider()
                    .overlay(TalkFitTheme.line)

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
                    .frame(width: 58, height: 2)
                    .accessibilityHidden(true)

                Divider()
                    .overlay(TalkFitTheme.line)

                Button(action: showFillerLibrary) {
                    HStack(spacing: 12) {
                        Image(systemName: "text.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TalkFitTheme.clay)
                            .frame(width: 34, height: 34)
                            .background(TalkFitTheme.clay.opacity(0.1), in: Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("調整贅字庫")
                                .font(.subheadline.weight(.semibold))
                            Text("目前 \(model.activeFillerWords.count) 個 · 加入自己的口頭習慣")
                                .font(.caption)
                                .foregroundStyle(TalkFitTheme.ink.opacity(0.58))
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TalkFitTheme.sage)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("調整贅字庫，目前 \(model.activeFillerWords.count) 個")
                .accessibilityHint("加入或移除自己的口頭習慣")
                .accessibilityIdentifier("home.fillers")
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

private struct GardenLanguageSelector: View {
    let selectedLanguage: PracticeLanguage
    let selectLanguage: (PracticeLanguage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("練習語言")
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(TalkFitTheme.moss)

            HStack(spacing: 10) {
                ForEach(PracticeLanguage.allCases) { language in
                    languageButton(for: language)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("練習語言")
    }

    private func languageButton(for language: PracticeLanguage) -> some View {
        let isSelected = language == selectedLanguage
        return Button {
            selectLanguage(language)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: isSelected ? "leaf.fill" : "leaf")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? TalkFitTheme.moss : TalkFitTheme.sage)
                    .accessibilityHidden(true)
                Text(language.displayName)
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? TalkFitTheme.pine : TalkFitTheme.ink.opacity(0.68))
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                isSelected
                    ? TalkFitTheme.sageSoft.opacity(0.5)
                    : TalkFitTheme.paperLight.opacity(0.36),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        isSelected ? TalkFitTheme.moss.opacity(0.34) : TalkFitTheme.line,
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .bottom) {
                if isSelected {
                    Capsule()
                        .fill(TalkFitTheme.clay)
                        .frame(width: 28, height: 2)
                        .padding(.bottom, 6)
                        .accessibilityHidden(true)
                }
            }
            .shadow(
                color: isSelected ? TalkFitTheme.ink.opacity(0.07) : .clear,
                radius: 4,
                y: 2
            )
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("使用 \(language.displayName) 練習")
        .accessibilityValue(isSelected ? "已選取" : "未選取")
        .accessibilityHint("切換語音辨識、題目與分析語言")
        .accessibilityIdentifier("home.language.\(language.rawValue)")
    }
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
