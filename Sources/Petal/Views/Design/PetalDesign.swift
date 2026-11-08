import Luminare
import SwiftUI

extension View {
    func petalDesign() -> some View {
        self
            .luminareMinHeight(PetalMetrics.controlHeight)
            .luminareCornerRadius(PetalMetrics.fieldCornerRadius)
            .luminareSectionHorizontalPadding(PetalSpacing.medium)
            .luminareSurfaceStyle(PetalSurface.minimal)
            .luminareHasDividers(false)
            .luminareFilledStates(.all)
            .luminareFormLayout(.stacked)
            .luminareFormSpacing(PetalSpacing.large)
            .luminareComposeControlSize(.regular)
            .luminareSliderLayout(.compact(textBoxWidth: PetalMetrics.sliderValueWidth))
            .luminareButtonRowSpacing(PetalSpacing.small)
    }
}
