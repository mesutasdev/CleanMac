import Foundation

struct CleanResult: Sendable {
    let kind: CleanTargetKind
    let freedBytes: Int64
    let success: Bool
    let message: String?
}

enum DiskCleaner {
    static func clean(targets: [CleanTarget]) async -> [CleanResult] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var results: [CleanResult] = []

        for target in targets where target.isSelected && target.sizeBytes > 0 {
            let result: CleanResult
            switch target.kind {
            case .xcodeDerivedData:
                result = cleanStaleDerivedData(target: target, home: home)
            case .xcodeDerivedDataLastBuild:
                result = cleanLatestDerivedData(target: target, home: home)
            case .flutterStaleBuilds:
                result = cleanStaleFlutterBuilds(target: target, home: home)
            case .flutterLastBuild:
                result = cleanLatestFlutterBuilds(target: target, home: home)
            case .xcodeDeviceSupport:
                result = cleanStaleDeviceSupport(target: target, home: home)
            case .xcodeDeviceSupportLatest:
                result = cleanLatestDeviceSupport(target: target, home: home)
            default:
                if target.kind.usesShellCommand {
                    result = await cleanWithShell(target)
                } else if let path = target.kind.resolvePath(home: home) {
                    result = cleanDirectory(target: target, path: path)
                } else {
                    result = CleanResult(kind: target.kind, freedBytes: 0, success: false, message: "Yol bulunamadı")
                }
            }
            results.append(result)
        }

        return results
    }

    private static func cleanStaleDerivedData(target: CleanTarget, home: URL) -> CleanResult {
        let derivedDataURL = DerivedDataHelper.derivedDataURL(home: home)
        let stale = DerivedDataHelper.staleProjectFolders(in: derivedDataURL)
        let systemCaches = DerivedDataHelper.systemCacheFolders(in: derivedDataURL)
        let foldersToDelete = stale + systemCaches

        guard !foldersToDelete.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        return deleteFolders(foldersToDelete, target: target)
    }

    private static func cleanLatestDerivedData(target: CleanTarget, home: URL) -> CleanResult {
        let derivedDataURL = DerivedDataHelper.derivedDataURL(home: home)
        guard let latest = DerivedDataHelper.latestProjectFolder(in: derivedDataURL) else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        return deleteFolders([latest], target: target)
    }

    private static func cleanStaleFlutterBuilds(target: CleanTarget, home: URL) -> CleanResult {
        let projectsRoot = FlutterBuildHelper.projectsRootURL(home: home)
        let staleFolders = FlutterBuildHelper.staleArtifactFolders(in: projectsRoot)

        guard !staleFolders.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        return deleteFolders(staleFolders, target: target)
    }

    private static func cleanLatestFlutterBuilds(target: CleanTarget, home: URL) -> CleanResult {
        let projectsRoot = FlutterBuildHelper.projectsRootURL(home: home)
        let latestFolders = FlutterBuildHelper.latestArtifactFolders(in: projectsRoot)

        guard !latestFolders.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        return deleteFolders(latestFolders, target: target)
    }

    private static func cleanStaleDeviceSupport(target: CleanTarget, home: URL) -> CleanResult {
        let deviceSupportURL = DeviceSupportHelper.deviceSupportURL(home: home)
        let stale = DeviceSupportHelper.staleFolders(in: deviceSupportURL)

        guard !stale.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        return deleteFolders(stale, target: target)
    }

    private static func cleanLatestDeviceSupport(target: CleanTarget, home: URL) -> CleanResult {
        let deviceSupportURL = DeviceSupportHelper.deviceSupportURL(home: home)
        let latest = DeviceSupportHelper.latestFolders(in: deviceSupportURL)

        guard !latest.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        return deleteFolders(latest, target: target)
    }

    private static func deleteFolders(_ folders: [URL], target: CleanTarget) -> CleanResult {
        let fm = FileManager.default
        var freedBytes: Int64 = 0
        var lastError: String?
        var failedCount = 0

        for folder in folders {
            guard fm.fileExists(atPath: folder.path) else { continue }
            let size = DerivedDataHelper.directorySize(at: folder)

            do {
                try fm.removeItem(at: folder)
                freedBytes += size
            } catch {
                failedCount += 1
                lastError = error.localizedDescription
            }
        }

        if freedBytes == 0, failedCount > 0 {
            return CleanResult(
                kind: target.kind,
                freedBytes: 0,
                success: false,
                message: lastError ?? "Silinemedi"
            )
        }

        if failedCount > 0 {
            return CleanResult(
                kind: target.kind,
                freedBytes: freedBytes,
                success: true,
                message: "\(failedCount) klasör silinemedi"
            )
        }

        return CleanResult(kind: target.kind, freedBytes: freedBytes, success: true, message: nil)
    }

    private static func cleanDirectory(target: CleanTarget, path: URL) -> CleanResult {
        let fm = FileManager.default
        guard fm.fileExists(atPath: path.path) else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        let sizeBefore = target.sizeBytes

        do {
            let contents = try fm.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            for item in contents {
                try fm.removeItem(at: item)
            }
            return CleanResult(kind: target.kind, freedBytes: sizeBefore, success: true, message: nil)
        } catch {
            do {
                try fm.removeItem(at: path)
                return CleanResult(kind: target.kind, freedBytes: sizeBefore, success: true, message: nil)
            } catch {
                return CleanResult(
                    kind: target.kind,
                    freedBytes: 0,
                    success: false,
                    message: error.localizedDescription
                )
            }
        }
    }

    private static func cleanWithShell(_ target: CleanTarget) async -> CleanResult {
        guard target.kind == .simulatorUnavailable else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: false, message: "Desteklenmiyor")
        }

        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "delete", "unavailable"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return CleanResult(kind: target.kind, freedBytes: 0, success: false, message: error.localizedDescription)
        }

        if process.terminationStatus == 0 {
            return CleanResult(kind: target.kind, freedBytes: target.sizeBytes, success: true, message: nil)
        }

        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Simülatör silinemedi"
        return CleanResult(kind: target.kind, freedBytes: 0, success: false, message: errorMessage)
    }
}
