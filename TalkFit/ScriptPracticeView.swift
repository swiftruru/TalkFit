import SwiftUI

struct ScriptPracticeView: View {
    let model: TalkFitModel
    let dismiss: () -> Void

    @State private var draft = ""
    @FocusState private var isEditorFocused: Bool

    private var paragraphs: [ScriptParagraph] {
        ScriptPracticeAnalyzer.paragraphs(in: draft)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                        introduction
                        editor
                        paragraphPicker
                    }
                    .talkFitPageInsets(top: 12, bottom: 120)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("講稿練習")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: dismiss)
                        .foregroundStyle(TalkFitTheme.pine)
                }
            }
            .safeAreaInset(edge: .bottom) {
                BottomActionBar {
                    Button(action: useSelectedParagraph) {
                        Label("帶著完整講稿去練習", systemImage: "leaf.fill")
                    }
                    .buttonStyle(PrimaryActionStyle())
                    .disabled(paragraphs.isEmpty)
                    .accessibilityIdentifier("script.use")
                }
            }
        }
        .tint(TalkFitTheme.pine)
        .onAppear {
            if let session = model.scriptPractice {
                draft = session.fullText
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("先完整說完，再挑一段加強")
                .font(.system(.title2, design: .serif, weight: .bold))
            Text("貼上整份講稿後開始錄音。完成後每一段都會有建議，你可以只重錄想加強的那一段。")
                .font(.subheadline)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var editor: some View {
        NotebookSection(title: "貼上講稿") {
            ZStack(alignment: .topLeading) {
                if draft.isEmpty {
                    Text("每一段用空白行分開，例如：\n\n大家好，今天我想分享……\n\n這個提案解決的是……")
                        .font(.body)
                        .foregroundStyle(TalkFitTheme.ink.opacity(0.38))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 9)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $draft)
                    .font(.body)
                    .lineSpacing(4)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 176)
                    .focused($isEditorFocused)
                    .accessibilityLabel("講稿內容")
                    .accessibilityHint("空白行會分成不同段落")
                    .accessibilityIdentifier("script.editor")
            }
            .padding(10)
            .background(TalkFitTheme.paper.opacity(0.48), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TalkFitTheme.line, lineWidth: 1)
            }

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(TalkFitTheme.moss)
                    .accessibilityHidden(true)
                Text("你貼上的講稿只留在這次 App 使用期間，不會寫入歷史紀錄。若你開啟本機紀錄，收下練習時會保存錄音與辨識逐字稿。")
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var paragraphPicker: some View {
        if !paragraphs.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("錄完後可逐段重練")
                        .font(.headline)
                    Spacer()
                    Text("共 \(paragraphs.count) 段")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.moss)
                }

                ForEach(paragraphs) { paragraph in
                    paragraphPreview(paragraph)
                }
            }
        }
    }

    private func paragraphPreview(_ paragraph: ScriptParagraph) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(paragraph.number)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(TalkFitTheme.moss)
                .frame(width: 30, height: 30)
                .background(TalkFitTheme.sageSoft.opacity(0.45), in: Circle())
            Text(paragraph.text)
                .font(.subheadline)
                .foregroundStyle(TalkFitTheme.ink)
                .lineLimit(4)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            TalkFitTheme.paperLight.opacity(0.64),
            in: RoundedRectangle(cornerRadius: 19, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(TalkFitTheme.line, lineWidth: 1)
        }
        .accessibilityLabel("第 \(paragraph.number) 段，\(paragraph.text)")
        .accessibilityIdentifier("script.paragraph.\(paragraph.number)")
    }

    private func useSelectedParagraph() {
        guard model.configureScriptPractice(text: draft) else { return }
        dismiss()
    }
}
