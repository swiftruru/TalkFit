import Accelerate
import AVFoundation

/// One short analysis step of microphone audio.
nonisolated struct VoiceActivityFrame: Equatable, Sendable {
    /// Seconds from the start of the recording to the start of this step.
    let time: TimeInterval
    let duration: TimeInterval
    let rms: Float
    /// How much the shape of the voice spectrum changed since the previous
    /// step, from 0 (identical) to about 1.4 (unrelated). A held 「嗯」 stays
    /// near 0.1–0.3; ordinary speech moves between syllables and sits
    /// around 0.5–0.8.
    let spectralFlux: Float
}

/// Collects `VoiceActivityFrame`s from the audio tap.
///
/// `append` must only be called from the audio thread; `snapshot` may be
/// called from anywhere.
nonisolated final class VoiceActivityRecorder: @unchecked Sendable {
    static let stepDuration: TimeInterval = 0.02
    private static let minimumWindowDuration: TimeInterval = 0.04
    private static let maximumVoiceFrequency: Double = 4_000

    private let lock = NSLock()
    private var frames: [VoiceActivityFrame] = []

    // Audio-thread state.
    private var sampleRate: Double = 0
    private var windowLength = 0
    private var stepLength = 0
    private var log2n: vDSP_Length = 0
    private var fftSetup: FFTSetup?
    private var window: [Float] = []
    private var windowed: [Float] = []
    private var real: [Float] = []
    private var imaginary: [Float] = []
    private var magnitudes: [Float] = []
    private var voiceBins: Range<Int> = 0..<0
    private var previousSpectrum: [Float] = []
    private var pending: [Float] = []
    private var consumedSamples = 0

    deinit {
        if let fftSetup { vDSP_destroy_fftsetup(fftSetup) }
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?.pointee else { return }
        let sampleCount = Int(buffer.frameLength)
        guard sampleCount > 0, buffer.format.sampleRate > 0 else { return }
        if fftSetup == nil {
            configure(sampleRate: buffer.format.sampleRate)
        }
        guard fftSetup != nil else { return }

        pending.append(contentsOf: UnsafeBufferPointer(start: channel, count: sampleCount))
        var newFrames: [VoiceActivityFrame] = []
        var offset = 0
        while pending.count - offset >= windowLength {
            newFrames.append(analyzeWindow(at: offset))
            offset += stepLength
            consumedSamples += stepLength
        }
        if offset > 0 { pending.removeFirst(offset) }
        guard !newFrames.isEmpty else { return }

        lock.lock()
        frames.append(contentsOf: newFrames)
        lock.unlock()
    }

    func snapshot() -> [VoiceActivityFrame] {
        lock.lock()
        defer { lock.unlock() }
        return frames
    }

    private func configure(sampleRate: Double) {
        self.sampleRate = sampleRate
        stepLength = max(1, Int(sampleRate * Self.stepDuration))
        let minimumLength = Int(sampleRate * Self.minimumWindowDuration)
        var length = 256
        while length < minimumLength { length *= 2 }
        windowLength = length
        log2n = vDSP_Length(length.trailingZeroBitCount)
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        window = [Float](repeating: 0, count: length)
        vDSP_hann_window(&window, vDSP_Length(length), Int32(vDSP_HANN_NORM))
        windowed = [Float](repeating: 0, count: length)
        real = [Float](repeating: 0, count: length / 2)
        imaginary = [Float](repeating: 0, count: length / 2)
        magnitudes = [Float](repeating: 0, count: length / 2)
        let binWidth = sampleRate / Double(length)
        let upperBin = min(length / 2, max(2, Int(Self.maximumVoiceFrequency / binWidth)))
        voiceBins = 1..<upperBin
    }

    private func analyzeWindow(at offset: Int) -> VoiceActivityFrame {
        guard let fftSetup else {
            return VoiceActivityFrame(time: 0, duration: 0, rms: 0, spectralFlux: 1)
        }
        let half = windowLength / 2
        var rms: Float = 0
        pending.withUnsafeBufferPointer { samples in
            let start = samples.baseAddress! + offset
            vDSP_rmsqv(start, 1, &rms, vDSP_Length(windowLength))
            vDSP_vmul(start, 1, window, 1, &windowed, 1, vDSP_Length(windowLength))
        }
        windowed.withUnsafeBufferPointer { input in
            input.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: half) { complex in
                real.withUnsafeMutableBufferPointer { realPointer in
                    imaginary.withUnsafeMutableBufferPointer { imaginaryPointer in
                        var split = DSPSplitComplex(
                            realp: realPointer.baseAddress!,
                            imagp: imaginaryPointer.baseAddress!
                        )
                        vDSP_ctoz(complex, 2, &split, 1, vDSP_Length(half))
                        vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                        vDSP_zvabs(&split, 1, &magnitudes, 1, vDSP_Length(half))
                    }
                }
            }
        }

        var spectrum = Array(magnitudes[voiceBins])
        var energy: Float = 0
        vDSP_svesq(spectrum, 1, &energy, vDSP_Length(spectrum.count))
        var scale = 1 / max(energy.squareRoot(), 1e-9)
        vDSP_vsmul(spectrum, 1, &scale, &spectrum, 1, vDSP_Length(spectrum.count))

        var flux: Float = 1
        if previousSpectrum.count == spectrum.count {
            var distance: Float = 0
            vDSP_distancesq(spectrum, 1, previousSpectrum, 1, &distance, vDSP_Length(spectrum.count))
            flux = distance.squareRoot()
        }
        previousSpectrum = spectrum

        return VoiceActivityFrame(
            time: Double(consumedSamples) / sampleRate,
            duration: Double(stepLength) / sampleRate,
            rms: rms,
            spectralFlux: flux
        )
    }
}

