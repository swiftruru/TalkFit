import Foundation

struct ScriptParagraph: Identifiable, Equatable {
    let id: Int
    let text: String

    var number: Int { id + 1 }
}

struct ScriptPracticeSession: Equatable {
    let paragraphs: [ScriptParagraph]

    var fullText: String {
        paragraphs.map(\.text).joined(separator: "\n\n")
    }

    static func make(text: String) -> ScriptPracticeSession? {
        let paragraphs = ScriptPracticeAnalyzer.paragraphs(in: text)
        guard !paragraphs.isEmpty else { return nil }
        return ScriptPracticeSession(paragraphs: paragraphs)
    }
}

struct ScriptPracticeReference: Equatable {
    let text: String
    let paragraphNumber: Int?
    let paragraphCount: Int

    init(text: String, paragraphNumber: Int? = nil, paragraphCount: Int) {
        self.text = text
        self.paragraphNumber = paragraphNumber
        self.paragraphCount = paragraphCount
    }

    var isWholeScript: Bool { paragraphNumber == nil }

    var title: String {
        if let paragraphNumber {
            return "自訂講稿 · 第 \(paragraphNumber) 段"
        }
        return "自訂講稿 · 完整 \(paragraphCount) 段"
    }
}

struct ScriptSpeechComparison: Equatable {
    let reference: String
    let spoken: String
    let coverage: Int
    let missingKeywords: [String]

    var summary: String {
        if coverage >= 85 {
            return "重點大多都有說到，接下來只要讓停頓更自然。"
        }
        if coverage >= 60 {
            return "主要內容有保留；再補回一兩個關鍵詞會更完整。"
        }
        return "先抓住兩個核心詞，不用急著一次說完整段。"
    }
}

struct ScriptParagraphFeedback: Identifiable, Equatable {
    let paragraph: ScriptParagraph
    let spokenExcerpt: String
    let comparison: ScriptSpeechComparison
    let suggestion: String

    var id: Int { paragraph.id }
}

enum ScriptPracticeAnalyzer {
    static func paragraphs(in text: String) -> [ScriptParagraph] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let blankLineParts: [String]
        if let expression = try? NSRegularExpression(pattern: "\n\\s*\n") {
            blankLineParts = normalized.components(separatedBy: expression)
        } else {
            blankLineParts = [normalized]
        }
        let rawParts: [String]
        if blankLineParts.count > 1 {
            rawParts = blankLineParts
        } else {
            rawParts = normalized.components(separatedBy: .newlines)
        }

