import Foundation

enum NodeProjectHelper {
    private static let artifactFolderNames = ["node_modules", ".next"]

    static func nodeProjects(home: URL) -> [URL] {
        var projects: [URL] = []
        var seen = Set<String>()

        for root in FlutterBuildHelper.projectSearchRoots(home: home) {
            discoverProjects(
                at: root,
                remainingDepth: maxDepth(for: root, home: home),
                into: &projects,
                seen: &seen
            )
        }

        return projects.sorted {
            $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending
        }
    }

    static func projectsWithArtifacts(home: URL) -> [URL] {
        nodeProjects(home: home).filter { !artifactFolders(in: $0).isEmpty }
    }

    static func latestProject(home: URL) -> URL? {
        projectsWithArtifacts(home: home).max { lhs, rhs in
            latestModificationDate(for: lhs) < latestModificationDate(for: rhs)
        }
    }

    static func staleArtifactFolders(home: URL, matching names: [String]) -> [URL] {
        guard let latest = latestProject(home: home) else { return [] }
        return nodeProjects(home: home)
            .filter { $0.path != latest.path }
            .flatMap { project in
                names.compactMap { name in
                    let url = project.appending(path: name)
                    var isDirectory = ObjCBool(false)
                    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                          isDirectory.boolValue
                    else { return nil }
                    return url
                }
            }
    }

    static func staleNodeModuleFolders(home: URL) -> [URL] {
        staleArtifactFolders(home: home, matching: ["node_modules"])
    }

    static func staleNextCacheFolders(home: URL) -> [URL] {
        staleArtifactFolders(home: home, matching: [".next"])
    }

    static func totalSize(of urls: [URL]) -> Int64 {
        urls.reduce(0) { $0 + DerivedDataHelper.directorySize(at: $1) }
    }

    static func displayName(for projectURL: URL) -> String {
        projectURL.lastPathComponent
    }

    static func searchRootsSummary(home: URL) -> String {
        FlutterBuildHelper.searchRootsSummary(home: home)
    }

    private static func artifactFolders(in projectURL: URL) -> [URL] {
        artifactFolderNames.compactMap { folderName in
            let url = projectURL.appending(path: folderName)
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else { return nil }
            return url
        }
    }

    private static func maxDepth(for root: URL, home: URL) -> Int {
        let developerRoot = home.appending(path: "Developer").standardizedFileURL.path
        if root.standardizedFileURL.path == developerRoot {
            return 3
        }
        return 2
    }

    private static func discoverProjects(
        at directory: URL,
        remainingDepth: Int,
        into projects: inout [URL],
        seen: inout Set<String>
    ) {
        if isNodeProject(directory) {
            let normalized = directory.standardizedFileURL.path
            if seen.insert(normalized).inserted {
                projects.append(directory)
            }
            return
        }

        guard remainingDepth > 0 else { return }

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for url in contents {
            guard shouldScan(directory: url) else { continue }
            discoverProjects(at: url, remainingDepth: remainingDepth - 1, into: &projects, seen: &seen)
        }
    }

    private static func shouldScan(directory: URL) -> Bool {
        let name = directory.lastPathComponent
        if name == "node_modules" || name == ".next" || name == "build" || name == "Pods" { return false }
        if name.hasPrefix(".") && name != ".private" { return false }

        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            return false
        }

        return true
    }

    private static func isNodeProject(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.appending(path: "package.json").path)
    }

    private static func latestModificationDate(for projectURL: URL) -> Date {
        artifactFolders(in: projectURL)
            .map { modificationDate(of: $0) }
            .max() ?? .distantPast
    }

    private static func modificationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }
}
