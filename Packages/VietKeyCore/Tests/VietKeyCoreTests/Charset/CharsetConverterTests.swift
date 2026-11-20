import Testing
@testable import VietCharset

@Suite("Charset converter")
struct CharsetConverterTests {
    private static let sample = "Tiếng Việt: Hà Nội, Đà Nẵng, người, thuở, khuỷu tay, quyển sách."
    private static let allLetters = "aáàảãạăắằẳẵặâấầẩẫậđeéèẻẽẹêếềểễệiíìỉĩịoóòỏõọôốồổỗộơớờởỡợuúùủũụưứừửữựyýỳỷỹỵ"

    @Test func tcvn3KnownValues() {
        #expect(CharsetConverter.encode("Việt Nam", to: .tcvn3) == "Vi\u{D6}t Nam")
        #expect(CharsetConverter.encode("Hà Nội", to: .tcvn3) == "H\u{B5} N\u{E9}i")
        #expect(CharsetConverter.decode("Vi\u{D6}t Nam", from: .tcvn3) == "Việt Nam")
    }

    @Test func vniWindowsKnownValues() {
        #expect(CharsetConverter.encode("Việt Nam", to: .vniWindows) == "Vieät Nam")
        #expect(CharsetConverter.encode("Hà Nội", to: .vniWindows) == "Haø Noäi")
        #expect(CharsetConverter.decode("Vieät Nam", from: .vniWindows) == "Việt Nam")
    }

    @Test func viqrKnownValues() {
        #expect(CharsetConverter.encode("Việt Nam", to: .viqr) == "Vie^.t Nam")
        #expect(CharsetConverter.encode("người", to: .viqr) == "ngu+o+`i")
        #expect(CharsetConverter.decode("ddu+o+`ng", from: .viqr) == "đường")
    }

    @Test(arguments: Charset.allCases)
    func roundTripsLowercase(charset: Charset) {
        let encoded = CharsetConverter.encode(Self.allLetters, to: charset)
        #expect(CharsetConverter.decode(encoded, from: charset) == Self.allLetters)
    }

    @Test(arguments: [Charset.unicode, .unicodeComposite, .vniWindows, .viqr])
    func roundTripsMixedCase(charset: Charset) {
        let text = Self.sample + " " + Self.allLetters.uppercased()
        let encoded = CharsetConverter.encode(text, to: charset)
        #expect(CharsetConverter.decode(encoded, from: charset) == text)
    }

    @Test func compositeIsNFD() {
        let composite = CharsetConverter.encode("ệ", to: .unicodeComposite)
        #expect(composite.unicodeScalars.count == 3)
        #expect(CharsetConverter.convert(composite, from: .unicodeComposite, to: .unicode).unicodeScalars.count == 1)
    }

    @Test func stripTones() {
        #expect(ToneStripper.strip("Tiếng Việt đẹp, ĐƯỜNG") == "Tieng Viet dep, DUONG")
        #expect(CharsetConverter.convert("Vieät", from: .vniWindows, to: .unicode, stripTones: true) == "Viet")
    }
}
