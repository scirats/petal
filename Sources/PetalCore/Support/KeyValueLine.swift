import Foundation

struct KeyValueLine {
    let key: String
    let value: String

    init?(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let separator = trimmed.firstIndex(of: ":") else { return nil }
        let key = trimmed[..<separator].trimmingCharacters(in: .whitespaces)
        let value = trimmed[trimmed.index(after: separator)...].trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return nil }
        self.key = key
        self.value = value
    }
}
