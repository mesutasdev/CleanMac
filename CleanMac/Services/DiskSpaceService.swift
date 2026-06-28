import Foundation

struct DiskSpaceInfo: Sendable, Equatable {
    let volumeName: String
    let totalBytes: Int64
    let freeBytes: Int64

    var usedBytes: Int64 {
        max(0, totalBytes - freeBytes)
    }

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, max(0, Double(usedBytes) / Double(totalBytes)))
    }

    func projectedFree(afterReclaiming bytes: Int64) -> Int64 {
        min(totalBytes, freeBytes + bytes)
    }
}

enum DiskSpaceService {
    static func current() -> DiskSpaceInfo? {
        let home = FileManager.default.homeDirectoryForCurrentUser

        if let urlInfo = volumeInfo(from: home) {
            return urlInfo
        }

        return filesystemInfo(at: home.path)
    }

    private static func volumeInfo(from url: URL) -> DiskSpaceInfo? {
        guard let values = try? url.resourceValues(forKeys: [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]) else {
            return nil
        }

        guard let total = numericCapacity(values.volumeTotalCapacity), total > 0 else {
            return nil
        }

        let free = numericCapacity(values.volumeAvailableCapacityForImportantUsage)
            ?? numericCapacity(values.volumeAvailableCapacity)
            ?? 0

        return DiskSpaceInfo(
            volumeName: values.volumeName ?? "Macintosh HD",
            totalBytes: total,
            freeBytes: max(0, free)
        )
    }

    private static func filesystemInfo(at path: String) -> DiskSpaceInfo? {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path),
              let totalNumber = attributes[.systemSize] as? NSNumber,
              let freeNumber = attributes[.systemFreeSize] as? NSNumber
        else {
            return nil
        }

        let total = totalNumber.int64Value
        guard total > 0 else { return nil }

        return DiskSpaceInfo(
            volumeName: "Macintosh HD",
            totalBytes: total,
            freeBytes: max(0, freeNumber.int64Value)
        )
    }

    private static func numericCapacity(_ value: Any?) -> Int64? {
        switch value {
        case let number as NSNumber:
            return number.int64Value
        case let int64 as Int64:
            return int64
        case let int as Int:
            return Int64(int)
        default:
            return nil
        }
    }
}
