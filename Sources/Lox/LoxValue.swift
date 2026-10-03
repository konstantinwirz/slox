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


extension LoxValue: Equatable {
    public static func == (lhs: LoxValue, rhs: LoxValue) -> Bool {
        switch (lhs, rhs) {
        case (.nil, .nil): return true
        case (.string(let a), .string(let b)): return a == b
        case (.number(let a), .number(let b)): return a == b
        case (.bool(let a), .bool(let b)): return a == b
        default: return false
        }
    }
}