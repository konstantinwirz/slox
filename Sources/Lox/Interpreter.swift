import Foundation

public class Interpreter {

    private let parser: Parser
    private var env: Env

    public init(source: String) {
        self.parser = Parser(source: source)
        self.env = Env()
    }

    public func eval() throws -> LoxValue {
        try evalExpr(parser.parseExpr())
    }

    public func run() throws(LoxError) {
        while let stmt = try parser.parse() {
            try execute(stmt)
        }
    }

    private func execute(_ stmt: Stmt) throws(LoxError) {
        switch stmt {
        case .print(let expr, _):
            printLoxValue(try evalExpr(expr))
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
        case .block(let stmts, _):
            try execBlock(stmts: stmts, env: Env(enclosing: self.env))
        }
    }

    private func printLoxValue(_ value: LoxValue) {
        switch value {
        case .nil: print("nil")
        case .number(let n):
            let s = String(n)
            if s.hasSuffix(".0") {
                print(s.dropLast(2))
            } else {
                print(s)
            }
        default: print(value)
        }
    }

    private func evalExpr(_ expr: Expr) throws(LoxError) -> LoxValue {
        switch expr {
        case .literal(let value): value
        case .grouping(let expr): try evalExpr(expr)
        case .unary(let op, let right): try evalUnaryExpr(op: op, expr: right)
        case .binary(let left, let op, let right):
            try evalBinaryExpr(left: left, op: op, right: right)
        case .var(let name): try lookupVar(name)
        case .assign(let name, let value): try assignVar(name: name, value: try evalExpr(value))
        }
    }

    private func execBlock(stmts: [Stmt], env: Env) throws(LoxError) {
        let previous = self.env

        self.env = env
        defer {
            self.env = previous
        }

        for stmt in stmts {
            try execute(stmt)
        }
    }

    private func lookupVar(_ name: Token) throws(LoxError) -> LoxValue {
        do {
            return try env[String(name.lexeme)]
        } catch {
            throw .runtimeError(message: error.description, line: name.line)
        }
    }

    private func assignVar(name: Token, value: LoxValue) throws(LoxError) -> LoxValue {
        do {
            try env.assign(name: String(name.lexeme), value: value)
            return value
        } catch {
            throw .runtimeError(message: error.description, line: name.line)
        }
    }

    private func evalUnaryExpr(op: Token, expr: Expr) throws(LoxError) -> LoxValue {
        let value = try evalExpr(expr)

        return switch op.kind {
        case .minus:
            try .number(-expectNumber(value))
        case .bang:
            .bool(!isTruthy(value))
        default:
            throw .runtimeError(message: "invalid unary expression", line: op.line)
        }
    }

    private func evalBinaryExpr(
        left: Expr,
        op: Token,
        right: Expr
    ) throws(LoxError) -> LoxValue {
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
                throw .runtimeError(message: "Operands must be two numbers or two strings.", line: op.line)
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
        case .equalEqual:
            .bool(leftValue == rightValue)
        case .bangEqual:
            .bool(leftValue != rightValue)
        default:
            fatalError("\(op.kind) on numbers is not supported")
        }
    }

    private func expectNumber(_ value: LoxValue) throws(LoxError) -> Double {
        guard case .number(let value) = value else {
            throw .runtimeError(message: "Operand '\(value)' must be a number.", line: -1)
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
