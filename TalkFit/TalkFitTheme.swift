import SwiftUI

enum TalkFitTheme {
    static let paper = Color(red: 0.96, green: 0.93, blue: 0.86)
    static let paperLight = Color(red: 0.99, green: 0.98, blue: 0.94)
    static let ink = Color(red: 0.08, green: 0.23, blue: 0.14)
    static let pine = Color(red: 0.12, green: 0.31, blue: 0.20)
    static let moss = Color(red: 0.34, green: 0.47, blue: 0.23)
    static let sage = Color(red: 0.58, green: 0.66, blue: 0.43)
    static let sageSoft = Color(red: 0.82, green: 0.84, blue: 0.68)
    static let clay = Color(red: 0.67, green: 0.31, blue: 0.16)
    static let line = Color(red: 0.18, green: 0.31, blue: 0.20).opacity(0.18)

    static let pageGutter: CGFloat = 26
    static let pageTop: CGFloat = 18
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 24
}

struct PaperBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Image("PaperBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(TalkFitTheme.paper.opacity(0.12))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    func talkFitPageInsets(top: CGFloat = TalkFitTheme.pageTop, bottom: CGFloat) -> some View {
        padding(.horizontal, TalkFitTheme.pageGutter)
            .padding(.top, top)
            .padding(.bottom, bottom)
    }
}

struct BottomActionBar<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, TalkFitTheme.pageGutter)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(TalkFitTheme.line.opacity(0.7))
                    .frame(height: 0.5)
                    .accessibilityHidden(true)
            }
    }
}

struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(isEnabled ? TalkFitTheme.pine : TalkFitTheme.sage)
                    .shadow(
                        color: TalkFitTheme.ink.opacity(configuration.isPressed ? 0.05 : 0.18),
                        radius: configuration.isPressed ? 2 : 7,
                        y: configuration.isPressed ? 2 : 6
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct NotebookSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(TalkFitTheme.moss)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TalkFitTheme.cardPadding)
        .background(TalkFitTheme.paperLight.opacity(0.82), in: RoundedRectangle(cornerRadius: TalkFitTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: TalkFitTheme.cardRadius, style: .continuous)
                .stroke(TalkFitTheme.line, lineWidth: 1)
        }
    }
}

struct BrandHeader: View {
    var compact = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("TalkFit")
                    .font(.system(compact ? .title2 : .largeTitle, design: .serif, weight: .medium))
                    .foregroundStyle(TalkFitTheme.ink)
                if !compact {
                    Text("綠園練習簿")
                        .font(.caption.weight(.semibold))
                        .tracking(2.5)
                        .foregroundStyle(TalkFitTheme.moss)
                }
            }
            Spacer()
            Image(systemName: "leaf.fill")
                .font(.title3)
                .foregroundStyle(TalkFitTheme.sage)
                .accessibilityHidden(true)
        }
    }
}

struct GardenLeavePrompt {
    let title: String
    let message: String
    let leaveTitle: String
    let stayTitle: String
}

struct GardenNavigationHeader: View {
    let destination: String
    let prompt: GardenLeavePrompt?
    var confirmationDidChange: (Bool) -> Void = { _ in }
    let action: () -> Void

    @State private var showsConfirmation = false

    var body: some View {
        ZStack {
            Text("TalkFit")
                .font(.system(.headline, design: .serif, weight: .medium))
                .foregroundStyle(TalkFitTheme.ink.opacity(0.78))

            HStack {
                Button {
                    if prompt == nil {
                        action()
                    } else {
                        showsConfirmation = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.bold))
                        Text(destination)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(TalkFitTheme.pine)
                    .padding(.horizontal, 11)
                    .frame(minHeight: 44)
                    .background(TalkFitTheme.paperLight.opacity(0.78), in: Capsule())
                    .overlay {
                        Capsule().stroke(TalkFitTheme.line, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("返回\(destination)")
                .accessibilityHint(prompt == nil ? "立即返回" : "返回前會先確認")

                Spacer()

                Image(systemName: "leaf.fill")
                    .font(.subheadline)
                    .foregroundStyle(TalkFitTheme.sage)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 44)
        .alert(prompt?.title ?? "", isPresented: $showsConfirmation) {
            Button(prompt?.stayTitle ?? "留在這裡", role: .cancel) {}
            Button(prompt?.leaveTitle ?? "離開", role: .destructive, action: action)
        } message: {
            Text(prompt?.message ?? "")
        }
        .onChange(of: showsConfirmation) { _, isPresented in
            confirmationDidChange(isPresented)
        }
    }
}

struct MetricPair: View {
    let title: String
    let before: String
    let after: String
    let improvement: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TalkFitTheme.ink)
                Spacer()
                Text(improvement)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TalkFitTheme.moss)
            }
            HStack(spacing: 12) {
                value(before, label: "上一次", color: TalkFitTheme.clay.opacity(0.78))
                Image(systemName: "arrow.right")
                    .foregroundStyle(TalkFitTheme.sage)
                    .accessibilityHidden(true)
                value(after, label: "這一次", color: TalkFitTheme.pine)
            }
        }
        .padding(.vertical, 4)
    }

    private func value(_ value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(TalkFitTheme.ink.opacity(0.55))
            Text(value).font(.title3.weight(.bold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
