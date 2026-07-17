import Foundation
import SwiftData

enum RecordingArchiveSessionKind: String, CaseIterable, Equatable {
    case shortPractice
    case scriptPractice

    var displayName: String {
        switch self {
        case .shortPractice:
            "短講練習"
        case .scriptPractice:
            "完整講稿"
        }
    }
}

enum RecordingArchiveAttemptKind: String, Equatable {
    case initial
    case fullRetry
    case segmentRetry
}

@Model
final class RecordingArchiveSessionRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var completedAt: Date
    var kindIdentifier: String
    var title: String
    var languageIdentifier: String
    var contextIdentifier: String
    var paragraphCount: Int?

    init(
        id: UUID,
        createdAt: Date,
        completedAt: Date,
        kind: RecordingArchiveSessionKind,
        title: String,
        language: PracticeLanguage,
        context: PracticeContext,
        paragraphCount: Int?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.completedAt = completedAt
        kindIdentifier = kind.rawValue
        self.title = title
        languageIdentifier = language.rawValue
        contextIdentifier = context.rawValue
        self.paragraphCount = paragraphCount
    }
}

@Model
final class RecordingArchiveAttemptRecord {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var capturedAt: Date
    var sequence: Int
    var kindIdentifier: String
    var paragraphNumber: Int?
    var relativeAudioPath: String
    var duration: TimeInterval
    var fillerCount: Int?
    var pace: Int?
    var stability: Int?
    var transcript: String?
    var transcriptSegmentsData: Data?

    init(
        id: UUID,
        sessionID: UUID,
        capturedAt: Date,
        sequence: Int,
        kind: RecordingArchiveAttemptKind,
        paragraphNumber: Int?,
        relativeAudioPath: String,
        duration: TimeInterval,
        fillerCount: Int?,
        pace: Int?,
        stability: Int?,
        transcript: String? = nil,
        transcriptSegmentsData: Data? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.capturedAt = capturedAt
        self.sequence = sequence
        kindIdentifier = kind.rawValue
        self.paragraphNumber = paragraphNumber
        self.relativeAudioPath = relativeAudioPath
        self.duration = duration
        self.fillerCount = fillerCount
        self.pace = pace
        self.stability = stability
        self.transcript = transcript
        self.transcriptSegmentsData = transcriptSegmentsData
    }
}

struct RecordingArchiveAttemptDraft: Equatable {
    let id: UUID
    let capturedAt: Date
    let kind: RecordingArchiveAttemptKind
    let paragraphNumber: Int?
    let temporaryAudioURL: URL
    let duration: TimeInterval
    let fillerCount: Int?
    let pace: Int?
    let stability: Int?
    let transcript: String
    let transcriptSegments: [SpeechTextSegment]
    let source: ResultSource

    init(
        id: UUID = UUID(),
        capturedAt: Date = .now,
        kind: RecordingArchiveAttemptKind,
        paragraphNumber: Int? = nil,
        temporaryAudioURL: URL,
        duration: TimeInterval,
        fillerCount: Int? = nil,
        pace: Int? = nil,
        stability: Int? = nil,
        transcript: String = "",
        transcriptSegments: [SpeechTextSegment] = [],
        source: ResultSource
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.kind = kind
        self.paragraphNumber = paragraphNumber
        self.temporaryAudioURL = temporaryAudioURL
        self.duration = duration
        self.fillerCount = fillerCount
        self.pace = pace
        self.stability = stability
        self.transcript = transcript
        self.transcriptSegments = transcriptSegments
        self.source = source
    }
}

struct RecordingArchiveSessionDraft: Equatable {
    let id: UUID
    let createdAt: Date
    let kind: RecordingArchiveSessionKind
    let title: String
    let language: PracticeLanguage
    let context: PracticeContext
    let paragraphCount: Int?
    let attempts: [RecordingArchiveAttemptDraft]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: RecordingArchiveSessionKind,
        title: String,
        language: PracticeLanguage,
        context: PracticeContext,
        paragraphCount: Int? = nil,
        attempts: [RecordingArchiveAttemptDraft]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.title = title
        self.language = language
        self.context = context
        self.paragraphCount = paragraphCount
        self.attempts = attempts
    }
}

struct RecordingArchiveAttemptSummary: Identifiable, Equatable {
    let id: UUID
    let capturedAt: Date
    let sequence: Int
    let kind: RecordingArchiveAttemptKind
    let paragraphNumber: Int?
    let relativeAudioPath: String
    let audioURL: URL
    let audioIsAvailable: Bool
    let duration: TimeInterval
    let fillerCount: Int?
    let pace: Int?
    let stability: Int?
    let transcript: String
    let transcriptSegments: [SpeechTextSegment]

