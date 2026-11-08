import Darwin
import Foundation

enum PasswordPrompt {
    static func read(for username: String) throws -> String {
        let first = try readPassword("Password for \(username) in the guest: ")
        let second = try readPassword("Again: ")
        guard first == second else {
            throw CLIError("The passwords don’t match.")
        }
        return first
    }

    private static func readPassword(_ prompt: String) throws -> String {
        guard isatty(STDIN_FILENO) != 0 else {
            throw CLIError("--password is required when not running in a terminal.")
        }
        guard let value = getpass(prompt) else {
            throw CLIError("No password entered.")
        }
        return String(cString: value)
    }
}
