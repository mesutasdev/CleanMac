import Foundation

enum FlutterBuildHelper {
    private static let artifactFolderNames = ["build", ".dart_tool"]

    private static let preferredRootPaths = [
        "Developer/projects",
        "Developer",
        "projects",
        "Projects",
        "dev",
        "code",
        "src",
        "workspace",
        "Documents/projects",
    ]

    private static let skipDirectoryNames: Set<String> = [
        ".git", ".svn", "node_modules", "Pods", "DerivedData", "build", ".dart_tool",
        ".idea", ".vscode", "Library", "Applications", "Downloads", "Movies", "Music",
        "Pictures", "Public", ".Trash", "vendor", "target", ".gradle", "Carthage",
        ".pub-cache", ".npm", ".cache", "Caches", "Logs", "tmp", "temp",
    ]

    static func projectSearchRoots(home: URL) -> [URL] {
        var roots: [URL] = []
        var seen = Set<String>()

        for relativePath in preferredRootPaths {
            let url = home.appending(path: relativePath)
            let normalized = url.standardizedFileURL.path
            guard seen.insert(normalized).inserted else { continue }

            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else {
                continue
            }

            roots.append(url)
        }

        for customPath in customSearchPaths(home: home) {
            let normalized = customPath.standardizedFileURL.path
            guard seen.insert(normalized).inserted else { continue }

            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: customPath.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else {
                continue
            }

            roots.append(customPath)
        }

        return roots
    }

    static func flutterProjects(home: URL) -> [URL] {
        var projects: [URL] = []
        var seen = Set<String>()

        for root in projectSearchRoots(home: home) {
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
        flutterProjects(home: home).filter { !artifactFolders(in: $0).isEmpty }
    }

    static func latestProject(home: URL) -> URL? {
        projectsWithArtifacts(home: home).max { lhs, rhs in
            latestModificationDate(for: lhs) < latestModificationDate(for: rhs)
        }
    }

    static func staleProjects(home: URL) -> [URL] {
        let withArtifacts = projectsWithArtifacts(home: home)
        guard let latest = latestProject(home: home) else {
            return []
        }
        return withArtifacts.filter { $0.path != latest.path }
    }

    static func staleArtifactFolders(home: URL) -> [URL] {
        staleProjects(home: home).flatMap { artifactFolders(in: $0) }
    }

    static func latestArtifactFolders(home: URL) -> [URL] {
        guard let latest = latestProject(home: home) else { return [] }
        return artifactFolders(in: latest)
    }

    static func searchRootsSummary(home: URL) -> String {
        let roots = projectSearchRoots(home: home)
        guard !roots.isEmpty else { return L("flutter.no_folder") }

        let labels = roots.map { PathDisplayHelper.displayPath($0, home: home) }
        if labels.count <= 2 {
            return labels.joined(separator: ", ")
        }
        return L("flutter.roots_more", labels.prefix(2).joined(separator: ", "), labels.count - 2)
    }

    static func totalSize(of urls: [URL]) -> Int64 {
        urls.reduce(0) { $0 + DerivedDataHelper.directorySize(at: $1) }
    }

    static func displayName(for projectURL: URL) -> String {
        projectURL.lastPathComponent
    }

    static func artifactFolders(in projectURL: URL) -> [URL] {
        artifactFolderNames.compactMap { folderName in
            let url = projectURL.appending(path: folderName)
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else {
                return nil
            }
            return url
        }
    }

    private static let customSearchPathsKey = "flutterCustomSearchPaths"

    static func customSearchPaths(home: URL) -> [URL] {
        let stored = UserDefaults.standard.stringArray(forKey: customSearchPathsKey) ?? []
        return stored.compactMap { path in
            let expanded = (path as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded, isDirectory: true)
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
        if isFlutterProject(directory) {
            let normalized = directory.standardizedFileURL.path
            if seen.insert(normalized).inserted {
                projects.append(directory)
            }
            return
        }

        guard remainingDepth > 0 else { return }

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
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
        if skipDirectoryNames.contains(name) { return false }
        if name.hasPrefix(".") && name != ".private" { return false }

        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            return false
        }

        return true
    }

    private static func isFlutterProject(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.appending(path: "pubspec.yaml").path)
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