    init(
        id: UUID,
        capturedAt: Date,
        sequence: Int,
        kind: RecordingArchiveAttemptKind,
        paragraphNumber: Int?,
        relativeAudioPath: String,
        audioURL: URL,
        audioIsAvailable: Bool,
        duration: TimeInterval,
        fillerCount: Int?,
        pace: Int?,
        stability: Int?,
        transcript: String = "",
        transcriptSegments: [SpeechTextSegment] = []
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.sequence = sequence
        self.kind = kind
        self.paragraphNumber = paragraphNumber
        self.relativeAudioPath = relativeAudioPath
        self.audioURL = audioURL
        self.audioIsAvailable = audioIsAvailable
        self.duration = duration
        self.fillerCount = fillerCount
        self.pace = pace
        self.stability = stability
        self.transcript = transcript
        self.transcriptSegments = transcriptSegments
    }

    var displayName: String {
        switch kind {
        case .initial:
            "第一次錄音"
        case .fullRetry:
            "完整重錄"
        case .segmentRetry:
            paragraphNumber.map { "第 \($0) 段重錄" } ?? "單段重錄"
        }
    }
}

struct RecordingArchiveSessionSummary: Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let completedAt: Date
    let kind: RecordingArchiveSessionKind
    let title: String
    let language: PracticeLanguage
    let context: PracticeContext
    let paragraphCount: Int?
    let attempts: [RecordingArchiveAttemptSummary]

    var typeLabel: String {
        switch kind {
        case .shortPractice:
            return kind.displayName
        case .scriptPractice:
            guard let paragraphCount else { return kind.displayName }
            return "\(kind.displayName) · \(paragraphCount) 段"
        }
    }

    var totalDuration: TimeInterval {
        attempts.reduce(0) { $0 + $1.duration }
    }
}

enum RecordingArchiveError: Error, Equatable, LocalizedError {
    case emptySession
    case duplicateSession
    case duplicateAttempt
    case unsupportedSource
    case invalidClassification
    case audioFileMissing
    case unsupportedAudioExtension
    case fileImportFailed
    case databaseWriteFailed
    case sessionNotFound
    case fileCleanupFailed

    var errorDescription: String? {
        switch self {
        case .emptySession:
            "這次練習沒有可保存的錄音。"
        case .duplicateSession, .duplicateAttempt:
            "這筆錄音已經保存。"
        case .unsupportedSource:
            "示範錄音不會加入練習紀錄。"
        case .invalidClassification:
            "錄音分類與練習模式不一致。"
        case .audioFileMissing:
            "找不到這次錄音的暫存音檔。"
        case .unsupportedAudioExtension:
            "這個音檔格式目前無法保存。"
        case .fileImportFailed:
            "無法把錄音移入練習紀錄。"
        case .databaseWriteFailed:
            "無法更新練習紀錄。"
        case .sessionNotFound:
            "找不到這次練習紀錄。"
        case .fileCleanupFailed:
            "紀錄已刪除，但音檔清理尚未完成。"
        }
    }
}

@MainActor
final class RecordingArchiveStore {
    static let supportedAudioExtensions = ["aac", "aif", "aiff", "caf", "m4a", "wav"]

    let recordingsRootURL: URL

    private let modelContext: ModelContext
    private let fileManager: FileManager

    init(
        modelContext: ModelContext,
        recordingsRootURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        self.modelContext = modelContext
        self.fileManager = fileManager

        if let recordingsRootURL {
            self.recordingsRootURL = recordingsRootURL.standardizedFileURL
        } else {
            let applicationSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.recordingsRootURL = applicationSupport
                .appendingPathComponent("TalkFit", isDirectory: true)
                .appendingPathComponent("Recordings", isDirectory: true)
        }

        try fileManager.createDirectory(
            at: self.recordingsRootURL,
            withIntermediateDirectories: true
        )
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var root = self.recordingsRootURL
        try? root.setResourceValues(values)
    }

    func fetchAll() -> [RecordingArchiveSessionSummary] {
        let sessionDescriptor = FetchDescriptor<RecordingArchiveSessionRecord>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        let attemptDescriptor = FetchDescriptor<RecordingArchiveAttemptRecord>(
            sortBy: [
                SortDescriptor(\.sessionID),
                SortDescriptor(\.sequence)
            ]
        )
        guard let sessions = try? modelContext.fetch(sessionDescriptor),
              let attempts = try? modelContext.fetch(attemptDescriptor) else {
            return []
        }
        let attemptsBySession = Dictionary(grouping: attempts, by: \.sessionID)
        return sessions.map { session in
            makeSummary(
                session: session,
                attempts: attemptsBySession[session.id] ?? []
            )
        }
    }

