import AVFoundation
import Speech
import SwiftUI
import UIKit

struct SettingsView: View {
    let model: TalkFitModel

    @Environment(\.scenePhase) private var scenePhase
    @State private var microphoneAccess: PermissionAccessState = .notRequested
    @State private var speechAccess: PermissionAccessState = .notRequested
    @State private var requestingPermission: PermissionKind?
    @State private var showsFillerLibrary = false

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: TalkFitTheme.sectionSpacing) {
                        settingsHeader
                        fillerLibrarySection
                        recordingStorageSection
                        permissionSection
                    }
                    .talkFitPageInsets(bottom: 34)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(TalkFitTheme.pine)
        .foregroundStyle(TalkFitTheme.ink)
        .sheet(isPresented: $showsFillerLibrary) {
            FillerLibraryView(model: model)
                .presentationDetents([.medium, .large])
        }
        .task(refreshPermissionStates)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshPermissionStates()
            }
        }
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("設定")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(TalkFitTheme.ink)
                .accessibilityAddTraits(.isHeader)
            Text("把贅字庫、錄音保存與權限整理在這裡。")
                .font(.subheadline)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.64))
        }
    }

    private var fillerLibrarySection: some View {
        NotebookSection(title: "贅字庫") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: "text.badge.plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TalkFitTheme.clay)
                        .frame(width: 46, height: 46)
                        .background(TalkFitTheme.clay.opacity(0.1), in: Circle())
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("聽懂你的口頭習慣")
                            .font(.headline)
                        Text("目前使用 \(model.selectedLanguage.displayName)詞庫，共 \(model.activeFillerWords.count) 個。")
                            .font(.caption)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                    }
                }

                Picker("贅字庫語言", selection: fillerLanguageBinding) {
                    ForEach(PracticeLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("切換要管理的贅字庫語言")
                .accessibilityIdentifier("settings.filler-language")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(Array(model.activeFillerWords.prefix(6)), id: \.self) { word in
                            Text(word)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TalkFitTheme.pine)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(TalkFitTheme.sageSoft.opacity(0.42), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 1)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("目前贅字範例：\(model.activeFillerWords.prefix(6).joined(separator: "、"))")

                Button {
                    showsFillerLibrary = true
                } label: {
                    Label("管理贅字庫", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(SecondaryActionStyle())
                .accessibilityHint("新增、移除或還原贅字")
                .accessibilityIdentifier("settings.fillers")
            }
        }
    }

    private var permissionSection: some View {
        NotebookSection(title: "錄音與辨識權限") {
            VStack(alignment: .leading, spacing: 0) {
                PermissionRow(
                    kind: .microphone,
                    state: microphoneAccess,
                    isRequesting: requestingPermission == .microphone,
                    request: requestPermission
                )

                Divider()
                    .overlay(TalkFitTheme.line)
                    .padding(.vertical, 5)

                PermissionRow(
                    kind: .speechRecognition,
                    state: speechAccess,
                    isRequesting: requestingPermission == .speechRecognition,
                    request: requestPermission
                )

                if needsSystemSettings {
                    Divider()
                        .overlay(TalkFitTheme.line)
                        .padding(.top, 5)

                    Button(action: openSystemSettings) {
                        Label("前往系統設定", systemImage: "gearshape.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TalkFitTheme.pine)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(TalkFitTheme.sageSoft.opacity(0.32), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 14)
                    .accessibilityHint("在 iPhone 設定中變更 TalkFit 權限")
                    .accessibilityIdentifier("settings.open-system-settings")
                }

                Label(
                    "設定頁不會自動啟用權限；只有你按下允許或開始真實練習時才會詢問。",
                    systemImage: "lock.shield.fill"
                )
                .font(.caption)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            }
        }
    }

    private var recordingStorageSection: some View {
        NotebookSection(title: "練習紀錄") {
            VStack(alignment: .leading, spacing: 15) {
                Toggle(isOn: historyEnabledBinding) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("保存練習摘要、錄音與逐字稿")
                            .font(.body.weight(.semibold))
                        Text(model.isHistoryEnabled
                             ? "收下真實練習時，會保存每段錄音與辨識逐字稿"
                             : "目前不會新增紀錄；已保存的內容仍會保留")
                            .font(.caption)
                            .foregroundStyle(TalkFitTheme.ink.opacity(0.62))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(TalkFitTheme.moss)
                .accessibilityHint("控制之後收下的練習是否保存到這台 iPhone")
                .accessibilityIdentifier("settings.recordings.toggle")

                Divider()
                    .overlay(TalkFitTheme.line)

                Label("摘要、錄音與逐字稿只保存在這台 iPhone。", systemImage: "iphone.gen3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TalkFitTheme.moss)

                Label(
                    "你貼上的講稿不會寫入紀錄；示範練習也永遠不會保存。",
                    systemImage: "lock.shield.fill"
                )
                .font(.caption)
                .foregroundStyle(TalkFitTheme.ink.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var fillerLanguageBinding: Binding<PracticeLanguage> {
        Binding(
            get: { model.selectedLanguage },
            set: model.selectLanguage
        )
    }

    private var historyEnabledBinding: Binding<Bool> {
        Binding(
            get: { model.isHistoryEnabled },
            set: model.setHistoryEnabled
        )
    }

    private var needsSystemSettings: Bool {
        microphoneAccess.needsSystemSettings || speechAccess.needsSystemSettings
    }

    private func refreshPermissionStates() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            microphoneAccess = .granted
        case .denied:
            microphoneAccess = .denied
        case .undetermined:
            microphoneAccess = .notRequested
        @unknown default:
            microphoneAccess = .restricted
        }

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechAccess = .granted
        case .denied:
            speechAccess = .denied
        case .restricted:
            speechAccess = .restricted
        case .notDetermined:
            speechAccess = .notRequested
        @unknown default:
            speechAccess = .restricted
        }
    }

    private func requestPermission(_ kind: PermissionKind) {
        guard requestingPermission == nil else { return }
        requestingPermission = kind

        Task {
            switch kind {
            case .microphone:
                _ = await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            case .speechRecognition:
                _ = await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { status in
                        continuation.resume(returning: status)
                    }
                }
            }

            refreshPermissionStates()
            requestingPermission = nil
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct PermissionRow: View {
    let kind: PermissionKind
    let state: PermissionAccessState
    let isRequesting: Bool
    let request: (PermissionKind) -> Void

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: kind.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(state == .granted ? TalkFitTheme.moss : TalkFitTheme.clay)
                .frame(width: 42, height: 42)
                .background(iconBackground, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(kind.title)
                    .font(.subheadline.weight(.semibold))
                Text(kind.explanation)
                    .font(.caption)
                    .foregroundStyle(TalkFitTheme.ink.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if state == .notRequested {
                Button {
                    request(kind)
                } label: {
                    Group {
                        if isRequesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("允許")
                                .font(.caption.weight(.bold))
                        }
                    }
                    .foregroundStyle(TalkFitTheme.pine)
                    .frame(minWidth: 58, minHeight: 44)
                    .background(TalkFitTheme.sageSoft.opacity(0.4), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isRequesting)
                .accessibilityLabel("允許\(kind.title)")
                .accessibilityIdentifier(kind.accessibilityIdentifier)
            } else {
                Text(state.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(state.foregroundColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(state.backgroundColor, in: Capsule())
                    .accessibilityLabel("\(kind.title)\(state.label)")
            }
        }
        .frame(minHeight: 66)
    }

    private var iconBackground: Color {
        state == .granted
            ? TalkFitTheme.sageSoft.opacity(0.4)
            : TalkFitTheme.clay.opacity(0.1)
    }
}

private enum PermissionKind: Hashable {
    case microphone
    case speechRecognition

    var title: String {
        switch self {
        case .microphone: "麥克風"
        case .speechRecognition: "語音辨識"
        }
    }

    var explanation: String {
        switch self {
        case .microphone: "錄下練習內容與音量變化"
        case .speechRecognition: "產生逐字稿並分析贅字"
        }
    }

    var systemImage: String {
        switch self {
        case .microphone: "mic.fill"
        case .speechRecognition: "waveform.badge.mic"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .microphone: "settings.permission.microphone"
        case .speechRecognition: "settings.permission.speech"
        }
    }
}

private enum PermissionAccessState: Equatable {
    case notRequested
    case granted
    case denied
    case restricted

    var label: String {
        switch self {
        case .notRequested: "尚未詢問"
        case .granted: "已允許"
        case .denied: "已關閉"
        case .restricted: "受限制"
        }
    }

    var needsSystemSettings: Bool {
        self == .denied || self == .restricted
    }

    var foregroundColor: Color {
        self == .granted ? TalkFitTheme.pine : TalkFitTheme.clay
    }

    var backgroundColor: Color {
        self == .granted
            ? TalkFitTheme.sageSoft.opacity(0.4)
            : TalkFitTheme.clay.opacity(0.1)
    }
}
