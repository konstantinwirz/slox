import ArgumentParser
import Foundation
import Lox

enum CliAction: String, CaseIterable, ExpressibleByArgument {
    case tokenize
    case parse
    case eval
    case run
}

@main
struct SLox: ParsableCommand {

    @Argument var action: CliAction
    @Option(name: .customShort(Character("f"))) var inputFile: String

    mutating func run() throws {
        let fileContent = try String(contentsOfFile: inputFile, encoding: .utf8)
        switch action {
        case .tokenize:
            let scanner = Scanner(source: fileContent)
            while let token = try scanner.scanNextToken() {
                print(token)
            }
        case .parse:
            let parser = Parser(source: fileContent)
            let expr = try parser.parseExpr()
            print(expr)
        case .eval:
            let interpreter = Interpreter(source: fileContent)
            let result =
                switch try interpreter.eval() {
                case .number(let n): String(format: "%.0f", n)
                case let a: a.description
                }
            print(result)
        case .run:
            let interpreter = Interpreter(source: fileContent)
            do {
                try interpreter.run()
            } catch {
                FileHandle.standardError.write("\(error)\n".data(using: .utf8)!)
                switch error {
                case .scanError, .parseError:
                    throw ExitCode(65)
                case .runtimeError:
                    throw ExitCode(70)
                }
            }
        }
    }

}
