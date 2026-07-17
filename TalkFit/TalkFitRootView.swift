import SwiftUI

struct TalkFitRootView: View {
    let model: TalkFitModel

    @State private var selection: RootTab

    init(model: TalkFitModel) {
        self.model = model
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: RootTab = if arguments.contains("-openSettings") {
            .settings
        } else if arguments.contains("-openRecordingArchive") {
            .recordings
        } else {
            .practice
        }
        _selection = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("練習", systemImage: "mic.fill", value: RootTab.practice) {
                ContentView(model: model)
                    .toolbar(model.stage == .home ? .visible : .hidden, for: .tabBar)
            }

            Tab("紀錄", systemImage: "waveform", value: RootTab.recordings) {
                RecordingArchiveView(model: model)
            }

            Tab("設定", systemImage: "gearshape.fill", value: RootTab.settings) {
                SettingsView(model: model)
            }
        }
        .tint(TalkFitTheme.pine)
        .onChange(of: selection) { _, tab in
            if tab == .recordings {
                model.reloadHistory()
            }
        }
        .onChange(of: model.stage) { _, stage in
            if stage != .home {
                selection = .practice
            }
        }
    }
}

private enum RootTab: Hashable {
    case practice
    case recordings
    case settings
}