    @discardableResult
    func importSession(
        _ draft: RecordingArchiveSessionDraft,
        completedAt: Date = .now
    ) throws -> RecordingArchiveSessionSummary {
        try validate(draft)

        let sessionDirectory = directoryURL(for: draft.id)
        do {
            try fileManager.createDirectory(
                at: sessionDirectory,
                withIntermediateDirectories: true
            )
            var records: [RecordingArchiveAttemptRecord] = []
            for (sequence, attempt) in draft.attempts.enumerated() {
                let pathExtension = attempt.temporaryAudioURL.pathExtension.lowercased()
                let relativePath = relativeAudioPath(
                    sessionID: draft.id,
                    attemptID: attempt.id,
                    pathExtension: pathExtension
                )
                guard let destination = audioURL(for: relativePath) else {
                    throw RecordingArchiveError.fileImportFailed
                }
                try fileManager.copyItem(at: attempt.temporaryAudioURL, to: destination)
                records.append(
                    RecordingArchiveAttemptRecord(
                        id: attempt.id,
                        sessionID: draft.id,
                        capturedAt: attempt.capturedAt,
                        sequence: sequence,
                        kind: attempt.kind,
                        paragraphNumber: attempt.paragraphNumber,
                        relativeAudioPath: relativePath,
                        duration: max(0, attempt.duration),
                        fillerCount: attempt.fillerCount,
                        pace: attempt.pace,
                        stability: attempt.stability,
                        transcript: attempt.transcript,
                        transcriptSegmentsData: try? JSONEncoder().encode(attempt.transcriptSegments)
                    )
                )
            }

            let session = RecordingArchiveSessionRecord(
                id: draft.id,
                createdAt: draft.createdAt,
                completedAt: completedAt,
                kind: draft.kind,
                title: draft.title,
                language: draft.language,
                context: draft.context,
                paragraphCount: draft.paragraphCount
            )
            modelContext.insert(session)
            records.forEach(modelContext.insert)
            do {
                try modelContext.save()
            } catch {
                modelContext.rollback()
                throw RecordingArchiveError.databaseWriteFailed
            }

            draft.attempts.forEach { attempt in
                try? fileManager.removeItem(at: attempt.temporaryAudioURL)
            }
            return makeSummary(session: session, attempts: records)
        } catch let error as RecordingArchiveError {
            try? fileManager.removeItem(at: sessionDirectory)
            throw error
        } catch {
            try? fileManager.removeItem(at: sessionDirectory)
            throw RecordingArchiveError.fileImportFailed
        }
    }

    func deleteSession(id: UUID) throws {
        let sessions = try modelContext.fetch(FetchDescriptor<RecordingArchiveSessionRecord>())
        guard let session = sessions.first(where: { $0.id == id }) else {
            throw RecordingArchiveError.sessionNotFound
        }
        let attempts = try modelContext.fetch(FetchDescriptor<RecordingArchiveAttemptRecord>())
            .filter { $0.sessionID == id }

        let sessionDirectory = directoryURL(for: id)
        let trashDirectory = recordingsRootURL
            .appendingPathComponent(".Trash", isDirectory: true)
        let quarantinedDirectory = trashDirectory
            .appendingPathComponent("\(id.uuidString.lowercased())-\(UUID().uuidString.lowercased())", isDirectory: true)
        var movedToQuarantine = false

        if fileManager.fileExists(atPath: sessionDirectory.path) {
            do {
                try fileManager.createDirectory(at: trashDirectory, withIntermediateDirectories: true)
                try fileManager.moveItem(at: sessionDirectory, to: quarantinedDirectory)
                movedToQuarantine = true
            } catch {
                throw RecordingArchiveError.fileCleanupFailed
            }
        }

        modelContext.delete(session)
        attempts.forEach(modelContext.delete)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            if movedToQuarantine {
                try? fileManager.moveItem(at: quarantinedDirectory, to: sessionDirectory)
            }
            throw RecordingArchiveError.databaseWriteFailed
        }

