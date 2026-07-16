import Testing
@testable import TalkFit

struct ScriptPracticeTests {
    @Test("空白行會拆成段落並忽略多餘空白")
    func splitsParagraphs() {
        let paragraphs = ScriptPracticeAnalyzer.paragraphs(
            in: "  第一段重點。  \n\n\n第二段內容。\n\n 第三段收尾。 "
        )

        #expect(paragraphs.map(\.text) == ["第一段重點。", "第二段內容。", "第三段收尾。"])
        #expect(paragraphs.map(\.number) == [1, 2, 3])
    }

    @Test("沒有空白行時仍可把逐行講稿拆段")
    func splitsLineBasedScript() {
        let paragraphs = ScriptPracticeAnalyzer.paragraphs(
            in: "Opening line\nMain idea\nClosing line"
        )

        #expect(paragraphs.count == 3)
        #expect(paragraphs[1].text == "Main idea")
    }

    @Test("中文比較會計算涵蓋程度並找出未說出的內容")
    func comparesChineseScript() {
        let comparison = ScriptPracticeAnalyzer.compare(
            reference: "今天分享校園共乘服務，幫助學生找到安全的同行夥伴。",
            spoken: "今天分享校園共乘服務，幫助學生找到同行夥伴。",
            language: .traditionalChinese
        )

        #expect(comparison.coverage >= 80)
        #expect(comparison.coverage < 100)
        #expect(!comparison.missingKeywords.isEmpty)
    }

    @Test("英文比較不受大小寫與標點影響")
    func comparesEnglishScript() {
        let comparison = ScriptPracticeAnalyzer.compare(
            reference: "Students can find a safe travel partner.",
            spoken: "students can find a travel partner",
            language: .english
        )

        #expect(comparison.coverage == 86)
        #expect(comparison.missingKeywords.contains("safe"))
    }

    @Test("講稿備援保留使用者段落並只在第一次加入贅字證據")
    func scriptFallbackStaysCoherent() {
        let first = TalkFitFixtures.scriptCapture(
            for: .first,
            language: .traditionalChinese,
            script: "這是我的提案重點。",
            fillerWords: PracticeLanguage.traditionalChinese.defaultFillerWords
        )
        let retry = TalkFitFixtures.scriptCapture(
            for: .retry,
            language: .traditionalChinese,
            script: "這是我的提案重點。",
            fillerWords: PracticeLanguage.traditionalChinese.defaultFillerWords
        )

        #expect(first.readableTranscript == "這是我的提案重點。")
        #expect(first.source == .sample)
        #expect(first.fillerEvidence.contains { $0.word == "嗯" })
        #expect(retry.fillerEvidence.isEmpty)
    }

    @Test("講稿示範重練會移除原優先句中的贅字")
    func scriptRetryRemovesFiller() {
        let capture = TalkFitFixtures.scriptCapture(
            for: .retry,
            language: .english,
            script: "Um, Hello I am Mia.",
            fillerWords: PracticeLanguage.english.defaultFillerWords
        )

        #expect(capture.readableTranscript == "Hello I am Mia.")
        #expect(capture.fillerEvidence.isEmpty)
    }
}
