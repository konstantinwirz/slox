

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
    private weak let enclosing: Env?

    init() {
        enclosing = nil
    }

    init(enclosing env: Env) {
        enclosing = env
    }

    public func define(name: String, value: LoxValue) {
        values[name] = value
    }

    public func assign(name: String, value: LoxValue) throws(UndefinedVariableError) {
        if values[name] != nil {
            values[name] = value
            return
        }

        throw UndefinedVariableError(name)
    }

    subscript(name: String) -> LoxValue {
        get throws(UndefinedVariableError) {
            if let value = values[name] {
                return value
            }

            if let enclosing = enclosing {
                    return try enclosing[name]
            }

            throw UndefinedVariableError(name)
        }
    }
}