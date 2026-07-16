import Testing
@testable import TalkFit

struct TalkFitAnalyzerTests {
    @Test("中文模式把完整英文單字視為一個語速單位")
    func mixedLanguageUnitCount() {
        #expect(PracticeLanguage.traditionalChinese.speechUnitCount(in: "今天 demo 很順") == 5)
        #expect(PracticeLanguage.traditionalChinese.speechUnitCount(in: "介紹 TalkFit 2.0") == 4)
    }

    @Test("英文贅字只匹配完整單字")
    func englishFillerWordBoundary() {
        let counts = TalkFitAnalyzer.fillerCounts(
            in: "I like this, unlike the previous version.",
            fillerWords: ["like"],
            language: .english
        )
        #expect(counts["like"] == 1)
    }

    @Test("無標點長句會在安全邊界切分")
    func longUnpunctuatedSentence() {
        let transcript = "大家好我是小安目前正在設計 TalkFit 這個產品希望讓練習口說變得更輕鬆然後我會先介紹今天完成的功能接著分享我們觀察到的改善"
        let sentences = TranscriptSentenceSegmenter.sentences(
            in: transcript,
            language: .traditionalChinese
        )

        #expect(sentences.count >= 2)
        #expect(sentences.allSatisfy {
            PracticeLanguage.traditionalChinese.speechUnitCount(in: $0) <= 32
        })
        #expect(sentences.joined().contains("TalkFit"))
    }

    @Test("Speech segment 的明顯停頓會形成新的語速句")
    func pauseCreatesTimedSentence() {
        let capture = SpeechCapture(
            readableTranscript: "大家好我是小安今天介紹 TalkFit",
            analysisTranscript: "大家好我是小安今天介紹 TalkFit",
            fillerEvidence: [],
            segments: [
                SpeechTextSegment(text: "大家好", timestamp: 0, duration: 0.4),
                SpeechTextSegment(text: "我是小安", timestamp: 0.5, duration: 0.5),
                SpeechTextSegment(text: "今天介紹", timestamp: 2.0, duration: 0.5),
                SpeechTextSegment(text: "TalkFit", timestamp: 2.55, duration: 0.45)
            ],
            source: .recognized
        )

        let feedback = TalkFitAnalyzer.sentencePaceFeedback(
            capture: capture,
            duration: 3,
            language: .traditionalChinese
        )

        #expect(feedback.count == 2)
        #expect(feedback[1].text.contains("TalkFit"))
    }

    @Test("缺少時間 segment 時仍能按內容估算語速")
    func proportionalPaceFallback() {
        let capture = SpeechCapture(
            readableTranscript: "大家好",
            analysisTranscript: "大家好",
            fillerEvidence: [],
            segments: [],
            source: .recognized
        )

        let feedback = TalkFitAnalyzer.sentencePaceFeedback(
            capture: capture,
            duration: 1,
            language: .traditionalChinese
        )

        #expect(feedback.count == 1)
        #expect(feedback[0].pace == 180)
    }

    @Test("示範 segments 保留原本句尾邊界")
    func sampleSegmentsKeepSentenceBoundaries() {
        let language = PracticeLanguage.traditionalChinese
        let capture = TalkFitFixtures.sampleCapture(
            for: .first,
            language: language,
            fillerWords: language.defaultFillerWords
        )
        let feedback = TalkFitAnalyzer.sentencePaceFeedback(
            capture: capture,
            duration: 31,
            language: language
        )

        #expect(feedback.first?.text == "大家好，我是小安，目前在台北學習產品設計")
        #expect(!feedback.contains { $0.text.contains("產品設計我最近") })
    }

    @Test("同時間的贅字證據會去重並保留可靠來源")
    func fillerEvidenceDeduplication() {
        var evidence: [FillerEvidence] = []
        FillerEvidenceReducer.upsert(
            FillerEvidence(word: "嗯", timestamp: 1, confidence: 0.8, source: .partial),
            into: &evidence
        )
        FillerEvidenceReducer.upsert(
            FillerEvidence(word: "嗯", timestamp: 1.1, confidence: 0.5, source: .alternative),
            into: &evidence
        )
        FillerEvidenceReducer.upsert(
            FillerEvidence(word: "嗯", timestamp: 1.05, confidence: 0.7, source: .final),
            into: &evidence
        )
        FillerEvidenceReducer.upsert(
            FillerEvidence(word: "嗯", timestamp: 1.5, confidence: 0.7, source: .partial),
            into: &evidence
        )

        #expect(evidence.count == 2)
        #expect(evidence[0].source == .final)
    }
}
