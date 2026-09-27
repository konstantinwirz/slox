public enum LoxValue {
    case `nil`
    case string(Substring)
    case number(Double)
    case bool(Bool)
}

extension LoxValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nil: "null"
        case .string(let s): String(s)
        case .number(let n): String(n)
        case .bool(let b): "\(b)"
        }
    }
}
