import Testing
@testable import TalkFit

struct PlaybackTranscriptProgressTests {
    @Test("播放逐字稿會依真實語音片段時間向前標示")
    func highlightsUsingSpeechSegmentTiming() {
        let transcript = "大家好，我正在練習。"
        let segments = [
            SpeechTextSegment(text: "大家好", timestamp: 0, duration: 1),
            SpeechTextSegment(text: "我正在練習", timestamp: 2, duration: 2)
        ]

        let beforeSecondSegment = PlaybackTranscriptProgress.highlightedCharacterCount(
            transcript: transcript,
            segments: segments,
            currentTime: 1.5,
            progress: 0.4
        )
        let duringSecondSegment = PlaybackTranscriptProgress.highlightedCharacterCount(
            transcript: transcript,
            segments: segments,
            currentTime: 3,
            progress: 0.7
        )
        let completed = PlaybackTranscriptProgress.highlightedCharacterCount(
            transcript: transcript,
            segments: segments,
            currentTime: 4.1,
            progress: 1
        )

        #expect(beforeSecondSegment > 0)
        #expect(duringSecondSegment > beforeSecondSegment)
        #expect(completed == transcript.count)
    }

    @Test("舊紀錄沒有時間片段時會依播放進度標示")
    func fallsBackToOverallProgress() {
        let transcript = "這是一段舊紀錄逐字稿"
        let highlighted = PlaybackTranscriptProgress.highlightedCharacterCount(
            transcript: transcript,
            segments: [],
            currentTime: 5,
            progress: 0.5
        )

        #expect(highlighted == Int((Double(transcript.count) * 0.5).rounded()))
    }
}
