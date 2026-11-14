import SwiftUI

/// Which version of the built-in script a person reads aloud.
enum ReferenceScriptStyle: String, CaseIterable, Identifiable {
    case clean
    case withFillers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: "正常版"
        case .withFillers: "贅字版"
        }
    }

    var systemImage: String {
        switch self {
        case .clean: "leaf"
        case .withFillers: "quote.bubble"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .clean: "leaf.fill"
        case .withFillers: "quote.bubble.fill"
        }
    }

    /// One line telling the reader what this version is for.
    var hint: String {
        switch self {
        case .clean: "乾淨的講稿，照著順順地唸完。"
        case .withFillers: "橘色是故意加進去的贅字，照著唸，看 TalkFit 抓到幾個。"
        }
    }
}

/// Two-way switch between the clean script and the filler script, drawn in
/// the same paper-tab style as the language selector.
struct ReferenceScriptStyleSelector: View {
    let selection: ReferenceScriptStyle
    var compact = false
    let select: (ReferenceScriptStyle) -> Void

    var body: some View {
        HStack(spacing: compact ? 6 : 10) {
            ForEach(ReferenceScriptStyle.allCases) { style in
                button(for: style)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("範例講稿版本")
    }

    private func button(for style: ReferenceScriptStyle) -> some View {
        let isSelected = style == selection
        let accent = style == .withFillers ? TalkFitTheme.clay : TalkFitTheme.moss
        let radius: CGFloat = compact ? 12 : 15
        return Button {
            select(style)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? style.selectedSystemImage : style.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? accent : TalkFitTheme.sage)
                    .accessibilityHidden(true)
                Text(style.title)
                    .font((compact ? Font.caption : Font.subheadline).weight(isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? TalkFitTheme.pine : TalkFitTheme.ink.opacity(0.68))
            .frame(maxWidth: .infinity, minHeight: compact ? 36 : 44)
            .background(
                isSelected
                    ? (style == .withFillers
                        ? TalkFitTheme.clay.opacity(0.12)
                        : TalkFitTheme.sageSoft.opacity(0.5))
                    : TalkFitTheme.paperLight.opacity(0.36),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(isSelected ? accent.opacity(0.36) : TalkFitTheme.line, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.title)講稿")
        .accessibilityValue(isSelected ? "已選取" : "未選取")
        .accessibilityHint(style.hint)
        .accessibilityIdentifier("script.style.\(style.rawValue)")
    }
}

extension ReferenceScriptStyle {
    /// The script as display text. The filler version marks every filler
    /// word the same way the report does, so the reader sees what to expect.
    func displayText(
        _ script: String,
        fillerWords: [String],
        language: PracticeLanguage
    ) -> AttributedString {
        var attributed = AttributedString(script)
        guard self == .withFillers else { return attributed }
        for filler in fillerWords {
            for range in TalkFitAnalyzer.ranges(of: filler, in: script, language: language) {
                guard let attributedRange = Range(range, in: attributed) else { continue }
                attributed[attributedRange].backgroundColor = TalkFitTheme.clay.opacity(0.18)
                attributed[attributedRange].foregroundColor = TalkFitTheme.clay
            }
        }
        return attributed
    }
}
