import SwiftUI

struct LivePaceNote: View {
    let feedback: SentencePaceFeedback
    let language: PracticeLanguage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "metronome.fill")
                .foregroundStyle(feedback.state == .steady ? TalkFitTheme.moss : TalkFitTheme.clay)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("最新一句 · \(feedback.pace) \(language.paceUnit)")
                    .font(.caption.weight(.bold))
                Text(feedback.state.suggestion)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.64))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Text(feedback.state.label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(feedback.state == .steady ? TalkFitTheme.moss : TalkFitTheme.clay)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(TalkFitTheme.paperLight.opacity(0.8), in: Capsule())
        }
        .padding(12)
        .background(TalkFitTheme.sageSoft.opacity(0.24), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "最新一句語速 \(feedback.pace) \(language.paceUnit)，\(feedback.state.label)。\(feedback.state.suggestion)"
        )
    }
}

struct SentencePaceList: View {
    let feedback: [SentencePaceFeedback]
    let language: PracticeLanguage

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(feedback.enumerated()), id: \.element.id) { index, item in
                SentencePaceRow(index: index + 1, feedback: item, language: language)
                if item.id != feedback.last?.id {
                    Divider().overlay(TalkFitTheme.line)
                        .padding(.vertical, 12)
                }
            }
        }
    }
}

private struct SentencePaceRow: View {
    let index: Int
    let feedback: SentencePaceFeedback
    let language: PracticeLanguage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(TalkFitTheme.pine)
                .frame(width: 28, height: 28)
                .background(TalkFitTheme.sageSoft.opacity(0.48), in: Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text(feedback.text)
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 7) {
                    Text("\(feedback.pace) \(language.paceUnit)")
                        .font(.caption.weight(.bold).monospacedDigit())
                    Text(feedback.state.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(feedback.state == .steady ? TalkFitTheme.moss : TalkFitTheme.clay)
                }
                Text(feedback.state.suggestion)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct PaceScale: View {
    let pace: Int
    let language: PracticeLanguage

    var body: some View {
        GeometryReader { geometry in
            let bounds = language.paceScaleRange
            let progress = min(
                1,
                max(0, CGFloat(pace - bounds.lowerBound) / CGFloat(bounds.upperBound - bounds.lowerBound))
            )
            ZStack(alignment: .leading) {
                Capsule().fill(TalkFitTheme.sageSoft.opacity(0.72)).frame(height: 10)
                Capsule().fill(TalkFitTheme.moss).frame(
                    width: max(12, geometry.size.width * progress),
                    height: 10
                )
                Circle()
                    .fill(TalkFitTheme.clay)
                    .frame(width: 18, height: 18)
                    .offset(x: min(geometry.size.width - 18, max(0, geometry.size.width * progress - 9)))
            }
        }
        .frame(height: 18)
        .accessibilityLabel("語速 \(pace) \(language.paceUnit)")
    }
}
