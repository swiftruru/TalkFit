import Foundation
import SwiftData
import Testing
@testable import TalkFit

@MainActor
struct PracticeHistoryStoreTests {
    @Test("歷史預設未決定，需由使用者主動開啟")
    func historyStartsUndecided() throws {
        let fixture = try makeStore()

        #expect(fixture.store.preference == .undecided)
        #expect(fixture.store.fetchAll().isEmpty)
    }

    @Test("舊版摘要同意不會被當成錄音同意，但舊版拒絕仍會保留")
    func legacyPreferenceRequiresFreshAudioConsent() throws {
        let enabledFixture = try makeStore()
        enabledFixture.defaults.set(
            HistoryPreference.enabled.rawValue,
            forKey: "talkfit.practice-history.preference.v1"
        )
        #expect(enabledFixture.store.preference == .undecided)

        let disabledFixture = try makeStore()
        disabledFixture.defaults.set(
            HistoryPreference.disabled.rawValue,
            forKey: "talkfit.practice-history.preference.v1"
        )
        #expect(disabledFixture.store.preference == .disabled)
    }

    @Test("只保存真實練習的前後摘要")
    func savesRecognizedSummary() throws {
        let fixture = try makeStore()
        fixture.store.setPreference(.enabled)
        let completedAt = Date(timeIntervalSince1970: 1_800_000_000)

        let didSave = fixture.store.save(
            comparison(source: .recognized),
            completedAt: completedAt
        )
        let saved = try #require(fixture.store.fetchAll().first)

        #expect(didSave)
        #expect(saved.completedAt == completedAt)
        #expect(saved.language == .traditionalChinese)
        #expect(saved.beforeFillerCount == 3)
        #expect(saved.afterFillerCount == 1)
        #expect(saved.beforePace == 260)
        #expect(saved.afterPace == 205)
        #expect(saved.beforeStability == 58)
        #expect(saved.afterStability == 82)
        #expect(saved.fillerImprovement == 2)
    }

    @Test("使用者不重錄也能保存單次練習摘要")
    func savesSingleRecognizedResult() throws {
        let fixture = try makeStore()
        fixture.store.setPreference(.enabled)
        let completedAt = Date(timeIntervalSince1970: 1_850_000_000)
        let practice = result(
            transcript: "大家好，我正在練習把提案說清楚。",
            fillerCounts: ["嗯": 1],
            pace: 188,
            stability: 74,
            context: .presentation,
            source: .recognized
        )

        #expect(fixture.store.save(practice, completedAt: completedAt))
        let saved = try #require(fixture.store.fetchAll().first)

        #expect(saved.completedAt == completedAt)
        #expect(saved.beforeFillerCount == saved.afterFillerCount)
        #expect(saved.beforePace == saved.afterPace)
        #expect(saved.beforeStability == saved.afterStability)
        #expect(saved.improvementNote == "完成一次專注練習")
    }

    @Test("未開啟與示範結果都不寫入歷史")
    func rejectsDisabledAndSampleResults() throws {
        let fixture = try makeStore()

        #expect(!fixture.store.save(comparison(source: .recognized)))
        fixture.store.setPreference(.enabled)
        #expect(!fixture.store.save(comparison(source: .sample)))
        #expect(fixture.store.fetchAll().isEmpty)
    }

    @Test("歷史會保存練習情境作為趨勢分組鍵")
    func savesPracticeContext() throws {
        let fixture = try makeStore()
        fixture.store.setPreference(.enabled)

        #expect(fixture.store.save(comparison(source: .recognized, context: .presentation)))
        let saved = try #require(fixture.store.fetchAll().first)

        #expect(saved.promptIdentifier == PracticeContext.presentation.rawValue)
        #expect(saved.promptTitle == PracticeContext.presentation.promptTitle(for: .traditionalChinese))
    }

    @Test("講稿練習只保存自訂講稿摘要，不保存原文")
    func savesScriptSummaryWithoutScriptText() throws {
        let fixture = try makeStore()
        fixture.store.setPreference(.enabled)
        let privateScript = "這是一段不應寫進歷史資料庫的私人講稿。"

        #expect(fixture.store.save(comparison(
            source: .recognized,
            scriptText: privateScript
        )))
        let saved = try #require(fixture.store.fetchAll().first)

        #expect(saved.promptIdentifier == "custom-script")
        #expect(saved.promptTitle == "自訂講稿")
        #expect(saved.promptTitle != privateScript)
    }

    @Test("關閉保存只停止新增，不會刪除既有紀錄")
    func disablingKeepsExistingHistory() throws {
        let fixture = try makeStore()
        fixture.store.setPreference(.enabled)
        #expect(fixture.store.save(comparison(source: .recognized)))

        fixture.store.setPreference(.disabled)

        #expect(!fixture.store.save(comparison(source: .recognized)))
        #expect(fixture.store.fetchAll().count == 1)
    }

    @Test("歷史依時間排序，並可單筆與全部刪除")
    func sortsAndDeletesHistory() throws {
        let fixture = try makeStore()
        fixture.store.setPreference(.enabled)
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_800_000_000)
        fixture.store.save(comparison(source: .recognized), completedAt: older)
        fixture.store.save(comparison(source: .recognized), completedAt: newer)

        var records = fixture.store.fetchAll()
        #expect(records.map(\.completedAt) == [newer, older])

        fixture.store.delete(id: records[0].id)
        records = fixture.store.fetchAll()
        #expect(records.count == 1)
        #expect(records[0].completedAt == older)

        fixture.store.deleteAll()
        #expect(fixture.store.fetchAll().isEmpty)
    }

    private func makeStore() throws -> (
        container: ModelContainer,
        store: PracticeHistoryStore,
        defaults: UserDefaults
    ) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PracticeHistoryRecord.self,
            configurations: configuration
        )
        let suiteName = "TalkFitTests.PracticeHistory.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (
            container,
            PracticeHistoryStore(
                modelContext: container.mainContext,
                defaults: defaults
            ),
            defaults
        )
    }

    private func comparison(
        source: ResultSource,
        context: PracticeContext = .selfIntroduction,
        scriptText: String? = nil
    ) -> TalkFit.ComparisonResult {
        TalkFit.ComparisonResult(
            before: result(
                transcript: "大家好，嗯，我最近在做產品，然後想把它介紹清楚。",
                fillerCounts: ["嗯": 1, "然後": 2],
                pace: 260,
                stability: 58,
                context: context,
                scriptText: scriptText,
                source: source
            ),
            after: result(
                transcript: "大家好，我最近在做產品，也想把它介紹清楚。",
                fillerCounts: ["然後": 1],
                pace: 205,
                stability: 82,
                context: context,
                scriptText: scriptText,
                source: source
            )
        )
    }

    private func result(
        transcript: String,
        fillerCounts: [String: Int],
        pace: Int,
        stability: Int,
        context: PracticeContext,
        scriptText: String? = nil,
        source: ResultSource
    ) -> PracticeResult {
        PracticeResult(
            transcript: transcript,
            duration: 24,
            fillerCounts: fillerCounts,
            fillerEvidence: [],
            fillerWords: PracticeLanguage.traditionalChinese.defaultFillerWords,
            language: .traditionalChinese,
            context: context,
            scriptReference: scriptText.map {
                ScriptPracticeReference(text: $0, paragraphNumber: 1, paragraphCount: 1)
            },
            sentencePaces: [],
            pace: pace,
            stability: stability,
            prioritySegment: transcript,
            coachingCue: "先說重點。",
            source: source
        )
    }
}
