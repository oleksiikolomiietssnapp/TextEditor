import Foundation

public enum UnicodeStyler {

    // MARK: - Character Maps

    // Mathematical Sans-Serif Bold (U+1D5D4 - U+1D607)
    private static let boldUppercase = "𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭"
    private static let boldLowercase = "𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇"
    private static let boldDigits = "𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵"

    // Mathematical Sans-Serif Italic (U+1D608 - U+1D63B)
    private static let italicUppercase = "𝘈𝘉𝘊𝘋𝘌𝘍𝘎𝘏𝘐𝘑𝘒𝘓𝘔𝘕𝘖𝘗𝘘𝘙𝘚𝘛𝘜𝘝𝘞𝘟𝘠𝘡"
    private static let italicLowercase = "𝘢𝘣𝘤𝘥𝘦𝘧𝘨𝘩𝘪𝘫𝘬𝘭𝘮𝘯𝘰𝘱𝘲𝘳𝘴𝘵𝘶𝘷𝘸𝘹𝘺𝘻"

    // Mathematical Sans-Serif Bold Italic (U+1D63C - U+1D66F)
    private static let boldItalicUppercase = "𝘼𝘽𝘾𝘿𝙀𝙁𝙂𝙃𝙄𝙅𝙆𝙇𝙈𝙉𝙊𝙋𝙌𝙍𝙎𝙏𝙐𝙑𝙒𝙓𝙔𝙕"
    private static let boldItalicLowercase = "𝙖𝙗𝙘𝙙𝙚𝙛𝙜𝙝𝙞𝙟𝙠𝙡𝙢𝙣𝙤𝙥𝙦𝙧𝙨𝙩𝙪𝙫𝙬𝙭𝙮𝙯"

    // Normal characters for reference
    private static let normalUppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private static let normalLowercase = "abcdefghijklmnopqrstuvwxyz"
    private static let normalDigits = "0123456789"

    // MARK: - Style Detection

