import Foundation

enum FillerEvidenceReducer {
    static func upsert(
        _ candidate: FillerEvidence,
        into evidence: inout [FillerEvidence]
    ) {
        if let index = evidence.firstIndex(where: {
            $0.word == candidate.word && abs($0.timestamp - candidate.timestamp) < 0.28
        }) {
            let existing = evidence[index]
            if rank(candidate) > rank(existing)
                || (rank(candidate) == rank(existing) && candidate.confidence > existing.confidence) {
                evidence[index] = FillerEvidence(
                    id: existing.id,
                    word: candidate.word,
                    timestamp: candidate.timestamp,
                    confidence: candidate.confidence,
                    source: candidate.source
                )
            }
            return
        }
        evidence.append(candidate)
    }

    private static func rank(_ evidence: FillerEvidence) -> Int {
        switch evidence.source {
        case .final: 3
        case .partial: 2
        case .alternative: 1
        case .sample: 0
        }
    }
}
