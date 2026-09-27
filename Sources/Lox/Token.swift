public enum TokenKind: String, CustomStringConvertible {
    // single character tokens
    case leftParen
    case rightParen
    case leftBrace
    case rightBrace
    case comma
    case dot
    case minus
    case plus
    case semicolon
    case slash
    case star

    // one or two character tokens
    case bang
    case bangEqual
    case equal
    case equalEqual
    case greater
    case greaterEqual
    case less
    case lessEqual

    // literals
    case identifier
    case string
    case number

    // keywords
    case and
    case `class`
    case `else`
    case `false`
    case fun
    case `for`
    case `if`
    case `nil`
    case `or`
    case print
    case `return`
    case `super`
    case this
    case `true`
    case `var`
    case `while`

    // end of file
    case eof

    public var description: String {
        switch self {
        case .leftParen: "LEFT_PAREN"
        case .rightParen: "RIGHT_PAREN"
        case .leftBrace: "LEFT_BRACE"
        case .rightBrace: "RIGHT_BRACE"
        case .bangEqual: "BANG_EQUAL"
        case .equalEqual: "EQUAL_EQUAL"
        case .greaterEqual: "GREATER_EQUAL"
        case .lessEqual: "LESS_EQUAL"
        default: self.rawValue.uppercased()
        }
    }
}

public struct Token: CustomStringConvertible {
    public let kind: TokenKind
    public let lexeme: Substring
    public let literal: LoxValue
    public let line: Int

    public init(kind: TokenKind, lexeme: Substring, literal: LoxValue, line: Int) {
        self.kind = kind
        self.lexeme = lexeme
        self.literal = literal
        self.line = line
    }

    public var description: String {
        return "\(kind) \(lexeme) \(literal)"
    }
}
