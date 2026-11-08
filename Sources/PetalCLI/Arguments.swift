import Foundation

struct ArgumentReader {
    private let positionals: [String]
    private let values: [String: String]
    private let flags: Set<String>

    init(
        _ arguments: [String],
        flags flagNames: Set<String> = [],
        options optionNames: Set<String> = []
    ) throws {
        var positionals: [String] = []
        var values: [String: String] = [:]
        var flags: Set<String> = []
        var iterator = arguments.makeIterator()

        while let argument = iterator.next() {
            if argument == "--" {
                while let remaining = iterator.next() {
                    positionals.append(remaining)
                }
                break
            }

            guard argument.hasPrefix("--") else {
                positionals.append(argument)
                continue
            }

            let name = String(argument.dropFirst(2))
            if flagNames.contains(name) {
                flags.insert(name)
                continue
            }
            guard optionNames.contains(name) else {
                throw CLIError("Unknown option --\(name).")
            }
            guard let value = iterator.next() else {
                throw CLIError("--\(name) needs a value.")
            }
            values[name] = value
        }

        self.positionals = positionals
        self.values = values
        self.flags = flags
    }

    func requirePositionals(_ minimum: Int, maximum: Int = .max) throws {
        guard positionals.count >= minimum else {
            throw CLIError("Missing an argument. Run `petalctl help` for usage.")
        }
        guard positionals.count <= maximum else {
            throw CLIError("Too many arguments. Run `petalctl help` for usage.")
        }
    }

    func positional(_ index: Int, named name: String) throws -> String {
        guard index < positionals.count else {
            throw CLIError("Missing <\(name)>. Run `petalctl help` for usage.")
        }
        return positionals[index]
    }

    func remainingPositionals(from index: Int) -> [String] {
        guard index < positionals.count else { return [] }
        return Array(positionals[index...])
    }

    func option(_ name: String) -> String? {
        values[name]
    }

    func intOption(_ name: String) throws -> Int? {
        guard let text = values[name] else { return nil }
        guard let value = Int(text), value > 0 else {
            throw CLIError("--\(name) must be a positive whole number.")
        }
        return value
    }

    func toggleOption(_ name: String) throws -> Bool? {
        guard let text = values[name] else { return nil }
        switch text.lowercased() {
        case "on", "yes", "true", "1":
            return true
        case "off", "no", "false", "0":
            return false
        default:
            throw CLIError("--\(name) must be on or off.")
        }
    }

    func hasFlag(_ name: String) -> Bool {
        flags.contains(name)
    }

    func pathOption(_ name: String) -> String? {
        values[name].map(Self.absolutePath)
    }

    func pathPositional(_ index: Int, named name: String) throws -> String {
        Self.absolutePath(try positional(index, named: name))
    }

    static func absolutePath(_ path: String) -> String {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path
    }
}
