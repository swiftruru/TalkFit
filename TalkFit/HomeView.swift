import SwiftUI

struct HomeView: View {
    let model: TalkFitModel

    @State private var presentedSheet: HomeSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                BrandHeader()
                HomeIntroduction()
                GrowthStrip(model: model)
                practiceSheet
            }
            .talkFitPageInsets(bottom: 132)
        }
        .safeAreaInset(edge: .bottom) {
            BottomActionBar {
                VStack(spacing: 10) {
                    Button(action: startPractice) {
                        Label(startButtonTitle, systemImage: "mic.fill")
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
            case .scriptPractice:
                ScriptPracticeView(model: model) {
                    presentedSheet = nil
                }
                .presentationDetents([.large])
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

                GardenContextSelector(
                    selectedContext: model.selectedContext,
                    selectContext: model.selectContext
                )

                Divider()
                    .overlay(TalkFitTheme.line)

                HStack(alignment: .top) {
                    Text(model.activePromptTitle)
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .layoutPriority(1)
                    Spacer()
                    Text(model.scriptPractice.map { "\($0.paragraphs.count) 段" } ?? "30 秒")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TalkFitTheme.clay)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(TalkFitTheme.clay.opacity(0.12), in: Capsule())
                }
                Text(
                    model.usesScriptPractice
                        ? "先完整說完講稿；錄完後可以查看每一段的建議，再挑一段加強。"
                        : model.activePrompt
                )
                    .font(.body)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                let comfortablePace = model.selectedContext.comfortablePace(
                    for: model.selectedLanguage
                )
                Label(
                    "舒服語速 \(comfortablePace.lowerBound)–\(comfortablePace.upperBound) \(model.selectedLanguage.paceUnit)",
                    systemImage: "metronome"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(TalkFitTheme.moss)

                Rectangle()
                    .fill(TalkFitTheme.clay)
                    .frame(width: 58, height: 2)
                    .accessibilityHidden(true)

                Divider()
                    .overlay(TalkFitTheme.line)

                scriptPracticeRow
            }
        }
    }

    private func showScriptPractice() {
        presentedSheet = .scriptPractice
    }

    private func startPractice() {
        model.startPractice()
    }

    private func startDemo() {
        model.startPractice(demo: true)
    }

    private var startButtonTitle: String {
        if model.scriptPractice != nil {
            return "開始完整講稿練習"
        }
        return model.selectedLanguage == .english
            ? "開始 English・\(model.selectedContext.shortName)練習"
            : "開始中文・\(model.selectedContext.shortName)練習"
    }

    @ViewBuilder
    private var scriptPracticeRow: some View {
        if let session = model.scriptPractice {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.clay)
                        .frame(width: 34, height: 34)
                        .background(TalkFitTheme.clay.opacity(0.1), in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("完整講稿 · \(session.paragraphs.count) 段")
                            .font(.subheadline.weight(.semibold))
                        Text(session.fullText)
                            .font(.caption)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                            .lineLimit(3)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 12) {
                    Button("編輯講稿", action: showScriptPractice)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TalkFitTheme.pine)
                        .frame(minHeight: 44)
                    Spacer()
                    Button("改回情境題目", action: model.clearScriptPractice)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.clay)
                        .frame(minHeight: 44)
                }
            }
            .accessibilityElement(children: .contain)
        } else {
            Button(action: showScriptPractice) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.clay)
                        .frame(width: 34, height: 34)
                        .background(TalkFitTheme.clay.opacity(0.1), in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("練自己的講稿")
                            .font(.subheadline.weight(.semibold))
                        Text("先完整錄一次，再逐段查看建議")
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
            .accessibilityHint("貼上完整講稿，錄完後可逐段重練")
            .accessibilityIdentifier("home.script")
        }
    }
}

private enum HomeSheet: String, Identifiable {
    case scriptPractice

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

private struct GardenContextSelector: View {
    let selectedContext: PracticeContext
    let selectContext: (PracticeContext) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("練習情境")
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(TalkFitTheme.moss)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PracticeContext.allCases) { context in
                        contextButton(for: context)
                    }
                }
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("練習情境")
    }

    private func contextButton(for context: PracticeContext) -> some View {
        let isSelected = context == selectedContext
        return Button {
            selectContext(context)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: context.systemImage)
                    .font(.caption.weight(.semibold))
                    .accessibilityHidden(true)
                Text(context.shortName)
                    .font(.caption.weight(isSelected ? .bold : .semibold))
            }
            .foregroundStyle(isSelected ? TalkFitTheme.pine : TalkFitTheme.ink.opacity(0.62))
            .padding(.horizontal, 12)
            .frame(minHeight: 40)
            .background(
                isSelected
                    ? TalkFitTheme.sageSoft.opacity(0.52)
                    : TalkFitTheme.paperLight.opacity(0.34),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        isSelected ? TalkFitTheme.moss.opacity(0.4) : TalkFitTheme.line,
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .bottom) {
                if isSelected {
                    Circle()
                        .fill(TalkFitTheme.clay)
                        .frame(width: 4, height: 4)
                        .padding(.bottom, 4)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("選擇\(context.displayName)")
        .accessibilityValue(isSelected ? "已選取" : "未選取")
        .accessibilityHint("切換題目、語速建議與歷史分組")
        .accessibilityIdentifier("home.context.\(context.rawValue)")
    }
}

private struct HomeIntroduction: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今天，讓表達自然長出來")
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text("選一個情境，或帶著自己的講稿練一小段。")
                .font(.subheadline)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.65))
        }
    }
}

private struct GrowthStrip: View {
    let model: TalkFitModel

    var body: some View {
        HStack(spacing: 0) {
            GrowthItem(value: model.historyFillerSummary, label: "贅字少")
            Divider().frame(height: 34).overlay(TalkFitTheme.line)
            GrowthItem(value: model.historyStabilitySummary, label: "穩定度")
            Divider().frame(height: 34).overlay(TalkFitTheme.line)
            GrowthItem(value: "\(model.practiceHistory.count) 次", label: "已保存")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 14)
        .background(
            TalkFitTheme.sageSoft.opacity(0.45),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "成長摘要：贅字 \(model.historyFillerSummary)，穩定度 \(model.historyStabilitySummary)，已保存 \(model.practiceHistory.count) 次"
        )
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
