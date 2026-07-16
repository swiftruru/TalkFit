import Foundation

struct FillerLibraryStore {
    private let defaults: UserDefaults
    private let storageKey = "talkfit.filler-library.overrides.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [PracticeLanguage: [String]] {
        var libraries = defaultLibraries
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(FillerLibrarySnapshot.self, from: data),
              snapshot.version == 1 else {
            return libraries
        }

        for language in PracticeLanguage.allCases {
            let override = snapshot.languages[language.rawValue] ?? FillerLibraryOverride()
            let removed = Set(override.removed.map(language.normalizeFiller))
            var words = language.defaultFillerWords.filter {
                !removed.contains(language.normalizeFiller($0))
            }
            for addedWord in override.added.map(language.normalizeFiller) {
                guard !addedWord.isEmpty,
                      !words.contains(where: { language.normalizeFiller($0) == addedWord }) else {
                    continue
                }
                words.append(addedWord)
            }
            libraries[language] = Array(words.prefix(40))
        }
        return libraries
    }

    func save(_ libraries: [PracticeLanguage: [String]]) {
        var languageOverrides: [String: FillerLibraryOverride] = [:]
        for language in PracticeLanguage.allCases {
            let current = libraries[language] ?? language.defaultFillerWords
            let currentNormalized = current.map(language.normalizeFiller)
            let defaultNormalized = language.defaultFillerWords.map(language.normalizeFiller)
            languageOverrides[language.rawValue] = FillerLibraryOverride(
                added: currentNormalized.filter { !defaultNormalized.contains($0) },
                removed: defaultNormalized.filter { !currentNormalized.contains($0) }
            )
        }

        let snapshot = FillerLibrarySnapshot(version: 1, languages: languageOverrides)
        guard snapshot.hasOverrides,
              let data = try? JSONEncoder().encode(snapshot) else {
            defaults.removeObject(forKey: storageKey)
            return
        }
        defaults.set(data, forKey: storageKey)
    }

    func resetAll() {
        defaults.removeObject(forKey: storageKey)
    }

    private var defaultLibraries: [PracticeLanguage: [String]] {
        Dictionary(uniqueKeysWithValues: PracticeLanguage.allCases.map { language in
            (language, language.defaultFillerWords)
        })
    }
}

private struct FillerLibrarySnapshot: Codable {
    let version: Int
    let languages: [String: FillerLibraryOverride]

    var hasOverrides: Bool {
        languages.values.contains { !$0.added.isEmpty || !$0.removed.isEmpty }
    }
}

private struct FillerLibraryOverride: Codable {
    var added: [String] = []
    var removed: [String] = []
}
