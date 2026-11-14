import AVFoundation
import Foundation
import Testing
@testable import TalkFit

struct HesitationSoundDetectorTests {
    private enum Sound {
        case silence
        /// Ordinary speech: loud, spectrum keeps changing.
        case speech
        /// A held 「嗯」: loud, spectrum barely changes.
        case held
        /// A quiet steady hum, such as a fan.
        case hum

        var rms: Float {
            switch self {
            case .silence: 0.001
            case .speech: 0.02
            case .held: 0.014
            case .hum: 0.002
            }
        }

        var spectralFlux: Float {
            switch self {
            case .silence: 0.6
            case .speech: 0.65
            case .held: 0.15
            case .hum: 0.1
            }
        }
    }

    /// Builds 20 ms frames for a timeline described as (sound, seconds) runs.
    private func frames(_ timeline: [(Sound, TimeInterval)]) -> [VoiceActivityFrame] {
        let step = 0.02
        var result: [VoiceActivityFrame] = []
        var index = 0
        for (sound, seconds) in timeline {
            for _ in 0..<Int((seconds / step).rounded()) {
                result.append(
                    VoiceActivityFrame(
                        time: Double(index) * step,
                        duration: step,
                        rms: sound.rms,
                        spectralFlux: sound.spectralFlux
                    )
                )
                index += 1
            }
        }
        return result
    }

    @Test("持續穩定的有聲片段會被當成語氣聲")
    func detectsHeldSounds() {
        // 「嗯」 at 1.0–1.45 s and again right before the next sentence.
        let timeline = frames([
            (.speech, 1), (.held, 0.45), (.speech, 1.2), (.silence, 0.4),
            (.held, 0.5), (.speech, 1)
        ])
        let sounds = HesitationSoundDetector.detect(frames: timeline)

        #expect(sounds.count == 2)
        #expect(abs((sounds.first?.timestamp ?? 0) - 1) < 0.03)
        #expect(abs((sounds.first?.duration ?? 0) - 0.45) < 0.03)
        #expect(abs((sounds.last?.timestamp ?? 0) - 3.05) < 0.03)
    }

    @Test("正常說話、安靜停頓與太短的穩定音不算語氣聲")
    func ignoresSpeechSilenceAndShortVowels() {
        let timeline = frames([
            (.speech, 1.5), (.silence, 0.6), (.speech, 0.8), (.held, 0.34), (.speech, 1)
        ])

        #expect(HesitationSoundDetector.detect(frames: timeline).isEmpty)
    }

    @Test("小聲的背景嗡嗡聲與過長的穩定音不算語氣聲")
    func ignoresQuietHumAndVeryLongTones() {
        let hum = frames([(.speech, 1.5), (.hum, 1), (.speech, 1.5)])
        #expect(HesitationSoundDetector.detect(frames: hum).isEmpty)

        let longTone = frames([(.speech, 1.5), (.held, 3), (.speech, 1.5)])
        #expect(HesitationSoundDetector.detect(frames: longTone).isEmpty)
    }

    @Test("資料太少或整段安靜時不猜測")
    func staysSilentWithoutEnoughAudio() {
        #expect(HesitationSoundDetector.detect(frames: []).isEmpty)
        #expect(HesitationSoundDetector.detect(frames: frames([(.silence, 3)])).isEmpty)
    }

    @Test("辨識器已寫出語氣詞的時間點不會再加一次，一般贅字不影響")
    func skipsSoundsAlreadyWrittenAsHesitationWords() {
        let sounds = [
            HesitationSound(timestamp: 1.3, duration: 0.5),
            HesitationSound(timestamp: 6, duration: 0.4)
        ]
        let existing = [
            FillerEvidence(word: "嗯", timestamp: 1.4, confidence: 0.6, source: .partial),
            // A real word next to a hesitation is a different event.
            FillerEvidence(word: "然後", timestamp: 6.3, confidence: 0.9, source: .final)
        ]
        let evidence = HesitationSoundDetector.evidence(
            from: sounds,
            existing: existing,
            language: .traditionalChinese
        )

        #expect(evidence.count == 1)
        #expect(evidence.first?.word == "語氣聲")
        #expect(evidence.first?.timestamp == 6)
        #expect(evidence.first?.source == .acoustic)
    }

    @Test("聲音偵測到的語氣聲會計入贅字總數並列在聲音證據")
    func acousticEvidenceCountsTowardFillerTotal() {
        let capture = SpeechCapture(
            readableTranscript: "我最近在做專題。",
            analysisTranscript: "我最近在做專題。",
            fillerEvidence: [
                FillerEvidence(word: "語氣聲", timestamp: 1.3, confidence: 0.5, source: .acoustic),
                FillerEvidence(word: "語氣聲", timestamp: 4, confidence: 0.5, source: .acoustic)
            ],
            segments: [],
            source: .recognized
        )
        let result = TalkFitAnalyzer.makeResult(
            capture: capture,
            duration: 6,
            round: .first,
            language: .traditionalChinese,
            fillerWords: PracticeLanguage.traditionalChinese.defaultFillerWords
        )

        #expect(result.fillerTotal == 2)
        #expect(result.additionalFillerEvidence.map(\.word) == ["語氣聲", "語氣聲"])
    }

    @Test("錄音器對持續音給出低頻譜變化、對雜訊給出高頻譜變化")
    func recorderMeasuresSpectralSteadiness() throws {
        let sampleRate = 48_000.0
        let format = try #require(
            AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        )
        // Delivered in 4 800-sample buffers like the real tap: 1 s of a held
        // 180 Hz voice-like tone with harmonics, then 1 s of noise.
        var samples: [Float] = []
        for index in 0..<48_000 {
            let time = Double(index) / sampleRate
            let tone = sin(2 * .pi * 180 * time) + 0.5 * sin(2 * .pi * 360 * time)
                + 0.25 * sin(2 * .pi * 540 * time)
            samples.append(Float(0.05 * tone))
        }
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<48_000 {
            samples.append(Float.random(in: -0.05...0.05, using: &generator))
        }

