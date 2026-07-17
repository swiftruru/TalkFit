import Foundation
import Testing
@testable import TalkFit

struct PracticeContextTests {
    @Test("四種情境都有獨立的雙語題目與示範內容")
    func contextsHaveDistinctBilingualContent() {
        #expect(PracticeContext.allCases.count == 4)

        for language in PracticeLanguage.allCases {
            let titles = PracticeContext.allCases.map { $0.promptTitle(for: language) }
            let prompts = PracticeContext.allCases.map { $0.prompt(for: language) }
            let samples = PracticeContext.allCases.map {
                $0.sampleTranscript(for: .first, language: language)
            }

            #expect(Set(titles).count == 4)
            #expect(Set(prompts).count == 4)
            #expect(Set(samples).count == 4)
            #expect(prompts.allSatisfy { !$0.isEmpty })
        }
    }

    @Test("每種短講情境都有獨立的雙語預設講稿")
    func contextsHaveDefaultRecordingScripts() {
        for language in PracticeLanguage.allCases {
            let scripts = PracticeContext.allCases.map {
                $0.defaultRecordingScript(for: language)
            }

            #expect(Set(scripts).count == PracticeContext.allCases.count)
            #expect(scripts.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        }
    }

    @Test("相同語速會依練習情境得到不同判定")
    func paceRangesDependOnContext() {
        #expect(
            PracticeContext.selfIntroduction.paceState(
                for: 225,
                language: .traditionalChinese
            ) == .steady
        )
        #expect(
            PracticeContext.presentation.paceState(
                for: 225,
                language: .traditionalChinese
            ) == .fast
        )
        #expect(
            PracticeContext.interview.paceState(
                for: 145,
                language: .english
            ) == .fast
        )
        #expect(
            PracticeContext.selfIntroduction.paceState(
                for: 145,
                language: .english
            ) == .steady
        )
    }

    @Test("逐句語速分析會帶入所選情境")
    func sentenceFeedbackUsesSelectedContext() throws {
        let capture = SpeechCapture(
            readableTranscript: "今天介紹產品",
            analysisTranscript: "今天介紹產品",
            fillerEvidence: [],
            segments: [
                SpeechTextSegment(
                    text: "今天介紹產品",
                    timestamp: 0,
                    duration: 1.6
                )
            ],
            source: .recognized
        )

        let introduction = try #require(TalkFitAnalyzer.sentencePaceFeedback(
            capture: capture,
            duration: 1.6,
            language: .traditionalChinese,
            context: .selfIntroduction
        ).first)
        let presentation = try #require(TalkFitAnalyzer.sentencePaceFeedback(
            capture: capture,
            duration: 1.6,
            language: .traditionalChinese,
            context: .presentation
        ).first)

        #expect(introduction.pace == 225)
        #expect(introduction.state == .steady)
        #expect(presentation.state == .fast)
        #expect(presentation.suggestion.contains("觀眾"))
    }

    @Test("Apple Speech hints 會包含目前情境的語句")
    func recognitionHintsIncludeContext() {
        let hints = PracticeLanguage.english.recognitionHints(
            fillerWords: PracticeLanguage.english.defaultFillerWords,
            context: .interview
        )

        #expect(hints.contains("interview answer"))
        #expect(!hints.contains("thirty second self introduction"))
    }

    @Test("每種情境的示範重練都比第一次更少贅字")
    func demoRetryImprovesEveryContext() {
        for context in PracticeContext.allCases {
            for language in PracticeLanguage.allCases {
                let first = TalkFitFixtures.sampleCapture(
                    for: .first,
                    language: language,
                    context: context,
                    fillerWords: language.defaultFillerWords
                )
                let retry = TalkFitFixtures.sampleCapture(
                    for: .retry,
                    language: language,
                    context: context,
                    fillerWords: language.defaultFillerWords
                )
                let firstCount = TalkFitAnalyzer.fillerCounts(
                    in: first.analysisTranscript,
                    fillerWords: language.defaultFillerWords,
                    language: language
                ).values.reduce(0, +)
                let retryCount = TalkFitAnalyzer.fillerCounts(
                    in: retry.analysisTranscript,
                    fillerWords: language.defaultFillerWords,
                    language: language
                ).values.reduce(0, +)

                #expect(firstCount > retryCount)
            }
        }
    }
}
