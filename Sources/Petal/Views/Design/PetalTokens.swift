import SwiftUI

enum PetalSpacing {
    static let hairline: CGFloat = 2
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
    static let xxLarge: CGFloat = 32
}

enum PetalMetrics {
    static let sidebarWidth: CGFloat = 240
    static let panePadding: CGFloat = 20
    static let paneMaxWidth: CGFloat = 720

    static let libraryMinWidth: CGFloat = 860
    static let libraryMinHeight: CGFloat = 560
    static let libraryWidth: CGFloat = 980
    static let libraryHeight: CGFloat = 660
    static let machineWidth: CGFloat = 1280
    static let machineHeight: CGFloat = 840

    static let sheetWidth: CGFloat = 520
    static let sheetHeight: CGFloat = 700

    static let controlHeight: CGFloat = 36
    static let iconButtonSize: CGFloat = 36
    static let fieldWidth: CGFloat = 260
    static let titleFieldWidth: CGFloat = fieldWidth * 1.5
    static let fieldHeight: CGFloat = controlHeight
    static let fieldCornerRadius: CGFloat = 8
    static let sliderValueWidth: CGFloat = 64
    static let buttonMinWidth: CGFloat = 96
    static let startButtonWidth: CGFloat = buttonMinWidth * 1.25
    static let messageMaxWidth: CGFloat = paneMaxWidth / 2
    static let segmentHeight: CGFloat = fieldHeight - PetalSpacing.xSmall
    static let iconSize: CGFloat = 18
    static let statusDot: CGFloat = 6
    static let listRowHeight: CGFloat = 48
    static let listRowCornerRadius: CGFloat = 6
    static let emptyStateIcon: CGFloat = 34
}

enum PetalText {
    static let paneTitle = Font.title.weight(.semibold)
    static let sectionHeader = Font.subheadline.weight(.medium)
    static let numeric = Font.body.monospacedDigit()
    static let metadata = Font.callout
    static let caption = Font.caption
    static let sidebarIcon = Font.system(size: 15)
}
