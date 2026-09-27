public enum Expr: CustomStringConvertible {
    case literal(LoxValue, line: Int)
    indirect case grouping(Expr, line: Int)
    indirect case unary(op: Token, right: Expr, line: Int)
    indirect case binary(left: Expr, op: Token, right: Expr, line: Int)

    public var description: String {
        switch self {
        case .literal(let literal, _):
            return literal.description
        case .grouping(let expr, _):
            return "(group \(expr))"
        case .unary(let op, let right, _):
            return "(\(op.lexeme) \(right))"
        case .binary(let left, let op, let right, _):
            return "(\(op.lexeme) \(left) \(right))"
        }
    }

    public var line: Int {
        switch self {
        case .literal(_, let line): line
        case .grouping(_, let line): line
        case .unary(_, _, let line): line
        case .binary(_, _, _, let line): line
        }
    }
}

public struct ParseError: Error, CustomStringConvertible {
    public let message: String
    public let line: Int

    public init(_ message: String, at line: Int) {
        self.message = message
        self.line = line
    }

    public var description: String {
        return "[line \(line)] \(message)"
    }
}

public class Parser {

    private let scanner: Scanner
    private var tokenBuffer: [Token] = []

    public init(source: String) {
        self.scanner = Scanner(source: source)
    }

    public func parseExpr() throws(ParseError) -> Expr {
        try parseEqualityExpr()
    }

    private func parseEqualityExpr() throws(ParseError) -> Expr {
        var expr = try parseComparisonExpr()

        while let op = try matches(.bangEqual, .equalEqual) {
            let right = try parseComparisonExpr()
            expr = .binary(left: expr, op: op, right: right, line: scanner.line)
        }

        return expr
    }

    private func parseComparisonExpr() throws(ParseError) -> Expr {
        var expr = try parseTermExpr()

        while let op = try matches(.greater, .greaterEqual, .less, .lessEqual) {
            let right = try parseTermExpr()
            expr = .binary(left: expr, op: op, right: right, line: scanner.line)
        }

        return expr
    }

    private func parseTermExpr() throws(ParseError) -> Expr {
        var expr = try parseFactorExpr()

        while let op = try matches(.plus, .minus) {
            let right = try parseFactorExpr()
            expr = .binary(left: expr, op: op, right: right, line: scanner.line)
        }

        return expr
    }

    private func parseFactorExpr() throws(ParseError) -> Expr {
        var expr = try parseUnaryExpr()

        while let op = try matches(.star, .slash) {
            let right = try parseUnaryExpr()
            expr = .binary(left: expr, op: op, right: right, line: scanner.line)
        }

        return expr
    }

    private func parseUnaryExpr() throws(ParseError) -> Expr {
        if let op = try matches(.bang, .minus) {
            let right = try parseUnaryExpr()
            return .unary(op: op, right: right, line: scanner.line)
        }

        return try parsePrimaryExpr()
    }

    private func parsePrimaryExpr() throws(ParseError) -> Expr {
        if (try matches(.false)) != nil { return .literal(.bool(false), line: scanner.line) }
        if (try matches(.true)) != nil { return .literal(.bool(true), line: scanner.line) }
        if (try matches(.nil)) != nil { return .literal(.nil, line: scanner.line) }

        if let token = try matches(.number, .string) {
            return .literal(token.literal, line: scanner.line)
        }

        if (try matches(.leftParen)) != nil {
            let expr = try parseExpr()
            try consume(.rightParen, errorMessage: "Expect ')' after expression.")
            return .grouping(expr, line: scanner.line)
        }

        throw ParseError("Expect expression.", at: scanner.line)
    }

    private func consume(_ tokenKind: TokenKind, errorMessage: String) throws(ParseError) {
        if try check(tokenKind) {
            _ = try advance()
            return
        }

        throw ParseError(errorMessage, at: scanner.line)
    }

    private func matches(_ tokenKinds: TokenKind...) throws(ParseError) -> Token? {
        for kind in tokenKinds {
            if try check(kind) {
                return try advance()
            }
        }

        return nil
    }

    private func check(_ tokenKind: TokenKind) throws(ParseError) -> Bool {
        try peek()?.kind == tokenKind
    }

    private func isAtEnd() throws(ParseError) -> Bool {
        if !tokenBuffer.isEmpty {
            return false
        }

        // no tokens in the buffer, try to scan next token
        do {
            if let token = try scanner.scanNextToken(), token.kind != .eof {
                precondition(
                    tokenBuffer.isEmpty, "tokenBuffer should be empty before appending new token")
                tokenBuffer.append(token)
                return false
            }
        } catch {
            throw ParseError(error.message, at: error.line)
        }

        return true
    }

    private func advance() throws(ParseError) -> Token {
        if try isAtEnd() {
            throw ParseError("Unexpected end of input", at: scanner.line)
        }

        precondition(!tokenBuffer.isEmpty, "tokenBuffer should not be empty when advancing")
        return tokenBuffer.removeFirst()
    }

    private func peek() throws(ParseError) -> Token? {
        if try isAtEnd() {
            return nil
        }

        precondition(!tokenBuffer.isEmpty, "tokenBuffer should not be empty when advancing")
        return tokenBuffer.first
    }

    private func sync() throws(ParseError) {
        while !(try isAtEnd()) {
            let token = try advance()
            if token.kind == .semicolon {
                return
            }

            if let nextToken = try peek() {
                switch nextToken.kind {
                case .class, .fun, .var, .for, .if, .while, .print, .return:
                    return
                default:
                    continue
                }
            }
        }
    }

}
