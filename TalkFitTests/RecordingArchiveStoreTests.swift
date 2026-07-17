import Foundation
import SwiftData
import Testing
@testable import TalkFit

@MainActor
struct RecordingArchiveStoreTests {
    @Test("短講錄音匯入 Application Support 結構並移除暫存檔")
    func importsShortPracticeAudio() throws {
        let fixture = try makeStore()
        defer { fixture.removeFiles() }
        let temporaryAudio = try fixture.makeTemporaryAudio(named: "short.m4a")
        let sessionID = UUID()
        let attemptID = UUID()

        let summary = try fixture.store.importSession(
            RecordingArchiveSessionDraft(
                id: sessionID,
                kind: .shortPractice,
                title: "30 秒短講",
                language: .traditionalChinese,
                context: .selfIntroduction,
                attempts: [
                    RecordingArchiveAttemptDraft(
                        id: attemptID,
                        kind: .initial,
                        temporaryAudioURL: temporaryAudio,
                        duration: 28,
                        fillerCount: 2,
                        pace: 205,
                        stability: 76,
                        transcript: "大家好，我正在練習把想法說清楚。",
                        transcriptSegments: [
                            SpeechTextSegment(
                                text: "大家好",
                                timestamp: 0,
                                duration: 1.2
                            ),
                            SpeechTextSegment(
                                text: "我正在練習把想法說清楚",
                                timestamp: 1.3,
                                duration: 3.4
                            )
                        ],
                        source: .recognized
                    )
                ]
            )
        )

        let attempt = try #require(summary.attempts.first)
        #expect(summary.kind == .shortPractice)
        #expect(summary.typeLabel == "短講練習")
        #expect(summary.attempts.count == 1)
        #expect(attempt.id == attemptID)
        #expect(!attempt.relativeAudioPath.hasPrefix("/"))
        #expect(attempt.audioIsAvailable)
        #expect(attempt.transcript == "大家好，我正在練習把想法說清楚。")
        #expect(attempt.transcriptSegments.count == 2)
        #expect(attempt.transcriptSegments.last?.timestamp == 1.3)
        #expect(FileManager.default.fileExists(atPath: attempt.audioURL.path))
        #expect(!FileManager.default.fileExists(atPath: temporaryAudio.path))
    }

    @Test("完整講稿與單段重錄聚合在同一個 session")
    func groupsScriptAttemptsUnderOneSession() throws {
        let fixture = try makeStore()
        defer { fixture.removeFiles() }
        let fullAudio = try fixture.makeTemporaryAudio(named: "full.caf")
        let segmentAudio = try fixture.makeTemporaryAudio(named: "segment.caf")
        let sessionID = UUID()

        _ = try fixture.store.importSession(
            RecordingArchiveSessionDraft(
                id: sessionID,
                kind: .scriptPractice,
                title: "產品簡報",
                language: .traditionalChinese,
                context: .presentation,
                paragraphCount: 3,
                attempts: [
                    RecordingArchiveAttemptDraft(
                        kind: .initial,
                        temporaryAudioURL: fullAudio,
                        duration: 92,
                        source: .recognized
                    ),
                    RecordingArchiveAttemptDraft(
                        kind: .segmentRetry,
                        paragraphNumber: 2,
                        temporaryAudioURL: segmentAudio,
                        duration: 21,
                        source: .recognized
                    )
                ]
            )
        )

        let sessions = fixture.store.fetchAll()
        let session = try #require(sessions.first)
        #expect(sessions.count == 1)
        #expect(session.id == sessionID)
        #expect(session.typeLabel == "完整講稿 · 3 段")
        #expect(session.attempts.count == 2)
        #expect(session.attempts.map(\.displayName) == ["第一次錄音", "第 2 段重錄"])
        #expect(session.totalDuration == 113)
    }

    @Test("示範錄音永遠不寫入索引或音檔資料夾")
    func rejectsSampleAudio() throws {
        let fixture = try makeStore()
        defer { fixture.removeFiles() }
        let sampleAudio = try fixture.makeTemporaryAudio(named: "sample.m4a")

        #expect(throws: RecordingArchiveError.unsupportedSource) {
            try fixture.store.importSession(
                RecordingArchiveSessionDraft(
                    kind: .shortPractice,
                    title: "示範",
                    language: .traditionalChinese,
                    context: .selfIntroduction,
                    attempts: [
                        RecordingArchiveAttemptDraft(
                            kind: .initial,
                            temporaryAudioURL: sampleAudio,
                            duration: 20,
                            source: .sample
                        )
                    ]
                )
            )
        }

