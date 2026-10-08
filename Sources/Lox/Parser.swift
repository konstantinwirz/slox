

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
    public func parse() throws(LoxError) -> Stmt? {
        if try isAtEnd() {
            return nil
        }

        do {
            return try parsseDecl()
        } catch {
            throw error
            //try sync()
            //return try parse()
        }
    }

    private func parsseDecl() throws(LoxError) -> Stmt {
        if let _ = try matches(.var) {
            return try parseVarDecl();
        }

        return try parseStmt()
    }

    private func parseStmt() throws(LoxError) -> Stmt {
        if let _ = try matches(.print) {
            return try parsePrintStmt()
        }

        if let _ = try matches(.leftBrace) {
            return try parseBlock()
        }

        return try parseExprStmt()
    }

    private func parseBlock() throws(LoxError) -> Stmt {
        var stmts: [Stmt] = [] 
        while try !check(.rightBrace), try !isAtEnd() {
            stmts.append(try parsseDecl())
        }

        try consume(.rightBrace, errorMessage: "Expect '}' after block.")
        return .block(stmts, loc: Location(line: scanner.line))
    }

    public func parseExpr() throws(LoxError) -> Expr {
        try parseAssignment()
    }

    private func parseAssignment() throws(LoxError) -> Expr {
        let expr = try parseEqualityExpr()

        if let equals = try matches(.equal) {
            let value = try parseAssignment()
            if case Expr.var(let name) = expr {
                return .assign(name: name, value: value)
            }

            throw .parseError(message: "Invalid assignment target.", line: equals.line, hint: " at '\(equals.lexeme)'")
        }

        return expr
    }

    private func parseVarDecl() throws(LoxError) -> Stmt {
        let name = try consume(.identifier, errorMessage: "Expect variable name.")

        let initializer: Expr? = if let _ = try matches(.equal) {
            try parseExpr()
        } else {
            nil
        }

        try consume(.semicolon, errorMessage: "Expect ';' after variable declaration.")
        return .var(name: name, initializer: initializer, loc: Location(line: scanner.line))
    }

    private func parseExprStmt() throws(LoxError) -> Stmt {
        let expr = try parseExpr()
        try consume(.semicolon, errorMessage: "Expect ';' after expression.")
        return .expr(expr: expr, loc: Location(line: scanner.line))
    }

    private func parsePrintStmt() throws(LoxError) -> Stmt {
        let expr = try parseExpr()
        try consume(.semicolon, errorMessage: "Expect ';' after value.")
        return .print(expr: expr, loc: Location(line: scanner.line))
    }

    private func parseEqualityExpr() throws(LoxError) -> Expr {
        var expr = try parseComparisonExpr()

        while let op = try matches(.bangEqual, .equalEqual) {
            let right = try parseComparisonExpr()
            expr = .binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func parseComparisonExpr() throws(LoxError) -> Expr {
        var expr = try parseTermExpr()

        while let op = try matches(.greater, .greaterEqual, .less, .lessEqual) {
            let right = try parseTermExpr()
            expr = .binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func parseTermExpr() throws(LoxError) -> Expr {
        var expr = try parseFactorExpr()

        while let op = try matches(.plus, .minus) {
            let right = try parseFactorExpr()
            expr = .binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func parseFactorExpr() throws(LoxError) -> Expr {
        var expr = try parseUnaryExpr()

        while let op = try matches(.star, .slash) {
            let right = try parseUnaryExpr()
            expr = .binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func parseUnaryExpr() throws(LoxError) -> Expr {
        if let op = try matches(.bang, .minus) {
            let right = try parseUnaryExpr()
            return .unary(op: op, right: right)
        }

        return try parsePrimaryExpr()
    }

    private func parsePrimaryExpr() throws(LoxError) -> Expr {
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

        throw .parseError(message: "Expect expression.", line: scanner.line, hint: " at '\(try peek()?.lexeme ?? "")'")
    }

    @discardableResult
    private func consume(_ tokenKind: TokenKind, errorMessage: String) throws(LoxError) -> Token {
        if try check(tokenKind) {
            return try advance()
        }

        let lexeme = try peek()?.lexeme ?? ""
        throw .parseError(message: "\(errorMessage)", line: scanner.line, hint: " at '\(lexeme)'")
    }

    private func matches(_ tokenKinds: TokenKind...) throws(LoxError) -> Token? {
        for kind in tokenKinds {
            if try check(kind) {
                return try advance()
            }
        }

        return nil
    }

    private func check(_ tokenKind: TokenKind) throws(LoxError) -> Bool {
        try peek()?.kind == tokenKind
    }

    private func isAtEnd() throws(LoxError) -> Bool {
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
            throw .parseError(message: error.message, line: error.line)
        }

        return true
    }

    private func advance() throws(LoxError) -> Token {
        if try isAtEnd() {
            throw .parseError(message: "Unexpected end of input", line: scanner.line)
        }

        precondition(!tokenBuffer.isEmpty, "tokenBuffer should not be empty when advancing")
        return tokenBuffer.removeFirst()
    }

    private func peek() throws(LoxError) -> Token? {
        if try isAtEnd() {
            return nil
        }

        precondition(!tokenBuffer.isEmpty, "tokenBuffer should not be empty when peeking")
        return tokenBuffer.first
    }

    private func sync() throws(LoxError) {
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
