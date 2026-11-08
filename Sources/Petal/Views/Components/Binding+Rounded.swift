import SwiftUI

extension Binding where Value == Double {
    var rounded: Binding<Double> {
        Binding<Double>(
            get: { wrappedValue.rounded() },
            set: { wrappedValue = $0.rounded() }
        )
    }
}
