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
        _model = State(initialValue: TalkFitModel(historyStore: historyStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .modelContainer(modelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: PracticeHistoryRecord.self)
        } catch {
            let memoryOnly = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(
                for: PracticeHistoryRecord.self,
                configurations: memoryOnly
            )
        }
    }
}
