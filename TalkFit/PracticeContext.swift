import Foundation

enum PracticeContext: String, CaseIterable, Identifiable, Equatable {
    case selfIntroduction = "self-introduction-30"
    case presentation = "presentation"
    case classReport = "class-report"
    case interview = "interview"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .selfIntroduction: "自我介紹"
        case .presentation: "簡報提案"
        case .classReport: "課堂報告"
        case .interview: "面試回答"
        }
    }

    var shortName: String {
        switch self {
        case .selfIntroduction: "自我介紹"
        case .presentation: "簡報"
        case .classReport: "課堂"
        case .interview: "面試"
        }
    }

    var systemImage: String {
        switch self {
        case .selfIntroduction: "person.crop.circle"
        case .presentation: "rectangle.on.rectangle.angled"
        case .classReport: "book.closed"
        case .interview: "person.2"
        }
    }

    func promptTitle(for language: PracticeLanguage) -> String {
        switch (self, language) {
        case (.selfIntroduction, .traditionalChinese): "30 秒自我介紹"
        case (.selfIntroduction, .english): "30 秒英文自我介紹"
        case (.presentation, .traditionalChinese): "一句話說清楚提案"
        case (.presentation, .english): "用英文說清楚你的提案"
        case (.classReport, .traditionalChinese): "課堂報告開場"
        case (.classReport, .english): "英文課堂報告開場"
        case (.interview, .traditionalChinese): "回答：為什麼是你？"
        case (.interview, .english): "用英文回答：為什麼是你？"
        }
    }

    func prompt(for language: PracticeLanguage) -> String {
        switch (self, language) {
        case (.selfIntroduction, .traditionalChinese):
            "介紹你是誰、最近在做什麼，以及一件你想讓別人記住的事。"
        case (.selfIntroduction, .english):
            "Tell us who you are, what you are doing these days, and one thing you want people to remember."
        case (.presentation, .traditionalChinese):
            "說明你想解決的問題、你的做法，以及為什麼值得現在開始。"
        case (.presentation, .english):
            "Tell us the problem, your idea, and why we should start now."
        case (.classReport, .traditionalChinese):
            "先說明今天的主題，再用一個例子告訴同學它為什麼重要。"
        case (.classReport, .english):
            "Tell us your topic, then give one example to show why it is important."
        case (.interview, .traditionalChinese):
            "分享一項與職位最相關的經驗，說明你做了什麼，以及帶來的結果。"
        case (.interview, .english):
            "Share one thing you did, how you did it, and what happened in the end."
        }
    }

    func defaultRecordingScript(for language: PracticeLanguage) -> String {
        recordingScript(for: language, style: .clean)
    }

    /// The script shown on the recording screen for people to read aloud.
    /// The filler version is the same talk with hesitation words written in,
    /// so a visitor can see TalkFit catch them.
    func recordingScript(
        for language: PracticeLanguage,
        style: ReferenceScriptStyle
    ) -> String {
        switch style {
        case .clean: sampleTranscript(for: .retry, language: language)
        case .withFillers: sampleTranscript(for: .first, language: language)
        }
    }

    func recognitionHint(for language: PracticeLanguage) -> String {
        switch (self, language) {
        case (.selfIntroduction, .traditionalChinese): "三十秒自我介紹"
        case (.selfIntroduction, .english): "thirty second self introduction"
        case (.presentation, .traditionalChinese): "簡報提案"
        case (.presentation, .english): "project proposal"
        case (.classReport, .traditionalChinese): "課堂報告"
        case (.classReport, .english): "class presentation"
        case (.interview, .traditionalChinese): "面試回答"
        case (.interview, .english): "interview answer"
        }
    }

    func comfortablePace(for language: PracticeLanguage) -> ClosedRange<Int> {
        switch (self, language) {
        // Upper bounds leave room for reading a script aloud, which runs
        // noticeably faster than speaking off the cuff.
        case (.selfIntroduction, .traditionalChinese): 170...260
        case (.presentation, .traditionalChinese): 155...245
        case (.classReport, .traditionalChinese): 165...255
        case (.interview, .traditionalChinese): 150...240
        case (.selfIntroduction, .english): 110...180
        case (.presentation, .english): 100...165
        case (.classReport, .english): 105...170
        case (.interview, .english): 95...160
        }
    }

    func paceState(for pace: Int, language: PracticeLanguage) -> PaceState {
        let range = comfortablePace(for: language)
        if pace < range.lowerBound { return .slow }
        if pace > range.upperBound { return .fast }
        return .steady
    }

    /// Pace verdict for the number shown while recording.
    ///
    /// The live number is an estimate from a few seconds of speech, so it
    /// only says "fast" once it is clearly past the comfortable range. A
    /// natural burst of quick words should not trip the warning.
    func livePaceState(for pace: Int, language: PracticeLanguage) -> PaceState {
        let range = comfortablePace(for: language)
        if pace < range.lowerBound { return .slow }
        if Double(pace) > Double(range.upperBound) * 1.12 { return .fast }
        return .steady
    }

    func paceSuggestion(for state: PaceState) -> String {
        switch (self, state) {
        case (.selfIntroduction, .slow):
            "把相近資訊連起來，讓自我介紹更自然。"
        case (.selfIntroduction, .steady):
            "節奏舒服，保留現在的自然停頓。"
        case (.selfIntroduction, .fast):
            "在名字與重點經驗後多留半拍。"
        case (.presentation, .slow):
            "把同一個論點接在一起，避免重點被拉散。"
        case (.presentation, .steady):
            "簡報節奏清楚，保留重點前後的空間。"
        case (.presentation, .fast):
            "關鍵結論前多留半拍，讓觀眾跟上。"
        case (.classReport, .slow):
            "例子與結論可以連著說，讓同學容易理解。"
        case (.classReport, .steady):
            "說明節奏自然，保留段落之間的停頓。"
        case (.classReport, .fast):
            "專有名詞後稍停一下，再接下一個觀念。"
        case (.interview, .slow):
            "先直接說行動與結果，再補充背景。"
        case (.interview, .steady):
            "回答從容清楚，保留現在的節奏。"
        case (.interview, .fast):
            "成果數字後多留半拍，讓亮點被聽見。"
        }
    }

    func sampleTranscript(for round: PracticeRound, language: PracticeLanguage) -> String {
        switch (self, round, language) {
        case (.selfIntroduction, .first, .traditionalChinese):
            "大家好，我是小安，目前在台北學習產品設計。嗯，我最近和同學一起做校園服務的專題，然後也開始練習把想法說得更清楚。其實我很喜歡觀察生活裡的小細節，就是希望未來能做出讓人感到貼心、又真正解決問題的產品。"
        case (.selfIntroduction, .retry, .traditionalChinese):
            "大家好，我是小安，目前在台北學習產品設計。我最近和同學一起做校園服務的專題，也練習把想法說得更清楚。我喜歡觀察生活裡的小細節，希望未來能做出貼心、又真正解決問題的產品。"
        case (.selfIntroduction, .first, .english):
            "Hi, I'm Mia. I am a student in Taipei, and I study design. Um, I am working on a school project with my classmates, and, like, I also practice speaking in front of people. Actually, I love to make things that are easy to use, you know, and help people every day."
        case (.selfIntroduction, .retry, .english):
            "Hi, I'm Mia. I am a student in Taipei, and I study design. I am working on a school project with my classmates, and I practice speaking in front of people. I love to make things that are easy to use and help people every day."
        case (.presentation, .first, .traditionalChinese):
            "今天我想提案一個校園共乘服務。嗯，現在很多同學下課後等車很久，然後也不知道誰剛好要去同一個地方。其實我們想用即時媒合，讓大家更快找到安全的同行夥伴，就是先從晚間校車站開始測試。"
        case (.presentation, .retry, .traditionalChinese):
            "今天我想提案一個校園共乘服務。許多同學下課後等車很久，我們用即時媒合，幫助大家找到安全的同行夥伴，並先從晚間校車站開始測試。"
        case (.presentation, .first, .english):
            "Today I want to share an idea for a school ride app. Um, many students wait a long time for the bus after class, and, like, they do not know who is going the same way. Actually, our app helps them find a safe friend to ride with, you know, and we will start at the night bus stop."
        case (.presentation, .retry, .english):
            "Today I want to share an idea for a school ride app. Many students wait a long time for the bus after class. Our app helps them find a safe friend to ride with, and we will start at the night bus stop."
        case (.classReport, .first, .traditionalChinese):
            "今天的報告主題是城市熱島。嗯，水泥和柏油在白天吸收熱量，然後晚上又慢慢釋放，所以市中心常常比郊區更熱。其實這種情況會增加用電，就是也會影響長者的健康。"
        case (.classReport, .retry, .traditionalChinese):
            "今天的報告主題是城市熱島。水泥和柏油白天吸收熱量，晚上再慢慢釋放，因此市中心通常比郊區更熱，也會增加用電並影響長者健康。"
        case (.classReport, .first, .english):
            "Today I want to talk about why cities are hot. Um, roads and buildings take in heat during the day, and, like, they give it back slowly at night. Actually, this makes the city hotter than the countryside, you know, and people use more power to stay cool."
        case (.classReport, .retry, .english):
            "Today I want to talk about why cities are hot. Roads and buildings take in heat during the day and give it back at night. This makes the city hotter than the countryside, and people use more power to stay cool."
        case (.interview, .first, .traditionalChinese):
            "我最相關的經驗是帶領三人團隊改善選課流程。嗯，我先訪談學生，然後整理最常卡住的步驟。其實我們重新設計資訊順序後，測試完成時間少了兩分鐘，就是讓使用者更快找到需要的課程。"
        case (.interview, .retry, .traditionalChinese):
            "我曾帶領三人團隊改善選課流程。我訪談學生並找出最常卡住的步驟，重新設計資訊順序後，測試完成時間縮短兩分鐘，讓使用者更快找到需要的課程。"
        case (.interview, .first, .english):
            "I want to tell you about a team project at school. Um, I led a team of three people, and, like, we asked students what was hard about choosing classes. Actually, we made the page easier to read, you know, and students finished two minutes faster."
        case (.interview, .retry, .english):
            "I led a team of three people at school. We asked students what was hard about choosing classes. Then we made the page easier to read, and students finished two minutes faster."
        }
    }
}
