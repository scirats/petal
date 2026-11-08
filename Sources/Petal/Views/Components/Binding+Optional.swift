import SwiftUI

extension Binding where Value == String {
    var optional: Binding<String?> {
        Binding<String?>(
            get: { wrappedValue },
            set: { wrappedValue = $0 ?? "" }
        )
    }
}
