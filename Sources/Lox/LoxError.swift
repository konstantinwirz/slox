public enum LoxError: Error, CustomStringConvertible {
    case scanError(message: String, line: Int)
    case parseError(message: String, line: Int)
    case runtimeError(message: String, line: Int)

    var line: Int {
        switch self {
        case .scanError(_, let line): return line
        case .parseError(_, let line): return line
        case .runtimeError(_, let line): return line
        }
    }

    var message: String {
        switch self {
        case .scanError(let message, _): return message
        case .parseError(let message, _): return message
        case .runtimeError(let message, _): return message
        }
    }

    public var description: String {
        switch self {
        case .runtimeError(let message, let line): "\(message)\n[line \(line)]"
        default: "[line \(line)] \(message)"
        }
    }

}
