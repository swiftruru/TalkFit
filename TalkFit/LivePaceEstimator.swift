import Foundation

/// Estimates speaking pace while a recording is still in progress.
///
/// Live partial results carry no usable word timings, so pace is measured
/// from the clock instead: how many speech units appeared in the transcript
/// over the last few seconds.
struct LivePaceEstimator: Equatable {
    /// How far back the estimate looks.
    var window: TimeInterval = 8
    /// Minimum stretch of speech needed before showing a number. A shorter
    /// stretch is dominated by how the recognizer batches its updates.
    var minimumSpan: TimeInterval = 4
    /// How much of each new reading is blended into the shown value. The
    /// recognizer delivers words in bursts, so raw readings jump around.
    var smoothing: Double = 0.5

    private var samples: [Sample] = []
    private var smoothedPace: Double?

    private struct Sample: Equatable {
        let time: TimeInterval
        let units: Int
    }

    /// Records that the transcript held `units` speech units at `time`
    /// seconds into the recording, and returns the current pace in units per
    /// minute, or `nil` while there is too little speech to judge.
    mutating func record(time: TimeInterval, units: Int) -> Int? {
        guard units > 0 else { return nil }
        if let last = samples.last, time <= last.time {
            // Same instant: keep only the newest reading.
            samples.removeLast()
        }
        samples.append(Sample(time: time, units: units))
        samples.removeAll { time - $0.time > window }

        guard let baseline = samples.first else { return nil }
        let span = time - baseline.time
        guard span >= minimumSpan else { return nil }
        // The recognizer may revise earlier words, so the count can dip.
        let gained = max(0, units - baseline.units)
        let reading = Double(gained) / span * 60
        let pace = smoothedPace.map { $0 + (reading - $0) * smoothing } ?? reading
        smoothedPace = pace
        return Int(pace.rounded())
    }

    mutating func reset() {
        samples.removeAll()
        smoothedPace = nil
    }
}
