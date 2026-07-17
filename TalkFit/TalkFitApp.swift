//
//  TalkFitApp.swift
//  TalkFit
//
//  Created by YU-RU on 2026/7/16.
//

import SwiftUI
import SwiftData

@main
@MainActor
struct TalkFitApp: App {
    private let modelContainer: ModelContainer
    @State private var model: TalkFitModel

    init() {
        let container = Self.makeModelContainer()
        modelContainer = container
        let historyStore = PracticeHistoryStore(modelContext: container.mainContext)
        let recordingArchiveStore = try? RecordingArchiveStore(
            modelContext: container.mainContext
        )
        let appModel = TalkFitModel(
            historyStore: historyStore,
            recordingArchiveStore: recordingArchiveStore
        )
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-seedRecordingArchiveQA") {
            appModel.loadRecordingArchiveQAFixtures()
        }
#endif
        _model = State(initialValue: appModel)
    }

    var body: some Scene {
        WindowGroup {
            TalkFitRootView(model: model)
        }
        .modelContainer(modelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: PracticeHistoryRecord.self,
                RecordingArchiveSessionRecord.self,
                RecordingArchiveAttemptRecord.self
            )
        } catch {
            let memoryOnly = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(
                for: PracticeHistoryRecord.self,
                RecordingArchiveSessionRecord.self,
                RecordingArchiveAttemptRecord.self,
                configurations: memoryOnly
            )
        }
    }
}