        guard !movedToQuarantine else {
            do {
                try fileManager.removeItem(at: quarantinedDirectory)
                return
            } catch {
                throw RecordingArchiveError.fileCleanupFailed
            }
        }
    }

    func audioURL(for relativePath: String) -> URL? {
        guard isSafe(relativePath: relativePath) else { return nil }
        let candidate = recordingsRootURL
            .appendingPathComponent(relativePath)
            .standardizedFileURL
        let rootPath = recordingsRootURL.standardizedFileURL.path
        guard candidate.path.hasPrefix(rootPath + "/") else { return nil }
        return candidate
    }

    private func validate(_ draft: RecordingArchiveSessionDraft) throws {
        guard !draft.attempts.isEmpty else {
            throw RecordingArchiveError.emptySession
        }
        let sessions = try modelContext.fetch(FetchDescriptor<RecordingArchiveSessionRecord>())
        guard !sessions.contains(where: { $0.id == draft.id }) else {
            throw RecordingArchiveError.duplicateSession
        }

        let attemptIDs = draft.attempts.map(\.id)
        guard Set(attemptIDs).count == attemptIDs.count else {
            throw RecordingArchiveError.duplicateAttempt
        }
        let storedAttempts = try modelContext.fetch(FetchDescriptor<RecordingArchiveAttemptRecord>())
        guard storedAttempts.allSatisfy({ !attemptIDs.contains($0.id) }) else {
            throw RecordingArchiveError.duplicateAttempt
        }
        guard draft.attempts.allSatisfy({ $0.source == .recognized }) else {
            throw RecordingArchiveError.unsupportedSource
        }
        guard classificationIsValid(draft) else {
            throw RecordingArchiveError.invalidClassification
        }

        for attempt in draft.attempts {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(
                atPath: attempt.temporaryAudioURL.path,
                isDirectory: &isDirectory
            ), !isDirectory.boolValue else {
                throw RecordingArchiveError.audioFileMissing
            }
            guard Self.supportedAudioExtensions.contains(
                attempt.temporaryAudioURL.pathExtension.lowercased()
            ) else {
                throw RecordingArchiveError.unsupportedAudioExtension
            }
        }
    }

    private func classificationIsValid(_ draft: RecordingArchiveSessionDraft) -> Bool {
        switch draft.kind {
        case .shortPractice:
            guard draft.paragraphCount == nil else { return false }
            return draft.attempts.allSatisfy {
                $0.kind != .segmentRetry && $0.paragraphNumber == nil
            }
        case .scriptPractice:
            guard let paragraphCount = draft.paragraphCount,
                  paragraphCount > 0 else {
                return false
            }
            return draft.attempts.allSatisfy { attempt in
                switch attempt.kind {
                case .initial, .fullRetry:
                    attempt.paragraphNumber == nil
                case .segmentRetry:
                    if let paragraphNumber = attempt.paragraphNumber {
                        (1...paragraphCount).contains(paragraphNumber)
                    } else {
                        false
                    }
                }
            }
        }
    }

    private func makeSummary(
        session: RecordingArchiveSessionRecord,
        attempts: [RecordingArchiveAttemptRecord]
    ) -> RecordingArchiveSessionSummary {
        let summaries = attempts
            .sorted { $0.sequence < $1.sequence }
            .compactMap { attempt -> RecordingArchiveAttemptSummary? in
                guard let kind = RecordingArchiveAttemptKind(rawValue: attempt.kindIdentifier),
                      let url = audioURL(for: attempt.relativeAudioPath) else {
                    return nil
                }
                return RecordingArchiveAttemptSummary(
                    id: attempt.id,
                    capturedAt: attempt.capturedAt,
                    sequence: attempt.sequence,
                    kind: kind,
                    paragraphNumber: attempt.paragraphNumber,
                    relativeAudioPath: attempt.relativeAudioPath,
                    audioURL: url,
                    audioIsAvailable: fileManager.fileExists(atPath: url.path),
                    duration: attempt.duration,
                    fillerCount: attempt.fillerCount,
                    pace: attempt.pace,
                    stability: attempt.stability,
                    transcript: attempt.transcript ?? "",
                    transcriptSegments: attempt.transcriptSegmentsData.flatMap {
                        try? JSONDecoder().decode([SpeechTextSegment].self, from: $0)
                    } ?? []
                )
            }
        return RecordingArchiveSessionSummary(
            id: session.id,
            createdAt: session.createdAt,
            completedAt: session.completedAt,
            kind: RecordingArchiveSessionKind(rawValue: session.kindIdentifier) ?? .shortPractice,
            title: session.title,
            language: PracticeLanguage(rawValue: session.languageIdentifier) ?? .traditionalChinese,
            context: PracticeContext(rawValue: session.contextIdentifier) ?? .selfIntroduction,
            paragraphCount: session.paragraphCount,
            attempts: summaries
        )
    }

    private func directoryURL(for sessionID: UUID) -> URL {
        recordingsRootURL.appendingPathComponent(
            sessionID.uuidString.lowercased(),
            isDirectory: true
        )
    }

    private func relativeAudioPath(
        sessionID: UUID,
        attemptID: UUID,
        pathExtension: String
    ) -> String {
        "\(sessionID.uuidString.lowercased())/\(attemptID.uuidString.lowercased()).\(pathExtension)"
    }

    private func isSafe(relativePath: String) -> Bool {
        guard !relativePath.isEmpty,
              !relativePath.hasPrefix("/"),
              !relativePath.contains("\\"),
              !relativePath.split(separator: "/").contains("..") else {
            return false
        }
        return true
    }
}
