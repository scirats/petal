import Foundation

enum SnapshotCodec {
    static func encode(_ snapshot: Snapshot) throws -> Data {
        try encoder.encode(snapshot)
    }

    static func decode(_ data: Data) throws -> Snapshot {
        try decoder.decode(Snapshot.self, from: data)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
