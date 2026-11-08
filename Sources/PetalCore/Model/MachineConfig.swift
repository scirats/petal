import Foundation

public struct MachineConfig: Codable, Equatable, Sendable {
    public var name: String
    public var resources: MachineResources
    public var diskFileName: String
    public var display: DisplaySpec
    public var macAddress: String
    public var installerImagePath: String?
    public var sharedFolders: [SharedFolder]
    public var rosetta: Bool
    public var clipboardSharing: Bool
    public var audioInput: Bool

    public init(
        name: String,
        resources: MachineResources = MachineResources(),
        diskFileName: String = "disk.img",
        display: DisplaySpec = DisplaySpec(),
        macAddress: String,
        installerImagePath: String? = nil,
        sharedFolders: [SharedFolder] = [],
        rosetta: Bool = false,
        clipboardSharing: Bool = true,
        audioInput: Bool = false
    ) {
        self.name = name
        self.resources = resources
        self.diskFileName = diskFileName
        self.display = display
        self.macAddress = macAddress
        self.installerImagePath = installerImagePath
        self.sharedFolders = sharedFolders
        self.rosetta = rosetta
        self.clipboardSharing = clipboardSharing
        self.audioInput = audioInput
    }
}
