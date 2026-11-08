import Foundation

public struct FileDownloader: Sendable {
    public init() {}

    public func download(
        from source: URL,
        to destination: URL,
        checksum: Checksum? = nil,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let coordinator = DownloadCoordinator(progress: progress)
        let temporary: URL
        do {
            temporary = try await coordinator.run(from: source)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        }
        defer { FileSystem.removeIfExists(temporary) }

        if let checksum {
            progress(1)
            try checksum.verify(temporary)
        }

        try FileSystem.createDirectory(destination.deletingLastPathComponent())
        FileSystem.removeIfExists(destination)
        try FileManager.default.moveItem(at: temporary, to: destination)
    }
}

private final class DownloadCoordinator: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let progress: @Sendable (Double) -> Void
    private let lock = NSLock()
    private var continuation: CheckedContinuation<URL, Error>?
    private var session: URLSession?
    private var task: URLSessionDownloadTask?
    private var isFinished = false
    private var isCancelled = false

    init(progress: @escaping @Sendable (Double) -> Void) {
        self.progress = progress
    }

    func run(from source: URL) async throws -> URL {
        defer { invalidateSession() }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                start(source: source, continuation: continuation)
            }
        } onCancel: {
            cancel()
        }
    }

    private func start(source: URL, continuation: CheckedContinuation<URL, Error>) {
        lock.lock()
        guard !isCancelled else {
            lock.unlock()
            continuation.resume(throwing: CancellationError())
            return
        }

        self.continuation = continuation
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: source)
        self.session = session
        self.task = task
        lock.unlock()

        task.resume()
    }

    private func cancel() {
        lock.lock()
        isCancelled = true
        let task = self.task
        lock.unlock()
        task?.cancel()
    }

    private func invalidateSession() {
        lock.lock()
        let session = self.session
        self.session = nil
        self.task = nil
        lock.unlock()
        session?.finishTasksAndInvalidate()
    }

    private func finish(_ result: Result<URL, Error>) {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        isFinished = true
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }

    private var isComplete: Bool {
        lock.lock()
        let value = isFinished
        lock.unlock()
        return value
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0, !isComplete else { return }
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progress(min(1, max(0, fraction)))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let response = downloadTask.response as? HTTPURLResponse,
           !(200..<300).contains(response.statusCode) {
            let fileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "the download"
            finish(.failure(PetalError.downloadFailed("The server answered \(response.statusCode) for \(fileName).")))
            return
        }

        let kept = FileManager.default.temporaryDirectory
            .appendingPathComponent("petal-download-\(UUID().uuidString)")
        do {
            try FileManager.default.moveItem(at: location, to: kept)
            finish(.success(kept))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else {
            finish(.failure(PetalError.downloadFailed("The download ended before it finished.")))
            return
        }
        finish(.failure(error))
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(request.upgradedToHTTPS)
    }
}

private extension URLRequest {
    var upgradedToHTTPS: URLRequest {
        guard let url,
              url.scheme == "http",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return self }
        components.scheme = "https"
        var request = self
        request.url = components.url
        return request
    }
}