    public struct Style: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let bold = Style(rawValue: 1 << 0)
        public static let italic = Style(rawValue: 1 << 1)
        public static let normal = Style([])
        public static let boldItalic: Style = [.bold, .italic]
    }

    public static func detectStyle(of char: Character) -> Style {
        let scalar = char.unicodeScalars.first?.value ?? 0

        // Bold Italic range
        if (0x1D63C...0x1D66F).contains(scalar) { return .boldItalic }

        // Bold range
        if (0x1D5D4...0x1D607).contains(scalar) { return .bold }

        // Italic range
        if (0x1D608...0x1D63B).contains(scalar) { return .italic }

        // Bold digits
        if (0x1D7EC...0x1D7F5).contains(scalar) { return .bold }

        return .normal
    }

    // MARK: - Conversion

    public static func toNormal(_ char: Character) -> Character {
        let style = detectStyle(of: char)
        guard style != .normal else { return char }

        let scalar = char.unicodeScalars.first!.value

        // Bold Italic uppercase
        if (0x1D63C...0x1D655).contains(scalar) {
            let index = Int(scalar - 0x1D63C)
            return normalUppercase[normalUppercase.index(normalUppercase.startIndex, offsetBy: index)]
        }
        // Bold Italic lowercase
        if (0x1D656...0x1D66F).contains(scalar) {
            let index = Int(scalar - 0x1D656)
            return normalLowercase[normalLowercase.index(normalLowercase.startIndex, offsetBy: index)]
        }

        // Bold uppercase
        if (0x1D5D4...0x1D5ED).contains(scalar) {
            let index = Int(scalar - 0x1D5D4)
            return normalUppercase[normalUppercase.index(normalUppercase.startIndex, offsetBy: index)]
        }
        // Bold lowercase
        if (0x1D5EE...0x1D607).contains(scalar) {
            let index = Int(scalar - 0x1D5EE)
            return normalLowercase[normalLowercase.index(normalLowercase.startIndex, offsetBy: index)]
        }
        // Bold digits
        if (0x1D7EC...0x1D7F5).contains(scalar) {
            let index = Int(scalar - 0x1D7EC)
            return normalDigits[normalDigits.index(normalDigits.startIndex, offsetBy: index)]
        }

        // Italic uppercase
        if (0x1D608...0x1D621).contains(scalar) {
            let index = Int(scalar - 0x1D608)
            return normalUppercase[normalUppercase.index(normalUppercase.startIndex, offsetBy: index)]
        }
        // Italic lowercase
        if (0x1D622...0x1D63B).contains(scalar) {
            let index = Int(scalar - 0x1D622)
            return normalLowercase[normalLowercase.index(normalLowercase.startIndex, offsetBy: index)]
        }

        return char
    }

    public static func apply(style: Style, to char: Character) -> Character {
        // First normalize the character
        let normalChar = toNormal(char)

        // Check if it's a letter or digit we can style
        guard let scalar = normalChar.unicodeScalars.first else { return char }
        let value = scalar.value

        // Uppercase A-Z
        if (0x41...0x5A).contains(value) {
            let index = Int(value - 0x41)
            let source: String
            switch style {
            case .boldItalic: source = boldItalicUppercase
            case .bold: source = boldUppercase
            case .italic: source = italicUppercase
            default: return normalChar
            }
            return source[source.index(source.startIndex, offsetBy: index)]
        }

        // Lowercase a-z
        if (0x61...0x7A).contains(value) {
            let index = Int(value - 0x61)
            let source: String
            switch style {
            case .boldItalic: source = boldItalicLowercase
            case .bold: source = boldLowercase
            case .italic: source = italicLowercase
            default: return normalChar
            }
            return source[source.index(source.startIndex, offsetBy: index)]
        }

        // Digits 0-9 (only bold available)
        if (0x30...0x39).contains(value) && style.contains(.bold) {
            let index = Int(value - 0x30)
            return boldDigits[boldDigits.index(boldDigits.startIndex, offsetBy: index)]
        }

        return normalChar
    }

    // MARK: - String Operations

    public static func toggleBold(_ text: String) -> String {
        // Check if all styleable chars are already bold
        let allBold = text.allSatisfy { char in
            let style = detectStyle(of: char)
            return style.contains(.bold) || !isStyleable(char)
        }

        return String(text.map { char in
            guard isStyleable(char) else { return char }
            let currentStyle = detectStyle(of: char)

            if allBold {
                // Remove bold, keep italic if present
                let newStyle = currentStyle.subtracting(.bold)
                return apply(style: newStyle, to: char)
            } else {
                // Add bold, keep italic if present
                let newStyle = currentStyle.union(.bold)
                return apply(style: newStyle, to: char)
            }
        })
    }

    public static func toggleItalic(_ text: String) -> String {
        // Check if all styleable chars are already italic
        let allItalic = text.allSatisfy { char in
            let style = detectStyle(of: char)
            return style.contains(.italic) || !isStyleable(char)
        }

        return String(text.map { char in
            guard isStyleable(char) else { return char }
            let currentStyle = detectStyle(of: char)

            if allItalic {
                // Remove italic, keep bold if present
                let newStyle = currentStyle.subtracting(.italic)
                return apply(style: newStyle, to: char)
            } else {
                // Add italic, keep bold if present
                let newStyle = currentStyle.union(.italic)
                return apply(style: newStyle, to: char)
            }
        })
    }

    private static func isStyleable(_ char: Character) -> Bool {
        let normalChar = toNormal(char)
        guard let scalar = normalChar.unicodeScalars.first else { return false }
        let value = scalar.value

        // A-Z, a-z, 0-9
        return (0x41...0x5A).contains(value) ||
               (0x61...0x7A).contains(value) ||
               (0x30...0x39).contains(value)
    }
}
