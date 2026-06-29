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
            case .generalAppCaches:
                result = cleanGeneralAppCaches(target: target, home: home)
            case .diagnosticReports:
                result = cleanDiagnosticReports(target: target, home: home)
            case .nodeStaleModules, .nodeStaleNextCache, .staleProjectBuilds, .staleIosPods, .androidAvdSnapshots:
                result = cleanProjectArtifactFolders(target: target, home: home)
            default:
                if target.kind.usesShellCommand {
                    result = await cleanWithShell(target, home: home)
                } else if let path = target.kind.resolvePath(home: home) {
                    result = cleanDirectory(target: target, path: path)
                } else {
                    result = CleanResult(kind: target.kind, freedBytes: 0, success: false, message: L("clean.error.path_not_found"))
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
        let staleFolders = FlutterBuildHelper.staleArtifactFolders(home: home)

        guard !staleFolders.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        return deleteFolders(staleFolders, target: target)
    }

    private static func cleanLatestFlutterBuilds(target: CleanTarget, home: URL) -> CleanResult {
        let latestFolders = FlutterBuildHelper.latestArtifactFolders(home: home)

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

    private static func cleanGeneralAppCaches(target: CleanTarget, home: URL) -> CleanResult {
        let folders = SystemDataHelper.otherCacheFolders(home: home)
        guard !folders.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }
        return deleteFolders(folders, target: target)
    }

    private static func cleanDiagnosticReports(target: CleanTarget, home: URL) -> CleanResult {
        let paths = SystemDataHelper.diagnosticReportPaths(home: home)
        guard !paths.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        var freedBytes: Int64 = 0
        var lastError: String?

        for path in paths {
            let sizeBefore = DerivedDataHelper.directorySize(at: path)
            let result = cleanDirectory(
                target: CleanTarget(kind: target.kind, sizeBytes: sizeBefore, exists: true, isSelected: true),
                path: path
            )
            if result.success {
                freedBytes += result.freedBytes
            } else {
                lastError = result.message
            }
        }

        if freedBytes == 0, let lastError {
            return CleanResult(kind: target.kind, freedBytes: 0, success: false, message: lastError)
        }

        return CleanResult(kind: target.kind, freedBytes: freedBytes, success: true, message: nil)
    }

    private static func cleanProjectArtifactFolders(target: CleanTarget, home: URL) -> CleanResult {
        let folders: [URL]
        switch target.kind {
        case .nodeStaleModules:
            folders = NodeProjectHelper.staleNodeModuleFolders(home: home)
        case .nodeStaleNextCache:
            folders = NodeProjectHelper.staleNextCacheFolders(home: home)
        case .staleProjectBuilds:
            folders = DevProjectBuildHelper.staleBuildOutputs(home: home)
        case .staleIosPods:
            folders = DevProjectBuildHelper.staleIosPodsFolders(home: home)
        case .androidAvdSnapshots:
            folders = DevProjectBuildHelper.androidAvdSnapshotFolders(home: home)
        default:
            return CleanResult(kind: target.kind, freedBytes: 0, success: false, message: L("clean.error.unsupported"))
        }

        guard !folders.isEmpty else {
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        return deleteFolders(folders, target: target)
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
                message: lastError ?? L("clean.error.delete_failed")
            )
        }

        if failedCount > 0 {
            return CleanResult(
                kind: target.kind,
                freedBytes: freedBytes,
                success: true,
                message: L("clean.error.folders_failed", failedCount)
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

    private static func cleanWithShell(_ target: CleanTarget, home: URL) async -> CleanResult {
        switch target.kind {
        case .simulatorUnavailable:
            return await cleanUnavailableSimulators(target)
        case .timeMachineLocalSnapshots:
            return cleanLocalSnapshots(target: target, home: home)
        default:
            return CleanResult(kind: target.kind, freedBytes: 0, success: false, message: L("clean.error.unsupported"))
        }
    }

    private static func cleanUnavailableSimulators(_ target: CleanTarget) async -> CleanResult {
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

    private static func cleanLocalSnapshots(target: CleanTarget, home: URL) -> CleanResult {
        let before = DiskSpaceService.current()?.freeBytes ?? 0
        let outcome = SystemDataHelper.deleteLocalSnapshots()

        guard outcome.deleted > 0 else {
            if let error = outcome.error {
                return CleanResult(kind: target.kind, freedBytes: 0, success: false, message: error)
            }
            return CleanResult(kind: target.kind, freedBytes: 0, success: true, message: nil)
        }

        let after = DiskSpaceService.current()?.freeBytes ?? before
        let freedBytes = max(after - before, target.sizeBytes)
        return CleanResult(kind: target.kind, freedBytes: freedBytes, success: true, message: nil)
    }
}
