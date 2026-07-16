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
        switch self {
        case .traditionalChinese: "30 秒自我介紹"
        case .english: "30-second introduction"
        }
    }

    var prompt: String {
        switch self {
        case .traditionalChinese:
            "介紹你是誰、最近在做什麼，以及一件你想讓別人記住的事。"
        case .english:
            "Introduce who you are, what you are working on, and one thing you want people to remember."
        }
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
        switch self {
        case .traditionalChinese:
            "大家好，我是小安，目前在台北學習產品設計。嗯，我最近和同學一起做校園服務的專題，然後也開始練習把想法說得更清楚。其實我很喜歡觀察生活裡的小細節，就是希望未來能做出讓人感到貼心、又真正解決問題的產品。"
        case .english:
            "Hi, I'm Mia, a product design student in Taipei. Um, I'm learning how to turn everyday observations into clear product ideas, and I also practice presenting those ideas with confidence. Actually, I care about making technology feel calm and thoughtful. In the future, I hope to build products that help people finish important tasks without feeling overwhelmed."
        }
    }

    var sampleRetryTranscript: String {
        switch self {
        case .traditionalChinese:
            "大家好，我是小安，目前在台北學習產品設計。我最近和同學一起做校園服務的專題，也練習把想法說得更清楚。我喜歡觀察生活裡的小細節，希望未來能做出貼心、又真正解決問題的產品。"
        case .english:
            "Hi, I'm Mia, a product design student in Taipei. I'm learning to turn everyday observations into clear product ideas and present them with confidence. I care about calm, thoughtful technology, and I hope to build products that help people finish important tasks without feeling overwhelmed."
        }
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
        if pace < comfortablePace.lowerBound { return .slow }
        if pace > comfortablePace.upperBound { return .fast }
        return .steady
    }

    func recognitionHints(fillerWords: [String]) -> [String] {
        let phrases: [String]
        switch self {
        case .traditionalChinese:
            phrases = fillerWords + ["嗯，我", "呃，我想", "然後我", "就是說", promptTitle]
        case .english:
            phrases = fillerWords + ["um I", "uh I think", "you know", "I mean", promptTitle]
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

    init(id: UUID = UUID(), text: String, pace: Int, state: PaceState) {
        self.id = id
        self.text = text
        self.pace = pace
        self.state = state
    }
}
