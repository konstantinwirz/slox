

public struct UndefinedVariableError : Error, CustomStringConvertible {
    private let varName: String   
    init(_ varName: String) {
        self.varName = varName
    }

    public var description: String {
        "Undefined variable '\(varName)'."
    }
}

public class Env {
    private var values: [String: LoxValue] = [:]

    public func define(name: String, value: LoxValue) {
        values[name] = value
    }

    subscript(name: String) -> LoxValue {
        get throws(UndefinedVariableError) {
            guard let value = values[name] else {
                throw UndefinedVariableError(name)
            }
            return value
        }
    }
}