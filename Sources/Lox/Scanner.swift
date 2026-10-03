public class Scanner {

    public let source: String
    public var startIndex: String.Index
    public var currentIndex: String.Index
    public var line: Int
    private var sourceExhausted: Bool = false

    public init(source: String) {
        self.source = source
        self.startIndex = source.startIndex
        self.currentIndex = source.startIndex
        self.line = 1
    }

    public func scanNextToken() throws(LoxError) -> Token? {
        guard !sourceExhausted else {
            return nil
        }
        
        try skipWhitespaces()

        if isAtEnd() {
            sourceExhausted = true
            return Token(kind: .eof, lexeme: "", literal: .nil, line: line)
        }

        startIndex = currentIndex
        let ch = try advance()

        switch ch {
        case "(": return newToken(kind: .leftParen)
        case ")": return newToken(kind: .rightParen)
        case ";": return newToken(kind: .semicolon)
        case "{": return newToken(kind: .leftBrace)
        case "}": return newToken(kind: .rightBrace)
        case "+": return newToken(kind: .plus)
        case "-": return newToken(kind: .minus)
        case "*": return newToken(kind: .star)
        case ".": return newToken(kind: .dot)
        case ",": return newToken(kind: .comma)
        case "'": return newToken(kind: .comma)
        case "/":
            if let next = peek(), next == "/" {
                while let next = peek(), !next.isNewline {
                    _ = try advance()
                }
                return try scanNextToken()
            } else {
                return newToken(kind: .slash)
            }
        case "=":
            return newToken(kind: try matches("=") ? .equalEqual : .equal)
        case "!":
            return newToken(kind: try matches("=") ? .bangEqual : .bang)
        case "<":
            return newToken(kind: try matches("=") ? .lessEqual : .less)
        case ">":
            return newToken(kind: try matches("=") ? .greaterEqual : .greater)
        case "\"":
            return try scanString()
        case "0"..."9":
            return try scanNumber()
        case "a"..."z", "A"..."Z", "_":
            return try scanIdentifier()
        default:
            throw .scanError(message: "Unexpected character: \(ch)", line: line)
        }
    }

    private func scanIdentifier() throws(LoxError) -> Token {
        while let ch = peek(), ch.isNumber || ch.isLetter || ch == "_" {
            _ = try advance()
        }

        let kind: TokenKind =
            switch source[startIndex..<currentIndex] {
            case "and": .and
            case "class": .class
            case "else": .else
            case "false": .false
            case "for": .for
            case "fun": .fun
            case "if": .if
            case "nil": .nil
            case "or": .or
            case "print": .print
            case "return": .return
            case "super": .super
            case "this": .this
            case "true": .true
            case "var": .var
            case "while": .while
            default: .identifier
            }

        return newToken(kind: kind)
    }

    private func scanNumber() throws(LoxError) -> Token {
        while let ch = peek(), ch.isNumber {
            _ = try advance()
        }

        // it could be a floating point number
        if peek() == "." && peekNext()?.isNumber ?? false {
            _ = try advance()  // .
            _ = try advance()  // first digit after .
            // consume remaining digits
            while let ch = peek(), ch.isNumber {
                _ = try advance()
            }
        }

        let lexeme = source[startIndex..<currentIndex]
        // try to convert to Double
        if let n = Double(lexeme) {
            return Token(kind: .number, lexeme: lexeme, literal: .number(n), line: line)
        }

        throw .scanError(message: "Invalid number: \(lexeme)", line: line)
    }

    private func scanString() throws(LoxError) -> Token {
        while let ch = peek(), ch != "\"" {
            if ch.isNewline {
                line += 1
            }
            _ = try advance()
        }

        // we expect closing double quote
        if peek() != "\"" {
            throw .scanError(message: "Unterminated string.", line: line)
        }

        _ = try advance()  // consume closing double quote
        return Token(
            kind: .string,
            lexeme: source[startIndex..<currentIndex],
            literal: .string(
                source[source.index(after: startIndex)..<source.index(before: currentIndex)]),
            line: line
        )
    }

    private func matches(_ expected: Character) throws(LoxError) -> Bool {
        if isAtEnd() {
            return false
        }

        if peek() == expected {
            _ = try advance()
            return true
        }

        return false
    }

    private func skipWhitespaces() throws(LoxError) {
        while let ch = peek(), ch.isWhitespace {
            _ = try advance()
            if ch.isNewline {
                line += 1
            }
        }
    }

    private func newToken(kind: TokenKind) -> Token {
        return Token(
            kind: kind, lexeme: source[startIndex..<currentIndex], literal: .nil, line: line)
    }

    private func isAtEnd() -> Bool {
        return currentIndex >= source.endIndex
    }

    private func advance() throws(LoxError) -> Character {
        guard !isAtEnd() else {
            throw .scanError(message: "Unexpected end of input", line: line)
        }

        let ch = source[currentIndex]
        currentIndex = source.index(after: currentIndex)
        return ch
    }

    private func peek() -> Character? {
        guard !isAtEnd() else {
            return nil
        }

        return source[currentIndex]
    }

    private func peekNext() -> Character? {
        guard !isAtEnd() else {
            return nil
        }

        let idx = source.index(after: currentIndex)
        if idx >= source.endIndex {
            return nil
        }

        return source[idx]
    }
}
