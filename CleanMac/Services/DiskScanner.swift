import Foundation

enum DiskScanner {
    private struct ScanMeasurement {
        var sizeBytes: Int64
        var exists: Bool
        var detail: String?
    }

    static func scanAll() async -> [CleanTarget] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var results = CleanTarget.makeDefaults()

        await withTaskGroup(of: (Int, ScanMeasurement).self) { group in
            for (index, target) in results.enumerated() {
                group.addTask {
                    let measurement = await measureTarget(target.kind, home: home)
                    return (index, measurement)
                }
            }

            for await (index, measurement) in group {
                results[index].sizeBytes = measurement.sizeBytes
                results[index].exists = measurement.exists
                results[index].detail = measurement.detail
            }
        }

        return results.sorted {
            if $0.kind.category.sortOrder != $1.kind.category.sortOrder {
                return $0.kind.category.sortOrder < $1.kind.category.sortOrder
            }
            return $0.sizeBytes > $1.sizeBytes
        }
    }

    private static func measureTarget(_ kind: CleanTargetKind, home: URL) async -> ScanMeasurement {
        if kind == .xcodeDerivedData || kind == .xcodeDerivedDataLastBuild {
            return measureDerivedData(kind, home: home)
        }

        if kind == .flutterStaleBuilds || kind == .flutterLastBuild {
            return measureFlutterBuilds(kind, home: home)
        }

        if kind == .xcodeDeviceSupport || kind == .xcodeDeviceSupportLatest {
            return measureDeviceSupport(kind, home: home)
        }

        if kind.usesShellCommand {
            let size = await shellCommandSize(for: kind)
            return ScanMeasurement(sizeBytes: size, exists: size > 0, detail: nil)
        }

        guard let path = kind.resolvePath(home: home) else {
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
        }

        let exists = FileManager.default.fileExists(atPath: path.path)
        guard exists else { return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil) }

        let size = DerivedDataHelper.directorySize(at: path)
        return ScanMeasurement(sizeBytes: size, exists: size > 0, detail: nil)
    }

    private static func measureDerivedData(_ kind: CleanTargetKind, home: URL) -> ScanMeasurement {
        let derivedDataURL = DerivedDataHelper.derivedDataURL(home: home)
        guard FileManager.default.fileExists(atPath: derivedDataURL.path) else {
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
        }

        let latest = DerivedDataHelper.latestProjectFolder(in: derivedDataURL)
        let stale = DerivedDataHelper.staleProjectFolders(in: derivedDataURL)
        let systemCaches = DerivedDataHelper.systemCacheFolders(in: derivedDataURL)

        switch kind {
        case .xcodeDerivedData:
            let totalSize = DerivedDataHelper.totalSize(of: stale + systemCaches)
            let detail = latest.map { "\(DerivedDataHelper.displayName(for: $0)) korunuyor" }
            return ScanMeasurement(sizeBytes: totalSize, exists: totalSize > 0, detail: detail)

        case .xcodeDerivedDataLastBuild:
            guard let latest else {
                return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
            }
            let size = DerivedDataHelper.directorySize(at: latest)
            let detail = "Proje: \(DerivedDataHelper.displayName(for: latest))"
            return ScanMeasurement(sizeBytes: size, exists: size > 0, detail: detail)

        default:
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
        }
    }

    private static func measureFlutterBuilds(_ kind: CleanTargetKind, home: URL) -> ScanMeasurement {
        let projectsRoot = FlutterBuildHelper.projectsRootURL(home: home)
        guard FileManager.default.fileExists(atPath: projectsRoot.path) else {
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
        }

        let latest = FlutterBuildHelper.latestProject(in: projectsRoot)
        let staleFolders = FlutterBuildHelper.staleArtifactFolders(in: projectsRoot)

        switch kind {
        case .flutterStaleBuilds:
            let totalSize = FlutterBuildHelper.totalSize(of: staleFolders)
            let detail = latest.map { "\(FlutterBuildHelper.displayName(for: $0)) korunuyor" }
            return ScanMeasurement(sizeBytes: totalSize, exists: totalSize > 0, detail: detail)

        case .flutterLastBuild:
            let latestFolders = FlutterBuildHelper.latestArtifactFolders(in: projectsRoot)
            guard let latest, !latestFolders.isEmpty else {
                return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
            }
            let size = FlutterBuildHelper.totalSize(of: latestFolders)
            let detail = "Proje: \(FlutterBuildHelper.displayName(for: latest))"
            return ScanMeasurement(sizeBytes: size, exists: size > 0, detail: detail)

        default:
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
        }
    }

    private static func measureDeviceSupport(_ kind: CleanTargetKind, home: URL) -> ScanMeasurement {
        let deviceSupportURL = DeviceSupportHelper.deviceSupportURL(home: home)
        guard FileManager.default.fileExists(atPath: deviceSupportURL.path) else {
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
        }

        let stale = DeviceSupportHelper.staleFolders(in: deviceSupportURL)
        let latest = DeviceSupportHelper.latestFolders(in: deviceSupportURL)
        let preservedVersion = DeviceSupportHelper.preservedVersionLabel(in: deviceSupportURL)

        switch kind {
        case .xcodeDeviceSupport:
            let totalSize = DeviceSupportHelper.totalSize(of: stale)
            let detail: String?
            if let preservedVersion {
                detail = "iOS \(preservedVersion) korunuyor — simülatör değil"
            } else {
                detail = nil
            }
            return ScanMeasurement(sizeBytes: totalSize, exists: totalSize > 0, detail: detail)

        case .xcodeDeviceSupportLatest:
            let totalSize = DeviceSupportHelper.totalSize(of: latest)
            let detail = preservedVersion.map { "iOS \($0) — gerçek cihaz sembolleri" }
            return ScanMeasurement(sizeBytes: totalSize, exists: totalSize > 0, detail: detail)

        default:
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil)
        }
    }

    private static func shellCommandSize(for kind: CleanTargetKind) async -> Int64 {
        guard kind == .simulatorUnavailable else { return 0 }

        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "list", "devices", "unavailable"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return 0
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return 0 }

        let deviceCount = output.components(separatedBy: .newlines)
            .filter { $0.contains("(unavailable)") }
            .count

        return deviceCount > 0 ? Int64(deviceCount) * 100 * 1024 * 1024 : 0
    }
}
