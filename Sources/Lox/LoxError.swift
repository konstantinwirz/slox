public enum LoxErrorKind: Int, Sendable {
    case scanError
    case parseError
    case runtimeError
}


public struct LoxError : Error, CustomStringConvertible {
    public let kind: LoxErrorKind 
    public let line: Int
    public let message: String
    let hint: String?

    private init(kind: LoxErrorKind, message: String, line: Int, hint: String? = nil) {
        self.kind = kind
        self.message = message
        self.line = line
        self.hint = hint
    }

    public static func scanError(message: String, line: Int, hint: String? = nil) -> LoxError {
        return LoxError(kind: .scanError, message: message, line: line, hint: hint)
    }

    public static func parseError(message: String, line: Int, hint: String? = nil) -> LoxError {
        return LoxError(kind: .parseError, message: message, line: line, hint: hint)
    }

    public static func runtimeError(message: String, line: Int, hint: String? = nil) -> LoxError {
        return LoxError(kind: .runtimeError, message: message, line: line, hint: hint)
    }

    public var description: String {
        switch kind {
        case .runtimeError:
            "\(message)\n[line \(line)]"
        default:
            "[line \(line)] Error\(hint ?? ""): \(message)"
        }
    }

}
