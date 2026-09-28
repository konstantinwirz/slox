
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


    // program        → declaration* EOF ;
    //
    // declaration    → varDecl
    //                | statement ;
    //
    // statement      → exprStmt
    //                | printStmt ;
    public func parse() throws(ParseError) -> Stmt? {
        if try isAtEnd() {
            return nil
        }

        do {
            return try parsseDecl()
        } catch {
            print("[line \(error.line)] \(error.message)")
            try sync()
            return try parse()
        }
    }

    private func parsseDecl() throws(ParseError) -> Stmt {
        if let _ = try matches(.var) {
            return try parseVarDecl();
        }

        return try parseStmt()
    }

    private func parseStmt() throws(ParseError) -> Stmt {
        if let _ = try matches(.print) {
            return try parsePrintStmt()
        }

        return try parseExprStmt()
    }

    public func parseExpr() throws(ParseError) -> Expr {
        try parseEqualityExpr()
    }

    private func parseVarDecl() throws(ParseError) -> Stmt {
        let name = try consume(.identifier, errorMessage: "Expect variable name.")

        let initializer: Expr? = if let _ = try matches(.equal) {
            try parseExpr()
        } else {
            nil
        }

        try consume(.semicolon, errorMessage: "Expect ';' after variable declaration.")
        return .var(name: name, initializer: initializer, loc: Location(line: scanner.line))
    }

    private func parseExprStmt() throws(ParseError) -> Stmt {
        let expr = try parseExpr()
        try consume(.semicolon, errorMessage: "Expect ';' after expression.")
        return .expr(expr: expr, loc: Location(line: scanner.line))
    }

    private func parsePrintStmt() throws(ParseError) -> Stmt {
        let expr = try parseExpr()
        try consume(.semicolon, errorMessage: "Expect ';' after value.")
        return .print(expr: expr, loc: Location(line: scanner.line))
    }

    private func parseEqualityExpr() throws(ParseError) -> Expr {
        var expr = try parseComparisonExpr()

        while let op = try matches(.bangEqual, .equalEqual) {
            let right = try parseComparisonExpr()
            expr = .binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func parseComparisonExpr() throws(ParseError) -> Expr {
        var expr = try parseTermExpr()

        while let op = try matches(.greater, .greaterEqual, .less, .lessEqual) {
            let right = try parseTermExpr()
            expr = .binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func parseTermExpr() throws(ParseError) -> Expr {
        var expr = try parseFactorExpr()

        while let op = try matches(.plus, .minus) {
            let right = try parseFactorExpr()
            expr = .binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func parseFactorExpr() throws(ParseError) -> Expr {
        var expr = try parseUnaryExpr()

        while let op = try matches(.star, .slash) {
            let right = try parseUnaryExpr()
            expr = .binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func parseUnaryExpr() throws(ParseError) -> Expr {
        if let op = try matches(.bang, .minus) {
            let right = try parseUnaryExpr()
            return .unary(op: op, right: right)
        }

        return try parsePrimaryExpr()
    }

    private func parsePrimaryExpr() throws(ParseError) -> Expr {
        if (try matches(.false)) != nil { return .literal(.bool(false)) }
        if (try matches(.true)) != nil { return .literal(.bool(true)) }
        if (try matches(.nil)) != nil { return .literal(.nil) }

        if let token = try matches(.number, .string) {
            return .literal(token.literal)
        }

        if let token = try matches(.identifier) {
            return .var(name: token)
        }

        if (try matches(.leftParen)) != nil {
            let expr = try parseExpr()
            try consume(.rightParen, errorMessage: "Expect ')' after expression.")
            return .grouping(expr)
        }

        throw ParseError("Expect expression.", at: scanner.line)
    }

    @discardableResult
    private func consume(_ tokenKind: TokenKind, errorMessage: String) throws(ParseError) -> Token {
        if try check(tokenKind) {
            return try advance()
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
                precondition(tokenBuffer.isEmpty, "tokenBuffer should be empty before appending new token")
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

        precondition(!tokenBuffer.isEmpty, "tokenBuffer should not be empty when peeking")
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
