import Foundation

public enum CharsetConverter {
    public static func convert(_ text: String, from source: Charset, to target: Charset, stripTones: Bool = false) -> String {
        var unicode = decode(text, from: source)
        if stripTones {
            unicode = ToneStripper.strip(unicode)
        }
        return encode(unicode, to: target)
    }

    public static func decode(_ text: String, from charset: Charset) -> String {
        switch charset {
        case .unicode, .unicodeComposite:
            return text.precomposedStringWithCanonicalMapping
        case .tcvn3:
            return String(text.map { TCVN3Table.decode[$0] ?? $0 })
        case .vniWindows:
            return decodeVNIWindows(text)
        case .viqr:
            return VIQRCodec.decode(text)
        }
    }

    public static func encode(_ text: String, to charset: Charset) -> String {
        let nfc = text.precomposedStringWithCanonicalMapping
        switch charset {
        case .unicode:
            return nfc
        case .unicodeComposite:
            return nfc.decomposedStringWithCanonicalMapping
        case .tcvn3:
            return String(nfc.map { TCVN3Table.encode[$0] ?? $0 })
        case .vniWindows:
            return nfc.map { VNIWindowsTable.encode[$0] ?? String($0) }.joined()
        case .viqr:
            return VIQRCodec.encode(nfc)
        }
    }

    private static func decodeVNIWindows(_ text: String) -> String {
        let characters = Array(text)
        var output = ""
        var index = 0
        while index < characters.count {
            if index + 1 < characters.count,
               let unicode = VNIWindowsTable.decode[String(characters[index...index + 1])] {
                output.append(unicode)
                index += 2
            } else {
                output.append(VNIWindowsTable.decode[String(characters[index])] ?? characters[index])
                index += 1
            }
        }
        return output
    }
}
