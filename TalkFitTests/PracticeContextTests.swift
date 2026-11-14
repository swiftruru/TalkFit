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
                for: 255,
                language: .traditionalChinese
            ) == .steady
        )
        #expect(
            PracticeContext.presentation.paceState(
                for: 255,
                language: .traditionalChinese
            ) == .fast
        )
        #expect(
            PracticeContext.interview.paceState(
                for: 170,
                language: .english
            ) == .fast
        )
        #expect(
            PracticeContext.selfIntroduction.paceState(
                for: 170,
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
                    duration: 1.4
                )
            ],
            source: .recognized
        )

        let introduction = try #require(TalkFitAnalyzer.sentencePaceFeedback(
            capture: capture,
            duration: 1.4,
            language: .traditionalChinese,
            context: .selfIntroduction
        ).first)
        let presentation = try #require(TalkFitAnalyzer.sentencePaceFeedback(
            capture: capture,
            duration: 1.4,
            language: .traditionalChinese,
            context: .presentation
        ).first)

        #expect(introduction.pace == 257)
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

struct ReferenceScriptTests {
    @Test("每個情境的贅字版講稿都有足夠贅字，正常版完全沒有")
    func fillerAndCleanScriptsDiffer() {
        for language in PracticeLanguage.allCases {
            for context in PracticeContext.allCases {
                let fillers = language.defaultFillerWords
                let filler = context.recordingScript(for: language, style: .withFillers)
                let clean = context.recordingScript(for: language, style: .clean)
                let fillerCount = TalkFitAnalyzer.fillerCounts(
                    in: filler,
                    fillerWords: fillers,
                    language: language
                ).values.reduce(0, +)
                let cleanCount = TalkFitAnalyzer.fillerCounts(
                    in: clean,
                    fillerWords: fillers,
                    language: language
                ).values.reduce(0, +)

                #expect(fillerCount == 4, "\(context.rawValue) \(language.rawValue)")
                #expect(cleanCount == 0, "\(context.rawValue) \(language.rawValue)")
                #expect(context.defaultRecordingScript(for: language) == clean)
            }
        }
    }

    @Test("只有贅字版會把贅字標成橘色")
    func onlyFillerVersionHighlightsFillers() {
        let language = PracticeLanguage.traditionalChinese
        let script = PracticeContext.selfIntroduction.recordingScript(
            for: language,
            style: .withFillers
        )
        let highlighted = ReferenceScriptStyle.withFillers.displayText(
            script,
            fillerWords: language.defaultFillerWords,
            language: language
        )
        let plain = ReferenceScriptStyle.clean.displayText(
            script,
            fillerWords: language.defaultFillerWords,
            language: language
        )

        #expect(highlighted.runs.filter { $0.backgroundColor != nil }.count == 4)
        #expect(plain.runs.allSatisfy { $0.backgroundColor == nil })
        #expect(String(highlighted.characters) == script)
    }
}
