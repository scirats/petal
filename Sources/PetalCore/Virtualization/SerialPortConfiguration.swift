import Foundation
import Virtualization

enum SerialPortConfiguration {
    static func make(logURL: URL) throws -> [VZVirtioConsoleDeviceSerialPortConfiguration] {
        let log = try openLog(at: logURL)
        let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
        serial.attachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: nil,
            fileHandleForWriting: log
        )
        return [serial]
    }

    private static func openLog(at url: URL) throws -> FileHandle {
        if FileSystem.exists(url) {
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            return handle
        }

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