        #expect(fixture.store.fetchAll().isEmpty)
        #expect(FileManager.default.fileExists(atPath: sampleAudio.path))
        let archivedFiles = try FileManager.default.contentsOfDirectory(
            at: fixture.archiveRoot,
            includingPropertiesForKeys: nil
        )
        #expect(archivedFiles.isEmpty)
    }

    @Test("刪除 session 會同步刪除旗下所有 attempt 與音檔")
    func deletesSessionAndAudio() throws {
        let fixture = try makeStore()
        defer { fixture.removeFiles() }
        let fullAudio = try fixture.makeTemporaryAudio(named: "full.m4a")
        let retryAudio = try fixture.makeTemporaryAudio(named: "retry.m4a")
        let sessionID = UUID()
        let summary = try fixture.store.importSession(
            RecordingArchiveSessionDraft(
                id: sessionID,
                kind: .shortPractice,
                title: "短講",
                language: .traditionalChinese,
                context: .selfIntroduction,
                attempts: [
                    RecordingArchiveAttemptDraft(
                        kind: .initial,
                        temporaryAudioURL: fullAudio,
                        duration: 30,
                        source: .recognized
                    ),
                    RecordingArchiveAttemptDraft(
                        kind: .fullRetry,
                        temporaryAudioURL: retryAudio,
                        duration: 27,
                        source: .recognized
                    )
                ]
            )
        )
        let audioURLs = summary.attempts.map(\.audioURL)

        try fixture.store.deleteSession(id: sessionID)

        #expect(fixture.store.fetchAll().isEmpty)
        #expect(audioURLs.allSatisfy { !FileManager.default.fileExists(atPath: $0.path) })
        #expect(!FileManager.default.fileExists(
            atPath: fixture.archiveRoot
                .appendingPathComponent(sessionID.uuidString.lowercased())
                .path
        ))
    }

    @Test("短講不能混入段落重錄，講稿段落編號也必須有效")
    func validatesAttemptClassification() throws {
        let fixture = try makeStore()
        defer { fixture.removeFiles() }
        let audio = try fixture.makeTemporaryAudio(named: "invalid.caf")

        #expect(throws: RecordingArchiveError.invalidClassification) {
            try fixture.store.importSession(
                RecordingArchiveSessionDraft(
                    kind: .shortPractice,
                    title: "短講",
                    language: .traditionalChinese,
                    context: .selfIntroduction,
                    attempts: [
                        RecordingArchiveAttemptDraft(
                            kind: .segmentRetry,
                            paragraphNumber: 1,
                            temporaryAudioURL: audio,
                            duration: 10,
                            source: .recognized
                        )
                    ]
                )
            )
        }
        #expect(fixture.store.fetchAll().isEmpty)
        #expect(FileManager.default.fileExists(atPath: audio.path))
    }

    private func makeStore() throws -> RecordingArchiveFixture {
        let container = try ModelContainer(
            for: RecordingArchiveSessionRecord.self,
            RecordingArchiveAttemptRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("TalkFitRecordingArchiveTests-\(UUID().uuidString)", isDirectory: true)
        let staging = root.appendingPathComponent("Staging", isDirectory: true)
        let archive = root.appendingPathComponent("Archive", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        let store = try RecordingArchiveStore(
            modelContext: container.mainContext,
            recordingsRootURL: archive
        )
        return RecordingArchiveFixture(
            container: container,
            store: store,
            root: root,
            stagingRoot: staging,
            archiveRoot: archive
        )
    }
}

@MainActor
private struct RecordingArchiveFixture {
    let container: ModelContainer
    let store: RecordingArchiveStore
    let root: URL
    let stagingRoot: URL
    let archiveRoot: URL

    func makeTemporaryAudio(named name: String) throws -> URL {
        let url = stagingRoot.appendingPathComponent(name)
        try Data("test-audio".utf8).write(to: url, options: .atomic)
        return url
    }

    func removeFiles() {
        try? FileManager.default.removeItem(at: root)
    }
}
