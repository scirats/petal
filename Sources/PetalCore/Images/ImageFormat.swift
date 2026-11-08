import Foundation

enum ImageFormat {
    static func isExpected(_ url: URL) -> Bool {
        switch url.pathExtension.lowercased() {
        case "iso":
            ISO9660.isValidDiscImage(url)
        case "xz":
            FileSignature.hasPrefix([0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00], at: url)
        case "img", "qcow2":
            QCOW2.isQCOW2(url)
        default:
            true
        }
    }
}
