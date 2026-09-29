public struct InterpretError: Error, CustomStringConvertible {
    public let line: Int
    public let message: String

    public init(_ message: String, at line: Int) {
        self.line = line
        self.message = message
    }

    public var description: String {
        "[line \(line)] \(message)"
    }
}

public class Interpreter {

    private let parser: Parser
    private let env: Env

    public init(source: String) {
        self.parser = Parser(source: source)
        self.env = Env()
    }

    public func eval() throws -> LoxValue {
        try evalExpr(parser.parseExpr())
    }

    public func run() throws {
        while let stmt = try parser.parse() {
            try execute(stmt)
        }
    }

    private func execute(_ stmt: Stmt) throws(InterpretError) {
        switch stmt {
        case .print(let expr, _):
            print(try evalExpr(expr))
        case .expr(let expr, _):
            try _ = evalExpr(expr)  // side-effect
        case .var(name: let token, let initializer, _):
            let value: LoxValue =
                if initializer != nil {
                    try evalExpr(initializer!)
                } else {
                    .nil
                }
            env.define(name: String(token.lexeme), value: value)
        }
    }

    private func evalExpr(_ expr: Expr) throws(InterpretError) -> LoxValue {
        switch expr {
        case .literal(let value): value
        case .grouping(let expr): try evalExpr(expr)
        case .unary(let op, let right): try evalUnaryExpr(op: op, expr: right)
        case .binary(let left, let op, let right): try evalBinaryExpr(left: left, op: op, right: right)
        case .var(let name): try lookupVar(name)
        }
    }

    private func lookupVar(_ name: Token) throws(InterpretError) -> LoxValue {
        do {
            return try env[String(name.lexeme)]
        } catch {
            throw InterpretError(error.description, at: name.line)
        }
    }

    private func evalUnaryExpr(op: Token, expr: Expr) throws(InterpretError) -> LoxValue {
        let value = try evalExpr(expr)

        return switch op.kind {
        case .minus:
            try .number(-expectNumber(value))
        case .bang:
            .bool(!isTruthy(value))
        default:
            throw InterpretError("invalid unary expression", at: op.line)
        }
    }

    private func evalBinaryExpr(
        left: Expr,
        op: Token,
        right: Expr
    ) throws(InterpretError) -> LoxValue {
        let leftValue = try evalExpr(left)
        let rightValue = try evalExpr(right)

        return switch op.kind {
        case .minus: try .number(expectNumber(leftValue) - expectNumber(rightValue))
        case .plus:
            if case .number(let l) = leftValue, case .number(let r) = rightValue {
                .number(l + r)
            } else if case .string(let l) = leftValue, case .string(let r) = rightValue {
                .string("\(l)\(r)")
            } else {
                throw InterpretError("Operands must be two numbers or two strings.", at: op.line)
            }
        case .slash: try .number(expectNumber(leftValue) / expectNumber(rightValue))
        case .star: try .number(expectNumber(leftValue) * expectNumber(rightValue))
        case .greater:
            try .bool(expectNumber(leftValue) > expectNumber(rightValue))
        case .greaterEqual:
            try .bool(expectNumber(leftValue) >= expectNumber(rightValue))
        case .less:
            try .bool(expectNumber(leftValue) < expectNumber(rightValue))
        case .lessEqual:
            try .bool(expectNumber(leftValue) <= expectNumber(rightValue))
        default:
            fatalError("\(op.kind) on numbers is not supported")
        }
    }

    private func expectNumber(_ value: LoxValue) throws(InterpretError) -> Double {
        guard case .number(let value) = value else {
            throw InterpretError("Operand '\(value)' must be a number.", at: -1)
        }

        return value
    }

    private func isTruthy(_ value: LoxValue) -> Bool {
        switch value {
        case .nil: false
        case .bool(let tf): tf
        default: true
        }
    }

}
