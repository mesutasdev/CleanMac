import Foundation

enum DevProjectBuildHelper {
    static func staleBuildOutputs(home: URL) -> [URL] {
        guard let latest = latestProjectWithBuildOutput(home: home) else { return [] }
        return allProjectsWithBuildOutput(home: home)
            .filter { $0.path != latest.path }
            .flatMap { buildOutputs(in: $0) }
    }

    static func staleIosPodsFolders(home: URL) -> [URL] {
        guard let latest = latestProjectWithPods(home: home) else { return [] }
        return allProjectsWithPods(home: home)
            .filter { $0.path != latest.path }
            .compactMap { podsFolder(in: $0) }
    }

    static func totalSize(of urls: [URL]) -> Int64 {
        urls.reduce(0) { $0 + DerivedDataHelper.directorySize(at: $1) }
    }

    static func flutterEngineCacheURL(home: URL) -> URL? {
        if let root = ProcessInfo.processInfo.environment["FLUTTER_ROOT"] {
            let cache = URL(fileURLWithPath: root).appending(path: "bin/cache")
            return FileManager.default.fileExists(atPath: cache.path) ? cache : nil
        }

        for relative in ["Developer/flutter/bin/cache", "flutter/bin/cache", "development/flutter/bin/cache"] {
            let cache = home.appending(path: relative)
            if FileManager.default.fileExists(atPath: cache.path) {
                return cache
            }
        }

        return flutterCacheFromShell()
    }

    static func androidAvdSnapshotFolders(home: URL) -> [URL] {
        let avdRoot = home.appending(path: ".android/avd")
        guard let devices = try? FileManager.default.contentsOfDirectory(
            at: avdRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return devices.compactMap { device in
            let snapshots = device.appending(path: "snapshots")
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: snapshots.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  DerivedDataHelper.directorySize(at: snapshots) > 0
            else {
                return nil
            }
            return snapshots
        }
    }

    private static func allProjectsWithBuildOutput(home: URL) -> [URL] {
        var projects = FlutterBuildHelper.projectsWithArtifacts(home: home)
        projects.append(contentsOf: NodeProjectHelper.projectsWithArtifacts(home: home))
        projects.append(contentsOf: xcodeProjects(home: home))

        var seen = Set<String>()
        return projects.filter { seen.insert($0.standardizedFileURL.path).inserted }
            .filter { !buildOutputs(in: $0).isEmpty }
    }

    private static func latestProjectWithBuildOutput(home: URL) -> URL? {
        allProjectsWithBuildOutput(home: home).max { lhs, rhs in
            buildOutputs(in: lhs).map { modificationDate(of: $0) }.max() ?? .distantPast
                < buildOutputs(in: rhs).map { modificationDate(of: $0) }.max() ?? .distantPast
        }
    }

    private static func allProjectsWithPods(home: URL) -> [URL] {
        FlutterBuildHelper.flutterProjects(home: home).filter { podsFolder(in: $0) != nil }
    }

    private static func latestProjectWithPods(home: URL) -> URL? {
        allProjectsWithPods(home: home).max { lhs, rhs in
            modificationDate(of: podsFolder(in: lhs) ?? lhs) < modificationDate(of: podsFolder(in: rhs) ?? rhs)
        }
    }

    private static func xcodeProjects(home: URL) -> [URL] {
        var projects: [URL] = []
        var seen = Set<String>()

        for root in FlutterBuildHelper.projectSearchRoots(home: home) {
            discoverXcodeProjects(at: root, remainingDepth: 3, into: &projects, seen: &seen)
        }

        return projects
    }

    private static func discoverXcodeProjects(
        at directory: URL,
        remainingDepth: Int,
        into projects: inout [URL],
        seen: inout Set<String>
    ) {
        if isXcodeProject(directory) {
            let normalized = directory.standardizedFileURL.path
            if seen.insert(normalized).inserted {
                projects.append(directory)
            }
            return
        }

        guard remainingDepth > 0,
              let contents = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              )
        else {
            return
        }

        for url in contents where shouldScan(url) {
            discoverXcodeProjects(at: url, remainingDepth: remainingDepth - 1, into: &projects, seen: &seen)
        }
    }

    private static func isXcodeProject(_ url: URL) -> Bool {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return false
        }
        return contents.contains { $0.pathExtension == "xcodeproj" || $0.pathExtension == "xcworkspace" }
    }

    private static func buildOutputs(in projectURL: URL) -> [URL] {
        var outputs: [URL] = []
        let buildFolder = projectURL.appending(path: "build")
        var isDirectory = ObjCBool(false)
        if FileManager.default.fileExists(atPath: buildFolder.path, isDirectory: &isDirectory),
           isDirectory.boolValue,
           DerivedDataHelper.directorySize(at: buildFolder) > 0 {
            outputs.append(buildFolder)
        }

        if let archives = try? FileManager.default.contentsOfDirectory(
            at: buildFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            outputs.append(contentsOf: archives.filter { $0.pathExtension == "xcarchive" })
        }

        return outputs
    }

    private static func podsFolder(in projectURL: URL) -> URL? {
        for relative in ["ios/Pods", "Pods"] {
            let url = projectURL.appending(path: relative)
            var isDirectory = ObjCBool(false)
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
               isDirectory.boolValue,
               DerivedDataHelper.directorySize(at: url) > 0 {
                return url
            }
        }
        return nil
    }

    private static func shouldScan(_ directory: URL) -> Bool {
        let name = directory.lastPathComponent
        if ["node_modules", ".next", "build", "Pods", "DerivedData", ".git"].contains(name) { return false }
        if name.hasPrefix(".") { return false }

        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private static func modificationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    private static func flutterCacheFromShell() -> URL? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/bash")
        process.arguments = ["-lc", "command -v flutter"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let flutterBinary = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !flutterBinary.isEmpty
        else {
            return nil
        }

        let flutterRoot = URL(fileURLWithPath: flutterBinary)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let cache = flutterRoot.appending(path: "bin/cache")
        return FileManager.default.fileExists(atPath: cache.path) ? cache : nil
    }
}
