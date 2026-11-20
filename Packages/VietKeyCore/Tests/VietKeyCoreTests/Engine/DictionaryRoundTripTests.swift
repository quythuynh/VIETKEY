import Testing
@testable import VietEngine

@Suite("Dictionary round trip")
struct DictionaryRoundTripTests {
    struct Syllable: CustomTestStringConvertible {
        let letters: [Letter]
        let tone: ToneMark
        var testDescription: String { Renderer.render(letters, tone: tone, style: .new) }
    }

    static let syllables: [Syllable] = {
        var result: [Syllable] = []
        for initial in Initials.valid.sorted() {
            for rhyme in Rhymes.valid.sorted() {
                if initial == "qu" && rhyme.hasPrefix("u") { continue }
                if initial == "gi" && (rhyme.hasPrefix("i") || rhyme.hasPrefix("y")) { continue }
                for tone in ToneMark.allCases {
                    let (letters, _) = LetterDecoder.decode(initial + rhyme)
                    guard SpellChecker.isValid(letters, tone: tone) else { continue }
                    result.append(Syllable(letters: letters, tone: tone))
                }
            }
        }
        return result
    }()

    @Test func generatesThousandsOfSyllables() {
        #expect(Self.syllables.count > 15_000)
    }

    @Test(arguments: InputMethodKind.allCases)
    func everySyllableTypes(kind: InputMethodKind) {
        let method = kind.method
        var failures: [String] = []
        for syllable in Self.syllables {
            let expected = Renderer.render(syllable.letters, tone: syllable.tone, style: .new)
            // Telex can't type "oo" directly; boong is typed "booong".
            if (kind == .telex || kind == .telexExtended) && Renderer.spelling(syllable.letters[...]).contains("oo") {
                continue
            }

            var keys = syllable.letters.flatMap { method.keys(for: $0) }
            if let toneKey = method.key(for: syllable.tone) { keys.append(toneKey) }
            let typed = TypingSimulator.type(String(keys), options: EngineOptions(inputMethod: kind))
            if typed != expected {
                failures.append("\(String(keys)) → \(typed), expected \(expected)")
            }
        }
        #expect(failures.isEmpty, "\(failures.count) failures, e.g. \(failures.prefix(20))")
    }
}