        return rawParts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(30)
            .enumerated()
            .map { ScriptParagraph(id: $0.offset, text: $0.element) }
    }

    static func compare(
        reference: String,
        spoken: String,
        language: PracticeLanguage
    ) -> ScriptSpeechComparison {
        let referenceUnits = comparisonUnits(in: reference, language: language)
        let spokenUnits = comparisonUnits(in: spoken, language: language)
        var available = Dictionary(grouping: spokenUnits, by: { $0 }).mapValues(\.count)
        let matched = referenceUnits.reduce(into: 0) { count, unit in
            guard (available[unit] ?? 0) > 0 else { return }
            count += 1
            available[unit, default: 0] -= 1
        }
        let coverage = referenceUnits.isEmpty
            ? 0
            : Int((Double(matched) / Double(referenceUnits.count) * 100).rounded())

        return ScriptSpeechComparison(
            reference: reference,
            spoken: spoken,
            coverage: min(100, max(0, coverage)),
            missingKeywords: missingKeywords(
                reference: reference,
                spoken: spoken,
                language: language
            )
        )
    }

    static func recognitionHints(from text: String, language: PracticeLanguage) -> [String] {
        let chunks = contentChunks(in: text, language: language)
        return Array(chunks.filter { !$0.isEmpty }.prefix(20))
    }

    static func paragraphFeedback(
        paragraphs: [ScriptParagraph],
        spoken: String,
        language: PracticeLanguage
    ) -> [ScriptParagraphFeedback] {
        paragraphs.map { paragraph in
            let comparison = compare(
                reference: paragraph.text,
                spoken: spoken,
                language: language
            )
            let excerpt = proportionalExcerpt(
                for: paragraph,
                among: paragraphs,
                spoken: spoken
            )
            let suggestion: String
            if let missingKeyword = comparison.missingKeywords.first {
                suggestion = "先補回「\(missingKeyword)」，再把這段重點說完整。"
            } else if comparison.coverage < 60 {
                suggestion = "先抓住開頭和結論，不用急著逐字說完。"
            } else if comparison.coverage < 85 {
                suggestion = "主要內容有保留，放慢一點讓關鍵詞更清楚。"
            } else if paragraph.id == paragraphs.first?.id {
                suggestion = "開場重點很完整；第一句後留半拍會更從容。"
            } else if paragraph.id == paragraphs.last?.id {
                suggestion = "收尾很完整；把最後一句放慢一點會更有力量。"
            } else {
                suggestion = "核心資訊很完整；在轉折前留一個自然停頓。"
            }
            return ScriptParagraphFeedback(
                paragraph: paragraph,
                spokenExcerpt: excerpt,
                comparison: comparison,
                suggestion: suggestion
            )
        }
    }

    private static func proportionalExcerpt(
        for paragraph: ScriptParagraph,
        among paragraphs: [ScriptParagraph],
        spoken: String
    ) -> String {
        guard !spoken.isEmpty,
              let paragraphIndex = paragraphs.firstIndex(of: paragraph) else {
            return spoken
        }
        let weights = paragraphs.map { max(1, $0.text.count) }
        let totalWeight = max(1, weights.reduce(0, +))
        let lowerWeight = weights.prefix(paragraphIndex).reduce(0, +)
        let upperWeight = lowerWeight + weights[paragraphIndex]
        let characters = Array(spoken)
        let lower = min(
            characters.count,
            Int((Double(lowerWeight) / Double(totalWeight) * Double(characters.count)).rounded(.down))
        )
        let upper = min(
            characters.count,
            max(
                lower + 1,
                Int((Double(upperWeight) / Double(totalWeight) * Double(characters.count)).rounded(.up))
            )
        )
        return String(characters[lower..<upper])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func comparisonUnits(
        in text: String,
        language: PracticeLanguage
    ) -> [String] {
        if language == .english {
            return text.lowercased().split { character in
                !character.isLetter && !character.isNumber && character != "'"
            }.map(String.init)
        }

        var units: [String] = []
        var latinToken = ""
        func flushLatinToken() {
            if !latinToken.isEmpty {
                units.append(latinToken.lowercased())
                latinToken = ""
            }
        }
        for character in text {
            if character.isASCII && (character.isLetter || character.isNumber || character == "'") {
                latinToken.append(character)
            } else {
                flushLatinToken()
                if character.isLetter || character.isNumber {
                    units.append(String(character))
                }
            }
        }
        flushLatinToken()
        return units
    }

    private static func missingKeywords(
        reference: String,
        spoken: String,
        language: PracticeLanguage
    ) -> [String] {
        let spokenNormalized = comparisonUnits(in: spoken, language: language).joined(separator: " ")
        var result: [String] = []
        for chunk in contentChunks(in: reference, language: language) {
            let normalized = comparisonUnits(in: chunk, language: language).joined(separator: " ")
            guard !normalized.isEmpty, !spokenNormalized.contains(normalized) else { continue }
            if !result.contains(chunk) { result.append(chunk) }
            if result.count == 3 { break }
        }
        return result
    }

    private static func contentChunks(
        in text: String,
        language: PracticeLanguage
    ) -> [String] {
        if language == .english {
            return text.lowercased()
                .split { !$0.isLetter && !$0.isNumber && $0 != "'" }
                .map(String.init)
                .filter { $0.count >= 4 }
        }

        let runs = text.split { character in
            !character.isLetter && !character.isNumber
        }.map(String.init)
        return runs.flatMap { run -> [String] in
            guard run.count > 6 else { return run.count >= 2 ? [run] : [] }
            var chunks: [String] = []
            var start = run.startIndex
            while start < run.endIndex {
                let end = run.index(start, offsetBy: 4, limitedBy: run.endIndex) ?? run.endIndex
                let chunk = String(run[start..<end])
                if chunk.count >= 2 { chunks.append(chunk) }
                start = end
            }
            return chunks
        }
    }
}

private extension String {
    func components(separatedBy expression: NSRegularExpression) -> [String] {
        let range = NSRange(startIndex..<endIndex, in: self)
        var cursor = startIndex
        var result: [String] = []
        for match in expression.matches(in: self, range: range) {
            guard let matchRange = Range(match.range, in: self) else { continue }
            result.append(String(self[cursor..<matchRange.lowerBound]))
            cursor = matchRange.upperBound
        }
        result.append(String(self[cursor..<endIndex]))
        return result
    }
}
