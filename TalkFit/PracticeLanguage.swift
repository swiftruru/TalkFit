import Foundation

enum PracticeLanguage: String, CaseIterable, Identifiable, Equatable {
    case traditionalChinese
    case english

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .traditionalChinese: "中文"
        case .english: "English"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .traditionalChinese: "zh-TW"
        case .english: "en-US"
        }
    }

    var promptTitle: String {
        PracticeContext.selfIntroduction.promptTitle(for: self)
    }

    var prompt: String {
        PracticeContext.selfIntroduction.prompt(for: self)
    }

    var defaultFillerWords: [String] {
        switch self {
        case .traditionalChinese:
            ["嗯", "呃", "然後", "就是", "這個", "那個", "其實", "對"]
        case .english:
            ["um", "uh", "like", "you know", "actually", "basically", "so", "right"]
        }
    }

    var sampleFirstTranscript: String {
        PracticeContext.selfIntroduction.sampleTranscript(for: .first, language: self)
    }

    var sampleRetryTranscript: String {
        PracticeContext.selfIntroduction.sampleTranscript(for: .retry, language: self)
    }

    var paceUnit: String {
        switch self {
        case .traditionalChinese: "字／分鐘"
        case .english: "詞／分鐘"
        }
    }

    var comfortablePace: ClosedRange<Int> {
        switch self {
        case .traditionalChinese: 170...235
        case .english: 110...160
        }
    }

    var paceScaleRange: ClosedRange<Int> {
        switch self {
        case .traditionalChinese: 110...300
        case .english: 70...210
        }
    }

    var minimumUsableUnits: Int {
        switch self {
        case .traditionalChinese: 8
        case .english: 4
        }
    }

    func normalizeFiller(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return self == .english ? trimmed.lowercased() : trimmed
    }

    func speechUnitCount(in text: String) -> Int {
        switch self {
        case .traditionalChinese:
            let scalars = Array(text.unicodeScalars)
            var insideLatinToken = false
            return scalars.enumerated().reduce(into: 0) { count, entry in
                let (index, scalar) = entry
                if (0x4E00...0x9FFF).contains(scalar.value) {
                    count += 1
                    insideLatinToken = false
                } else if scalar.isASCII,
                          CharacterSet.alphanumerics.contains(scalar) || scalar.value == 39 {
                    if !insideLatinToken { count += 1 }
                    insideLatinToken = true
                } else if scalar.value == 46,
                          insideLatinToken,
                          scalars.indices.contains(index + 1),
                          CharacterSet.decimalDigits.contains(scalars[index + 1]) {
                    // Keep decimal numbers such as 2.0 inside one mixed-language token.
                } else {
                    insideLatinToken = false
                }
            }
        case .english:
            return text.split { character in
                !character.isLetter && !character.isNumber && character != "'"
            }.count
        }
    }

    func paceState(for pace: Int) -> PaceState {
        PracticeContext.selfIntroduction.paceState(for: pace, language: self)
    }

    func recognitionHints(
        fillerWords: [String],
        context: PracticeContext = .selfIntroduction
    ) -> [String] {
        let phrases: [String]
        switch self {
        case .traditionalChinese:
            phrases = fillerWords + ["嗯，我", "呃，我想", "然後我", "就是說", context.recognitionHint(for: self)]
        case .english:
            phrases = fillerWords + ["um I", "uh I think", "you know", "I mean", context.recognitionHint(for: self)]
        }
        return Array(phrases.reduce(into: [String]()) { result, phrase in
            if !result.contains(phrase) { result.append(phrase) }
        }.prefix(100))
    }

    func languageModelPhrases(fillerWords: [String]) -> [(phrase: String, count: Int)] {
        var phrases = fillerWords.map { ($0, 3_000) }
        switch self {
        case .traditionalChinese:
            phrases += [("嗯，我", 1_500), ("呃，我想", 1_200), ("然後我", 700), ("就是說", 700)]
        case .english:
            phrases += [("um I", 1_500), ("uh I think", 1_200), ("you know", 1_000), ("I mean", 700)]
        }
        return phrases
    }
}

enum PaceState: Equatable {
    case slow
    case steady
    case fast

    var label: String {
        switch self {
        case .slow: "稍慢"
        case .steady: "舒服"
        case .fast: "稍快"
        }
    }

