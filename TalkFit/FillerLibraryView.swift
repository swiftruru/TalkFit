import SwiftUI

struct FillerLibraryView: View {
    @Environment(\.dismiss) private var dismiss

    let model: TalkFitModel

    @State private var newWord = ""
    @State private var validationMessage: String?
    @State private var resetTarget: FillerResetTarget?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                addSection
                librarySection
                resetSection
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .tint(TalkFitTheme.pine)
            .navigationTitle("調整贅字庫")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", action: dismissSheet)
                }
            }
            .alert(item: $resetTarget, content: resetAlert)
            .onAppear { isInputFocused = true }
        }
    }

    private var addSection: some View {
        Section("新增贅字") {
            TextField(inputPlaceholder, text: $newWord)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(model.selectedLanguage == .english)
                .submitLabel(.done)
                .focused($isInputFocused)
                .onSubmit(addWord)

            Button("加入贅字庫", action: addWord)
                .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.clay)
            }
        }
    }

    private var librarySection: some View {
        Section {
            ForEach(model.activeFillerWords, id: \.self) { word in
                HStack {
                    Text(word)
                    Spacer()
                    Button {
                        removeWord(word)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(TalkFitTheme.clay.opacity(0.78))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("移除贅字 \(word)")
                }
            }
        } header: {
            Text("\(model.selectedLanguage.displayName) 贅字庫 · \(model.activeFillerWords.count) 個")
        } footer: {
            Text("變更會立即套用到下一次辨識與分析，並保存在這台裝置上。")
        }
    }

    private var resetSection: some View {
        Section("還原") {
            Button(role: .destructive) {
                resetTarget = .language(model.selectedLanguage)
            } label: {
                Label("還原 \(model.selectedLanguage.displayName) 預設贅字", systemImage: "arrow.counterclockwise")
            }
            .accessibilityIdentifier("fillers.reset.language")

            Button(role: .destructive) {
                resetTarget = .all
            } label: {
                Label("還原所有語言", systemImage: "arrow.trianglehead.2.counterclockwise")
            }
            .accessibilityIdentifier("fillers.reset.all")
        }
    }

    private var inputPlaceholder: String {
        model.selectedLanguage == .english ? "例如：I mean" : "例如：老實說"
    }

    private func addWord() {
        if model.addFillerWord(newWord) {
            newWord = ""
            validationMessage = nil
        } else {
            validationMessage = "這個詞已存在、內容為空，或贅字庫已達 40 個。"
        }
    }

    private func removeWord(_ word: String) {
        model.removeFillerWord(word)
        validationMessage = nil
    }

    private func resetAlert(for target: FillerResetTarget) -> Alert {
        Alert(
            title: Text(target.title),
            message: Text(target.message),
            primaryButton: .cancel(Text("保留目前設定")),
            secondaryButton: .destructive(Text("還原")) {
                reset(target)
            }
        )
    }

    private func reset(_ target: FillerResetTarget) {
        switch target {
        case .language(let language):
            model.resetFillerWords(for: language)
        case .all:
            model.resetAllFillerWords()
        }
        newWord = ""
        validationMessage = nil
    }

    private func dismissSheet() {
        dismiss()
    }
}

private enum FillerResetTarget: Identifiable {
    case language(PracticeLanguage)
    case all

    var id: String {
        switch self {
        case .language(let language): "language-\(language.rawValue)"
        case .all: "all"
        }
    }

    var title: String {
        switch self {
        case .language(let language): "還原 \(language.displayName) 贅字庫嗎？"
        case .all: "還原所有贅字庫嗎？"
        }
    }

    var message: String {
        switch self {
        case .language(let language):
            "你在 \(language.displayName) 新增或刪除的內容會消失，並回到 App 預設贅字。"
        case .all:
            "中文與 English 的所有自訂內容都會消失，並回到 App 預設贅字。"
        }
    }
}
