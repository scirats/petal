import Foundation
import Observation
import PetalCore

@MainActor
@Observable
final class InstallCenter {
    @ObservationIgnored private let library: MachineLibrary
    @ObservationIgnored private let images: ImageService
    @ObservationIgnored var onCompletion: ((MachineBundle) -> Void)?

    private(set) var jobs: [InstallJob] = []

    init(library: MachineLibrary) {
        self.library = library
        images = ImageService(directory: library.imagesDirectory)
    }

    func start(image: CatalogImage, account: GuestAccount?, name: String, resources: MachineResources) {
        let job = InstallJob(name: name)
        jobs.append(job)

        job.task = Task { [weak self] in
            guard let self else { return }
            do {
                job.update(status: "Finding the latest \(image.name)…", fraction: nil)
                let resolved = try await images.resolve(image)
                let download = try await images.download(
                    resolved,
                    progress: job.reporter(for: "Downloading \(image.name) \(resolved.version)…")
                )
                job.update(status: "Creating the machine…", fraction: nil)
                let bundle = try await createBundle(
                    image: image,
                    download: download,
                    name: name,
                    account: account,
                    resources: resources
                )
                if Task.isCancelled {
                    try? library.trash(bundle)
                    return
                }
                complete(job, bundle: bundle)
            } catch {
                guard !Task.isCancelled else { return }
                job.fraction = nil
                job.error = error.localizedDescription
                job.task = nil
            }
        }
    }

    func dismiss(_ job: InstallJob) {
        job.task?.cancel()
        job.task = nil
        jobs.removeAll { $0.id == job.id }
    }

    private func createBundle(
        image: CatalogImage,
        download: URL,
        name: String,
        account: GuestAccount?,
        resources: MachineResources
    ) async throws -> MachineBundle {
        let library = library
        return try await Task.detached(priority: .userInitiated) {
            if case let .cloudImage(desktop) = image.kind {
                guard let account else {
                    throw PetalError.unsupported("A Linux account is required to set up \(image.name).")
                }
                return try library.createCloud(
                    name: name,
                    archive: download,
                    account: account,
                    desktop: desktop,
                    resources: resources
                )
            }
            return try library.createLinux(
                name: name,
                installerISO: download,
                resources: resources
            )
        }.value
    }

    private func complete(_ job: InstallJob, bundle: MachineBundle) {
        job.task = nil
        jobs.removeAll { $0.id == job.id }
        onCompletion?(bundle)
    }
}
