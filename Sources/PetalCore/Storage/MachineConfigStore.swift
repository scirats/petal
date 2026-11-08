import Foundation

public enum MachineConfigStore {
    public static func load(from bundle: MachineBundle) throws -> MachineConfig {
        guard FileSystem.exists(bundle.configURL) else {
            throw PetalError.missingFile(bundle.configURL.path)
        }
        let data = try Data(contentsOf: bundle.configURL)
        return try decoder.decode(MachineConfig.self, from: data)
    }

    public static func save(_ config: MachineConfig, to bundle: MachineBundle) throws {
        let data = try encoder.encode(config)
        try data.write(to: bundle.configURL, options: .atomic)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        JSONDecoder()
    }
}