        let recorder = VoiceActivityRecorder()
        for start in stride(from: 0, to: samples.count, by: 4_800) {
            let buffer = try #require(
                AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4_800)
            )
            buffer.frameLength = 4_800
            let channel = try #require(buffer.floatChannelData?.pointee)
            for offset in 0..<4_800 { channel[offset] = samples[start + offset] }
            recorder.append(buffer)
        }
        let recorded = recorder.snapshot()

        #expect(recorded.count > 90)
        #expect(abs(recorded[10].time - 0.2) < 0.0001)
        let tone = recorded.filter { $0.time > 0.1 && $0.time < 0.9 }
        let noise = recorded.filter { $0.time > 1.1 && $0.time < 1.9 }
        #expect(tone.allSatisfy { $0.spectralFlux < 0.1 })
        #expect(noise.allSatisfy { $0.spectralFlux > 0.4 })
        #expect(abs(tone[5].rms - 0.0405) < 0.004)

        let sounds = HesitationSoundDetector.detect(frames: recorded)
        #expect(sounds.count == 1)
        #expect(abs((sounds.first?.duration ?? 0) - 1) < 0.1)
    }
}

struct LivePaceTests {
    private func capture(_ text: String, segments: [SpeechTextSegment]) -> SpeechCapture {
        SpeechCapture(
            readableTranscript: text,
            analysisTranscript: text,
            fillerEvidence: [],
            segments: segments,
            source: .recognized
        )
    }

    @Test("錄音中沒有時間戳的字詞不會被算成極快的語速")
    func placeholderTimingsDoNotInflatePace() {
        let text = "我現在在想要測試然後這就是我的一些逐字稿練習"
        // Partial results: every segment at time zero with no duration.
        let segments = text.map { SpeechTextSegment(text: String($0), timestamp: 0, duration: 0) }
        let live = capture(text, segments: segments)

        #expect(!TranscriptSentenceSegmenter.hasReliableTiming(
            capture: live,
            language: .traditionalChinese
        ))
        let feedback = TalkFitAnalyzer.sentencePaceFeedback(
            capture: live,
            duration: 12,
            language: .traditionalChinese
        )
        // 22 characters over 12 seconds is 110 per minute: slow, not fast.
        #expect(feedback.allSatisfy { $0.pace < 170 })
        #expect(feedback.allSatisfy { $0.state == .slow })
    }

    @Test("有真實時間戳時仍使用字詞時間")
    func realTimingsAreStillUsed() {
        let text = "我現在在想要測試"
        let segments = text.enumerated().map { index, character in
            SpeechTextSegment(text: String(character), timestamp: Double(index) * 0.3, duration: 0.3)
        }

        #expect(TranscriptSentenceSegmenter.hasReliableTiming(
            capture: capture(text, segments: segments),
            language: .traditionalChinese
        ))
    }

    @Test("即時語速依時鐘計算，慢慢說會得到慢的數字")
    func livePaceFollowsTheClock() {
        var slow = LivePaceEstimator()
        var slowPace: Int?
        // One character per second.
        for second in 1...10 {
            slowPace = slow.record(time: Double(second), units: second)
        }
        #expect(slowPace == 60)

        var fast = LivePaceEstimator()
        var fastPace: Int?
        // Five characters per second, delivered in bursts every half second.
        for step in 1...20 {
            fastPace = fast.record(time: Double(step) * 0.5, units: step * 5 / 2)
        }
        #expect(abs((fastPace ?? 0) - 300) < 20)
    }

    @Test("一次突然變快的讀數不會讓顯示值跟著暴衝")
    func livePaceIsSmoothed() {
        var estimator = LivePaceEstimator()
        var pace: Int?
        // Steady 3 characters per second (180 per minute)…
        for second in 1...10 {
            pace = estimator.record(time: Double(second), units: second * 3)
        }
        #expect(pace == 180)
        // …then the recognizer dumps 12 characters at once.
        pace = estimator.record(time: 10.5, units: 42)
        #expect((pace ?? 0) < 240)
    }

    @Test("錄音中略高於舒服區間不算太快，明顯超過才算")
    func livePaceVerdictHasHeadroom() {
        let context = PracticeContext.selfIntroduction
        // Comfortable range for a Chinese self-introduction is 170–260.
        #expect(context.livePaceState(for: 280, language: .traditionalChinese) == .steady)
        #expect(context.livePaceState(for: 300, language: .traditionalChinese) == .fast)
        #expect(context.livePaceState(for: 150, language: .traditionalChinese) == .slow)
        // The finished report keeps the exact range.
        #expect(context.paceState(for: 280, language: .traditionalChinese) == .fast)
        #expect(context.paceState(for: 250, language: .traditionalChinese) == .steady)
    }

    @Test("語音太少時先不顯示語速，重設後重新累積")
    func livePaceWaitsForEnoughSpeech() {
        var estimator = LivePaceEstimator()
        #expect(estimator.record(time: 1, units: 0) == nil)
        #expect(estimator.record(time: 1.5, units: 4) == nil)
        #expect(estimator.record(time: 3, units: 9) == nil)
        #expect(estimator.record(time: 4.5, units: 13) == nil)
        #expect(estimator.record(time: 6, units: 17) != nil)

        estimator.reset()
        #expect(estimator.record(time: 9, units: 30) == nil)
    }
}
