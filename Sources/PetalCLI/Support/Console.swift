import Foundation

enum Console {
    static func line(_ text: String = "") {
        write(text + "\n")
    }

    static func write(_ text: String) {
        FileHandle.standardOutput.write(Data(text.utf8))
    }

    static func error(_ text: String) {
        FileHandle.standardError.write(Data((text + "\n").utf8))
    }
}
