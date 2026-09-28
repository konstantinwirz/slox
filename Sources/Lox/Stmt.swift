public struct Location {
    public let line: Int
}

public enum Stmt {
    case expr(expr: Expr, loc: Location)
    case print(expr: Expr, loc: Location)
    case `var`(name: Token, initializer: Expr?, loc: Location)

    public var location: Location {
        switch self {
        case .expr(_, let loc): loc
        case .print(_, let loc): loc
        case .var(_, _, let loc): loc
        }
    }
}

public enum Expr: CustomStringConvertible {
    case literal(LoxValue)
    indirect case grouping(Expr)
    indirect case unary(op: Token, right: Expr)
    case `var`(name: Token)
    indirect case binary(left: Expr, op: Token, right: Expr)

    public var description: String {
        switch self {
        case .literal(let literal):
            return literal.description
        case .grouping(let expr):
            return "(group \(expr))"
        case .unary(let op, let right):
            return "(\(op.lexeme) \(right))"
        case .binary(let left, let op, let right):
            return "(\(op.lexeme) \(left) \(right))"
        case .var(let name):
            return "var \(name)"
        }
    }
}
