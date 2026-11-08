import SwiftUI

struct NewMachineActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var newMachineAction: (() -> Void)? {
        get { self[NewMachineActionKey.self] }
        set { self[NewMachineActionKey.self] = newValue }
    }
}