    var suggestion: String {
        switch self {
        case .slow: "可以把相近詞連起來，讓句子更連貫。"
        case .steady: "節奏舒服，保留現在的自然停頓。"
        case .fast: "句尾多留半拍，讓重點更容易被聽見。"
        }
    }
}

enum SentencePauseState: Equatable {
    case short
    case balanced
    case long

    var label: String {
        switch self {
        case .short: "太短"
        case .balanced: "剛好"
        case .long: "稍長"
        }
    }

    var suggestion: String {
        switch self {
        case .short: "句尾再多留半拍，讓下一句的重點有空間。"
        case .balanced: "這個句尾停頓很自然，保留現在的節奏。"
        case .long: "停頓稍久，可以先接住下一句再繼續想。"
        }
    }
}

struct SpeechTextSegment: Identifiable, Equatable {
    let id: UUID
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        text: String,
        timestamp: TimeInterval,
        duration: TimeInterval
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.duration = duration
    }
}

struct SentencePaceFeedback: Identifiable, Equatable {
    let id: UUID
    let text: String
    let pace: Int
    let state: PaceState
    let context: PracticeContext
    let pauseAfter: TimeInterval?
    let pauseState: SentencePauseState?
    let paceChange: Int?
    let isSuddenAcceleration: Bool

    init(
        id: UUID = UUID(),
        text: String,
        pace: Int,
        state: PaceState,
        context: PracticeContext = .selfIntroduction,
        pauseAfter: TimeInterval? = nil,
        pauseState: SentencePauseState? = nil,
        paceChange: Int? = nil,
        isSuddenAcceleration: Bool = false
    ) {
        self.id = id
        self.text = text
        self.pace = pace
        self.state = state
        self.context = context
        self.pauseAfter = pauseAfter
        self.pauseState = pauseState
        self.paceChange = paceChange
        self.isSuddenAcceleration = isSuddenAcceleration
    }

    var suggestion: String {
        if isSuddenAcceleration {
            return "這句突然加快，先把第一個重點說穩再往下接。"
        }
        if let pauseState, pauseState != .balanced {
            return pauseState.suggestion
        }
        return context.paceSuggestion(for: state)
    }

    var pauseDurationLabel: String? {
        guard let pauseAfter else { return nil }
        return String(format: "%.1f 秒", pauseAfter)
    }

    var rhythmIssueCount: Int {
        let pauseIssue = pauseState == .short || pauseState == .long ? 1 : 0
        return pauseIssue + (isSuddenAcceleration ? 1 : 0)
    }
}

struct RhythmSummary: Equatable {
    let measuredPauseCount: Int
    let balancedPauseCount: Int
    let shortPauseCount: Int
    let longPauseCount: Int
    let suddenAccelerationCount: Int

    init(feedback: [SentencePaceFeedback]) {
        measuredPauseCount = feedback.compactMap(\.pauseState).count
        balancedPauseCount = feedback.filter { $0.pauseState == .balanced }.count
        shortPauseCount = feedback.filter { $0.pauseState == .short }.count
        longPauseCount = feedback.filter { $0.pauseState == .long }.count
        suddenAccelerationCount = feedback.filter(\.isSuddenAcceleration).count
    }

    var issueCount: Int {
        shortPauseCount + longPauseCount + suddenAccelerationCount
    }

    var headline: String {
        if suddenAccelerationCount > 0 {
            return "有 \(suddenAccelerationCount) 句突然加快"
        }
        if shortPauseCount > 0 {
            return "有 \(shortPauseCount) 個句尾接得太快"
        }
        if longPauseCount > 0 {
            return "有 \(longPauseCount) 個停頓稍久"
        }
        if measuredPauseCount > 0 {
            return "句尾停頓很自然"
        }
        return "先從逐句語速看節奏"
    }

    var detail: String {
        if suddenAccelerationCount > 0 {
            return "先留意突然加快的句子，再用句尾停頓把重點分開。"
        }
        if shortPauseCount > 0 {
            return "句尾多留半拍，聽的人會更容易跟上下一個重點。"
        }
        if longPauseCount > 0 {
            return "停頓時先想好下一句的開頭，會更連貫。"
        }
        if measuredPauseCount > 0 {
            return "停頓有把句子分開，保留這個呼吸感。"
        }
        return "這次缺少足夠的時間戳，仍會保留逐句語速建議。"
    }
}
