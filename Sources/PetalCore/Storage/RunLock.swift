import Darwin
import Foundation

struct RunLock: Sendable {
    let fileURL: URL

    var isHeld: Bool {
        guard FileSystem.exists(fileURL), let descriptor = openFile(flags: O_RDONLY) else {
            return false
        }
        defer { close(descriptor) }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            return errno == EWOULDBLOCK
        }
        _ = flock(descriptor, LOCK_UN)
        return false
    }

    func acquire(ownerName: String) throws {
        if LockRegistry.shared.contains(fileURL) { return }

        guard let descriptor = openFile(flags: O_CREAT | O_RDWR) else {
            throw PetalError.fileAccessFailed(fileURL.path)
        }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            throw PetalError.machineRunning(ownerName)
        }
        _ = ftruncate(descriptor, 0)
        LockRegistry.shared.insert(fileURL, descriptor: descriptor)
    }

    func release() {
        guard let descriptor = LockRegistry.shared.remove(fileURL) else { return }
        _ = flock(descriptor, LOCK_UN)
        _ = ftruncate(descriptor, 0)
        close(descriptor)
    }

    private func openFile(flags: Int32) -> Int32? {
        let descriptor = fileURL.withUnsafeFileSystemRepresentation { path -> Int32 in
            guard let path else { return -1 }
            return open(path, flags, 0o600)
        }
        return descriptor >= 0 ? descriptor : nil
    }
}

private final class LockRegistry: @unchecked Sendable {
    static let shared = LockRegistry()

    private let lock = NSLock()
    private var descriptors: [String: Int32] = [:]

    func contains(_ url: URL) -> Bool {
        locked { descriptors[url.path] != nil }
    }

    func insert(_ url: URL, descriptor: Int32) {
        locked { descriptors[url.path] = descriptor }
    }

    func remove(_ url: URL) -> Int32? {
        locked { descriptors.removeValue(forKey: url.path) }
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
