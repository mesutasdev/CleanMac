import Foundation

enum SystemDataHelper {
    /// Cache folders already tracked by dedicated CleanMac targets.
    static func excludedCacheRelativePaths(home: URL) -> [String] {
        [
            "Library/Caches/com.apple.dt.Xcode",
            "Library/Caches/CocoaPods",
            "Library/Caches/Homebrew",
            "Library/Caches/org.swift.swiftpm",
        ]
    }

    static func otherCacheFolders(home: URL) -> [URL] {
        let cachesRoot = home.appending(path: "Library/Caches")
        guard FileManager.default.fileExists(atPath: cachesRoot.path),
              let contents = try? FileManager.default.contentsOfDirectory(
                at: cachesRoot,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              )
        else {
            return []
        }

        let excluded = Set(excludedCacheRelativePaths(home: home))
        return contents.filter { url in
            let relative = url.path.hasPrefix(home.path + "/")
                ? String(url.path.dropFirst(home.path.count + 1))
                : url.lastPathComponent
            guard !excluded.contains(relative) else { return false }
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else { return false }
            return DerivedDataHelper.directorySize(at: url) > 0
        }
        .sorted { DerivedDataHelper.directorySize(at: $0) > DerivedDataHelper.directorySize(at: $1) }
    }

    static func diagnosticReportPaths(home: URL) -> [URL] {
        [
            home.appending(path: "Library/Logs/DiagnosticReports"),
            home.appending(path: "Library/Logs/CrashReporter"),
            home.appending(path: "Library/Application Support/CrashReporter"),
        ].filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func totalSize(of urls: [URL]) -> Int64 {
        urls.reduce(0) { $0 + DerivedDataHelper.directorySize(at: $1) }
    }

    static func deletableLocalSnapshotNames() -> [String] {
        let output = runCommand(executable: "/usr/bin/tmutil", arguments: ["listlocalsnapshots", "/"])
        return output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.contains("com.apple.TimeMachine.") && $0.hasSuffix(".local") }
    }

    static func deleteLocalSnapshots() -> (deleted: Int, error: String?) {
        let snapshots = deletableLocalSnapshotNames()
        guard !snapshots.isEmpty else { return (0, nil) }

        var deleted = 0
        var lastError: String?

        for snapshot in snapshots {
            guard let date = snapshotDate(from: snapshot) else { continue }
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
            process.arguments = ["deletelocalsnapshots", date]
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                lastError = error.localizedDescription
                continue
            }

            if process.terminationStatus == 0 {
                deleted += 1
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                lastError = String(data: data, encoding: .utf8) ?? L("clean.error.delete_failed")
            }
        }

        return (deleted, lastError)
    }

    static func purgeableBytesEstimate(home: URL) -> Int64 {
        guard let values = try? home.resourceValues(forKeys: [
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]) else {
            return 0
        }

        func capacity(_ value: Any?) -> Int64? {
            switch value {
            case let number as NSNumber: return number.int64Value
            case let int64 as Int64: return int64
            case let int as Int: return Int64(int)
            default: return nil
            }
        }

        guard
            let available = capacity(values.volumeAvailableCapacity),
            let important = capacity(values.volumeAvailableCapacityForImportantUsage)
        else {
            return 0
        }

        return max(0, important - available)
    }

    private static func snapshotDate(from snapshotName: String) -> String? {
        let prefix = "com.apple.TimeMachine."
        let suffix = ".local"
        guard snapshotName.hasPrefix(prefix), snapshotName.hasSuffix(suffix) else { return nil }
        let start = snapshotName.index(snapshotName.startIndex, offsetBy: prefix.count)
        let end = snapshotName.index(snapshotName.endIndex, offsetBy: -suffix.count)
        guard start < end else { return nil }
        return String(snapshotName[start..<end])
    }

    private static func runCommand(executable: String, arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return error.localizedDescription
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
