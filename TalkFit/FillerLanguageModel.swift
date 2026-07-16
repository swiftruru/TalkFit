import Foundation
import OSLog
import Speech

enum FillerLanguageModel {
    nonisolated private static let logger = Logger(
        subsystem: "com.ru.TalkFit",
        category: "FillerLanguageModel"
    )

    nonisolated static func prepare(
        phrases: [(phrase: String, count: Int)]
    ) async -> SFSpeechLanguageModel.Configuration? {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TalkFitFillerLanguageModel-v1", isDirectory: true)
        let trainingDataURL = directory.appendingPathComponent("training-data.bin")
        let languageModelURL = directory.appendingPathComponent("language-model.bin")
        let vocabularyURL = directory.appendingPathComponent("vocabulary.bin")

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let configuration = SFSpeechLanguageModel.Configuration(
                languageModel: languageModelURL,
                vocabulary: vocabularyURL,
                weight: 1
            )
            if FileManager.default.fileExists(atPath: languageModelURL.path),
               FileManager.default.fileExists(atPath: vocabularyURL.path) {
                return configuration
            }

            let data = SFCustomLanguageModelData(
                locale: Locale(identifier: "zh-TW"),
                identifier: "com.ru.TalkFit.fillers",
                version: "1"
            )
            for item in phrases {
                data.insert(
                    phraseCount: SFCustomLanguageModelData.PhraseCount(
                        phrase: item.phrase,
                        count: item.count
                    )
                )
            }
            try await data.export(to: trainingDataURL)

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                SFSpeechLanguageModel.prepareCustomLanguageModel(
                    for: trainingDataURL,
                    configuration: configuration,
                    ignoresCache: true
                ) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            guard FileManager.default.fileExists(atPath: languageModelURL.path),
                  FileManager.default.fileExists(atPath: vocabularyURL.path) else {
                logger.error("Apple Speech 未產生自訂語言模型輸出；將使用 contextual hints。")
                return nil
            }
            return configuration
        } catch {
            logger.error("準備贅字語言模型失敗：\(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
