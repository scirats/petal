import SwiftUI

struct InstallRow: View {
    @Environment(AppModel.self) private var model
    let job: InstallJob

    var body: some View {
        HStack(alignment: .top, spacing: PetalSpacing.medium) {
            VStack(alignment: .leading, spacing: PetalSpacing.xSmall) {
                Text(job.name)
                    .lineLimit(1)

                if let fraction = job.fraction {
                    ProgressView(value: fraction)
                        .progressViewStyle(.linear)
                } else if job.error == nil {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(job.summary)
                    .font(PetalText.caption)
                    .foregroundStyle(job.error == nil ? Color.secondary : Color.red)
                    .lineLimit(2)
            }

            Spacer(minLength: PetalSpacing.small)

            PetalIconButton(
                systemImage: "xmark",
                help: job.error == nil ? "Cancel" : "Dismiss"
            ) {
                model.installs.dismiss(job)
            }
        }
        .padding(.vertical, PetalSpacing.xSmall)
    }
}
