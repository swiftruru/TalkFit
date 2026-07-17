import SwiftUI

struct ScriptPracticeView: View {
    let model: TalkFitModel
    let dismiss: () -> Void

    @State private var draft = ""
    @State private var selectedIndex = 0
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
                        Label("帶著這一段去練習", systemImage: "leaf.fill")
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
                draft = session.paragraphs.map(\.text).joined(separator: "\n\n")
                selectedIndex = session.selectedIndex
            }
        }
        .onChange(of: paragraphs.count) { _, count in
            if count == 0 {
                selectedIndex = 0
            } else if selectedIndex >= count {
                selectedIndex = count - 1
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("把講稿拆成一小段一小段")
                .font(.system(.title2, design: .serif, weight: .bold))
            Text("貼上內容後選一段開始。TalkFit 會比較你實際說出的重點，不要求逐字背誦。")
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
                Text("講稿只留在這次 App 使用期間；歷史紀錄不會保存講稿、錄音或逐字稿。")
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
                    Text("選擇這次要練的段落")
                        .font(.headline)
                    Spacer()
                    Text("共 \(paragraphs.count) 段")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.moss)
                }

                ForEach(paragraphs) { paragraph in
                    paragraphButton(paragraph)
                }
            }
        }
    }

    private func paragraphButton(_ paragraph: ScriptParagraph) -> some View {
        let isSelected = paragraph.id == selectedIndex
        return Button {
            selectedIndex = paragraph.id
            isEditorFocused = false
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text("\(paragraph.number)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(isSelected ? .white : TalkFitTheme.moss)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? TalkFitTheme.pine : TalkFitTheme.sageSoft.opacity(0.45), in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text(paragraph.text)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(TalkFitTheme.ink)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    if isSelected {
                        Label("這次練這一段", systemImage: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TalkFitTheme.clay)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                isSelected ? TalkFitTheme.sageSoft.opacity(0.38) : TalkFitTheme.paperLight.opacity(0.64),
                in: RoundedRectangle(cornerRadius: 19, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(isSelected ? TalkFitTheme.moss.opacity(0.45) : TalkFitTheme.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("第 \(paragraph.number) 段，\(paragraph.text)")
        .accessibilityValue(isSelected ? "已選取" : "未選取")
        .accessibilityIdentifier("script.paragraph.\(paragraph.number)")
    }

    private func useSelectedParagraph() {
        guard model.configureScriptPractice(text: draft, selectedIndex: selectedIndex) else { return }
        dismiss()
    }
}
