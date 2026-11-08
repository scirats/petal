import Foundation

enum NewMachineSource: Hashable, CaseIterable {
    case download
    case file

    var title: String {
        switch self {
        case .download: "Download"
        case .file: "Local ISO"
        }
    }
}
