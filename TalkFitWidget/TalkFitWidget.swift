import SwiftUI
import WidgetKit

private enum WidgetTheme {
    static let paper = Color(red: 0.96, green: 0.93, blue: 0.86)
    static let paperLight = Color(red: 0.99, green: 0.98, blue: 0.94)
    static let ink = Color(red: 0.08, green: 0.23, blue: 0.14)
    static let pine = Color(red: 0.12, green: 0.31, blue: 0.20)
    static let moss = Color(red: 0.34, green: 0.47, blue: 0.23)
    static let sage = Color(red: 0.58, green: 0.66, blue: 0.43)
    static let clay = Color(red: 0.67, green: 0.31, blue: 0.16)
}

private struct PracticeEntry: TimelineEntry {
    let date: Date
}

private struct PracticeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PracticeEntry {
        PracticeEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PracticeEntry) -> Void) {
        completion(PracticeEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PracticeEntry>) -> Void) {
        completion(Timeline(entries: [PracticeEntry(date: .now)], policy: .never))
    }
}

private struct TalkFitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    private let startPracticeURL = URL(string: "talkfit://practice/start")!

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                accessoryCircular
            case .accessoryRectangular:
                accessoryRectangular
            case .systemMedium:
                mediumWidget
            default:
                smallWidget
            }
        }
        .widgetURL(startPracticeURL)
        .containerBackground(for: .widget) {
            WidgetTheme.paper
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
            Spacer(minLength: 10)
            ZStack {
                Circle()
                    .fill(WidgetTheme.sage.opacity(0.20))
                    .frame(width: 58, height: 58)
                Image(systemName: "mic.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(WidgetTheme.pine)
            }
            Spacer(minLength: 10)
            Text("一鍵開始練習")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WidgetTheme.ink)
            Text("30 秒，說得更自在")
                .font(.caption2)
                .foregroundStyle(WidgetTheme.moss)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumWidget: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                brand
                Spacer(minLength: 6)
                Text("今天，也練一次")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(WidgetTheme.ink)
                Text("30 秒開口，慢慢長出自己的節奏。")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.moss)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            VStack(spacing: 9) {
                Image(systemName: "mic.fill")
                    .font(.title2.weight(.semibold))
                Text("開始練習")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(width: 104, height: 104)
            .background(WidgetTheme.pine, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private var accessoryCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "mic.fill")
                .font(.title3.weight(.semibold))
        }
        .accessibilityLabel("開始 TalkFit 練習")
    }

    private var accessoryRectangular: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill")
            VStack(alignment: .leading, spacing: 1) {
                Text("TalkFit")
                    .font(.headline)
                Text("開始 30 秒練習")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("TalkFit，開始 30 秒練習")
    }

    private var brand: some View {
        HStack(spacing: 5) {
            Text("TalkFit")
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(WidgetTheme.ink)
            Image(systemName: "leaf.fill")
                .font(.caption2)
                .foregroundStyle(WidgetTheme.sage)
        }
    }
}

struct TalkFitPracticeWidget: Widget {
    let kind = "TalkFitPracticeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PracticeProvider()) { _ in
            TalkFitWidgetView()
        }
        .configurationDisplayName("一鍵開始練習")
        .description("從主畫面或鎖定畫面直接開始 TalkFit 口說練習。")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

@main
struct TalkFitWidgetBundle: WidgetBundle {
    var body: some Widget {
        TalkFitPracticeWidget()
    }
}
