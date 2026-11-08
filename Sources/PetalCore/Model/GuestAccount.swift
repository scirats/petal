import Foundation

public struct GuestAccount: Equatable, Sendable {
    public var fullName: String
    public var username: String
    public var password: String

    public init(fullName: String, username: String, password: String) {
        self.fullName = fullName
        self.username = username
        self.password = password
    }

    public static func suggested() -> GuestAccount {
        let username = NSUserName()
            .lowercased()
            .filter { character in
                character.isASCII && (character.isLetter || character.isNumber || character == "-" || character == "_")
            }
        return GuestAccount(
            fullName: NSFullUserName(),
            username: username.isEmpty ? "user" : username,
            password: ""
        )
    }

    public func validate() throws {
        let allowed = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "-_"))
        guard let first = username.unicodeScalars.first,
              CharacterSet.lowercaseLetters.contains(first) || first == Unicode.Scalar("_"),
              username.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              username.count <= 32,
              !Self.reservedUsernames.contains(username)
        else {
            throw PetalError.unsupported(
                "Use a username of lowercase letters, digits, “-” or “_”, starting with a letter."
            )
        }

        guard password.count >= 4 else {
            throw PetalError.unsupported("Choose a password of at least 4 characters for the guest account.")
        }
    }

    private static let reservedUsernames: Set<String> = [
        "root", "admin", "administrator", "guest", "defaultaccount", "system",
    ]
}
