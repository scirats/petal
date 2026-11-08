import Foundation

enum ProcessRunner {
    static func run(_ executable: String, _ arguments: [String]) throws -> String {
        let identifier = UUID().uuidString
        let directory = FileManager.default.temporaryDirectory
        let outputURL = directory.appendingPathComponent("petal-process-\(identifier)-out")
        let errorURL = directory.appendingPathComponent("petal-process-\(identifier)-err")
        defer {
            FileSystem.removeIfExists(outputURL)
            FileSystem.removeIfExists(errorURL)
        }

        let outputHandle = try createFile(at: outputURL)
        let errorHandle = try createFile(at: errorURL)
        defer {
            try? outputHandle.close()
            try? errorHandle.close()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = outputHandle
        process.standardError = errorHandle
        try process.run()
        process.waitUntilExit()

        let output = try Data(contentsOf: outputURL)
        let errorOutput = try Data(contentsOf: errorURL)

        guard process.terminationStatus == 0 else {
            let message = String(decoding: errorOutput, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw PetalError.commandFailed(
                message.isEmpty ? "\(executable) exited \(process.terminationStatus)" : message
            )
        }

        return String(decoding: output, as: UTF8.self)
    }

    private static func createFile(at url: URL) throws -> FileHandle {
        guard FileManager.default.createFile(
            atPath: url.path,
            contents: nil,
            attributes: [.posixPermissions: 0o600]
        ) else {
            throw PetalError.fileAccessFailed(url.path)
        }
        return try FileHandle(forWritingTo: url)
    }
}
