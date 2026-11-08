import Foundation

public enum CloudInitSeed {
    public static func create(at destination: URL, account: GuestAccount, hostname: String, desktop: Bool) throws {
        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent("petal-cidata-\(UUID().uuidString)", isDirectory: true)
        try FileSystem.createDirectory(staging)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: staging.path)
        defer { FileSystem.removeIfExists(staging) }

        try metaData(hostname: hostname).write(
            to: staging.appendingPathComponent("meta-data"),
            atomically: true,
            encoding: .utf8
        )
        try CloudInitDocument(account: account, hostname: hostname, desktop: desktop)
            .render()
            .write(to: staging.appendingPathComponent("user-data"), atomically: true, encoding: .utf8)

        try ISOImage.create(from: staging, to: destination, volumeName: "cidata")
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
    }

    static func hostname(for machineName: String) -> String {
        let mapped = machineName.lowercased().map { character in
            character.isASCII && (character.isLetter || character.isNumber) ? character : "-"
        }
        let collapsed = String(mapped).split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? "petal" : String(collapsed.prefix(63))
    }

    private static func metaData(hostname: String) -> String {
        "instance-id: petal-\(UUID().uuidString.lowercased())\nlocal-hostname: \(hostname)\n"
    }
}