/// A held, steady sound in the recording.
struct HesitationSound: Equatable {
    let timestamp: TimeInterval
    let duration: TimeInterval
}

/// Finds hesitation sounds (「嗯」「呃」, "um", "uh") from the audio signal
/// instead of the transcript, because Apple Speech usually drops them.
///
/// A hesitation sound is one note held for a while: loud enough to be the
/// speaker's voice, with a spectrum that barely changes. Normal speech keeps
/// moving from syllable to syllable, so it never stays that steady for long.
/// Recognizer word timings are deliberately not used; on device they stretch
/// neighbouring words over the hesitation and hide it.
enum HesitationSoundDetector {
    struct Configuration: Equatable {
        /// A frame is steady when its spectral flux is at or below this.
        var maximumSpectralFlux: Float = 0.35
        /// A frame must reach this fraction of the typical speaking level.
        var speechLevelRatio: Float = 0.3
        /// …and this multiple of the background noise floor.
        var noiseFloorMultiplier: Float = 3
        var minimumRMS: Float = 0.003
        /// Steady frames this close together are joined into one sound.
        var mergeGap: TimeInterval = 0.045
        /// Ordinary speech also holds a vowel or a nasal ending steady for
        /// a moment (measured up to about 0.34 s when reading a script with
        /// no fillers), while a deliberate 「嗯」 lasts 0.45 s or more. The
        /// bar sits between the two; very short hesitations are missed
        /// rather than flagging clean speech.
        var minimumDuration: TimeInterval = 0.4
        /// Averaged over the whole sound, a real hesitation is steadier than
        /// a vowel that merely passes the per-frame bar.
        var maximumMeanSpectralFlux: Float = 0.24
        /// Longer steady stretches are more likely a hum, a fan or music.
        var maximumDuration: TimeInterval = 2
        /// Text evidence this close to a sound means it was already counted.
        var evidenceTolerance: TimeInterval = 0.4
    }

    static func detect(
        frames: [VoiceActivityFrame],
        configuration: Configuration = Configuration()
    ) -> [HesitationSound] {
        guard frames.count >= 10 else { return [] }
        let levels = frames.map(\.rms).sorted()
        let noiseFloor = levels[levels.count / 10]
        // The louder part of the recording is the speaker's voice.
        let speechLevel = levels[levels.count * 7 / 10]
        // When someone talks almost without pausing, the quietest frames are
        // speech too, so the noise-based bar is capped below speaking level.
        let noiseBar = min(
            noiseFloor * configuration.noiseFloorMultiplier,
            speechLevel * 0.6
        )
        let threshold = max(
            configuration.minimumRMS,
            speechLevel * configuration.speechLevelRatio,
            noiseBar
        )

        var sounds: [HesitationSound] = []
        var start: TimeInterval?
        var end: TimeInterval = 0
        var fluxTotal: Float = 0
        var frameCount = 0

        func close() {
            guard let soundStart = start else { return }
            let duration = end - soundStart
            let meanFlux = fluxTotal / Float(max(1, frameCount))
            if duration >= configuration.minimumDuration,
               duration <= configuration.maximumDuration,
               meanFlux <= configuration.maximumMeanSpectralFlux {
                sounds.append(HesitationSound(timestamp: soundStart, duration: duration))
            }
            start = nil
            fluxTotal = 0
            frameCount = 0
        }

        for frame in frames {
            let isSteadyVoice = frame.rms >= threshold
                && frame.spectralFlux <= configuration.maximumSpectralFlux
            guard isSteadyVoice else { continue }
            if start != nil, frame.time - end > configuration.mergeGap {
                close()
            }
            if start == nil { start = frame.time }
            end = frame.time + frame.duration
            fluxTotal += frame.spectralFlux
            frameCount += 1
        }
        close()
        return sounds
    }

    /// Turns detected sounds into filler evidence, skipping any sound the
    /// recognizer already wrote down as a hesitation word at that moment.
    static func evidence(
        from sounds: [HesitationSound],
        existing: [FillerEvidence],
        language: PracticeLanguage,
        configuration: Configuration = Configuration()
    ) -> [FillerEvidence] {
        let hesitationWords = Set(language.hesitationWords)
        let alreadyHeard = existing
            .filter { hesitationWords.contains(language.normalizeFiller($0.word)) }
            .map(\.timestamp)
        return sounds.compactMap { sound in
            let lower = sound.timestamp - configuration.evidenceTolerance
            let upper = sound.timestamp + sound.duration + configuration.evidenceTolerance
            guard !alreadyHeard.contains(where: { (lower...upper).contains($0) }) else {
                return nil
            }
            return FillerEvidence(
                word: language.hesitationSoundLabel,
                timestamp: sound.timestamp,
                confidence: 0.5,
                source: .acoustic
            )
        }
    }
}

extension PracticeLanguage {
    /// Label for a hesitation sound heard in the audio. It is deliberately
    /// generic: the signal cannot tell 「嗯」 from 「呃」.
    var hesitationSoundLabel: String {
        switch self {
        case .traditionalChinese: "語氣聲"
        case .english: "hesitation"
        }
    }

    /// Filler words that are sounds rather than real words. Only these can
    /// stand for the same moment as an acoustically detected hesitation.
    var hesitationWords: [String] {
        switch self {
        case .traditionalChinese: ["嗯", "呃", "啊", "欸", "痾", "恩"]
        case .english: ["um", "uh", "er", "erm", "hmm", "uhm"]
        }
    }
}
