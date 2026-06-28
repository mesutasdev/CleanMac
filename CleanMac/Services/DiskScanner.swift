import Foundation

enum DiskScanner {
    private struct ScanMeasurement {
        var sizeBytes: Int64
        var exists: Bool
        var detail: String?
        var locationPaths: [String] = []
        var locationNote: String?
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
                results[index].locationPaths = measurement.locationPaths
                results[index].locationNote = measurement.locationNote
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
            return await measureUnavailableSimulators(home: home)
        }

        guard let path = kind.resolvePath(home: home) else {
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil, locationPaths: [])
        }

        let exists = FileManager.default.fileExists(atPath: path.path)
        guard exists else { return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil, locationPaths: []) }

        let size = DerivedDataHelper.directorySize(at: path)
        return ScanMeasurement(
            sizeBytes: size,
            exists: size > 0,
            detail: nil,
            locationPaths: size > 0 ? [PathDisplayHelper.displayPath(path, home: home)] : []
        )
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
            let folders = stale + systemCaches
            let totalSize = DerivedDataHelper.totalSize(of: folders)
            let detail = latest.map { L("derived.preserved", DerivedDataHelper.displayName(for: $0)) }
            return ScanMeasurement(
                sizeBytes: totalSize,
                exists: totalSize > 0,
                detail: detail,
                locationPaths: PathDisplayHelper.displayPaths(folders, home: home)
            )

        case .xcodeDerivedDataLastBuild:
            guard let latest else {
                return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil, locationPaths: [])
            }
            let size = DerivedDataHelper.directorySize(at: latest)
            let detail = L("derived.project", DerivedDataHelper.displayName(for: latest))
            return ScanMeasurement(
                sizeBytes: size,
                exists: size > 0,
                detail: detail,
                locationPaths: [PathDisplayHelper.displayPath(latest, home: home)]
            )

        default:
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil, locationPaths: [])
        }
    }

    private static func measureFlutterBuilds(_ kind: CleanTargetKind, home: URL) -> ScanMeasurement {
        let projects = FlutterBuildHelper.projectsWithArtifacts(home: home)
        guard !projects.isEmpty else {
            let roots = FlutterBuildHelper.projectSearchRoots(home: home)
            if roots.isEmpty {
                return ScanMeasurement(
                    sizeBytes: 0,
                    exists: false,
                    detail: L("flutter.no_projects"),
                    locationPaths: [],
                    locationNote: L("flutter.search_note")
                )
            }
            return ScanMeasurement(
                sizeBytes: 0,
                exists: false,
                detail: L("flutter.no_build_folders"),
                locationPaths: PathDisplayHelper.displayPaths(roots, home: home),
                locationNote: L("flutter.scanned_projects")
            )
        }

        let latest = FlutterBuildHelper.latestProject(home: home)
        let staleFolders = FlutterBuildHelper.staleArtifactFolders(home: home)
        let rootsNote = FlutterBuildHelper.searchRootsSummary(home: home)

        switch kind {
        case .flutterStaleBuilds:
            let totalSize = FlutterBuildHelper.totalSize(of: staleFolders)
            let detail = latest.map { L("flutter.preserved", FlutterBuildHelper.displayName(for: $0), rootsNote) }
            return ScanMeasurement(
                sizeBytes: totalSize,
                exists: totalSize > 0,
                detail: detail,
                locationPaths: PathDisplayHelper.displayPaths(staleFolders, home: home),
                locationNote: L("flutter.projects_count", projects.count)
            )

        case .flutterLastBuild:
            let latestFolders = FlutterBuildHelper.latestArtifactFolders(home: home)
            guard let latest, !latestFolders.isEmpty else {
                return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil, locationPaths: [])
            }
            let size = FlutterBuildHelper.totalSize(of: latestFolders)
            let detail = L("flutter.project_detail", FlutterBuildHelper.displayName(for: latest), rootsNote)
            return ScanMeasurement(
                sizeBytes: size,
                exists: size > 0,
                detail: detail,
                locationPaths: PathDisplayHelper.displayPaths(latestFolders, home: home),
                locationNote: L("flutter.projects_count", projects.count)
            )

        default:
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil, locationPaths: [])
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
                detail = L("device.preserved_ios", preservedVersion)
            } else {
                detail = nil
            }
            return ScanMeasurement(
                sizeBytes: totalSize,
                exists: totalSize > 0,
                detail: detail,
                locationPaths: PathDisplayHelper.displayPaths(stale, home: home)
            )

        case .xcodeDeviceSupportLatest:
            let totalSize = DeviceSupportHelper.totalSize(of: latest)
            let detail = preservedVersion.map { L("device.latest_ios", $0) }
            return ScanMeasurement(
                sizeBytes: totalSize,
                exists: totalSize > 0,
                detail: detail,
                locationPaths: PathDisplayHelper.displayPaths(latest, home: home)
            )

        default:
            return ScanMeasurement(sizeBytes: 0, exists: false, detail: nil, locationPaths: [])
        }
    }

    private static func measureUnavailableSimulators(home: URL) async -> ScanMeasurement {
        let output = await runSimctlListUnavailable()
        let uuids = parseUnavailableDeviceUUIDs(from: output)
        let devicesRoot = home.appending(path: "Library/Developer/CoreSimulator/Devices")

        var totalSize: Int64 = 0
        var paths: [URL] = []

        for uuid in uuids {
            let devicePath = devicesRoot.appending(path: uuid)
            guard FileManager.default.fileExists(atPath: devicePath.path) else { continue }
            totalSize += DerivedDataHelper.directorySize(at: devicePath)
            paths.append(devicePath)
        }

        let detail = uuids.isEmpty ? nil : L(
            "simulator.detail",
            uuids.count,
            ByteCountFormatter.string(from: totalSize)
        )
        return ScanMeasurement(
            sizeBytes: totalSize,
            exists: !uuids.isEmpty,
            detail: detail,
            locationPaths: PathDisplayHelper.displayPaths(Array(paths.prefix(5)), home: home),
            locationNote: uuids.isEmpty
                ? nil
                : "Silme: xcrun simctl delete unavailable\(paths.count < uuids.count ? " (\(uuids.count) cihaz)" : "")"
        )
    }

    private static func runSimctlListUnavailable() async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
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
                    continuation.resume(returning: "")
                    return
                }

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: output)
            }
        }
    }

    private static func parseUnavailableDeviceUUIDs(from output: String) -> [String] {
        let pattern = #"\(([0-9A-Fa-f-]{36})\)\s*\(unavailable\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(output.startIndex..., in: output)

        return regex.matches(in: output, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let uuidRange = Range(match.range(at: 1), in: output)
            else { return nil }
            return String(output[uuidRange])
        }
    }
}
