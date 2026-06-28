import Foundation

enum FlutterBuildHelper {
    private static let artifactFolderNames = ["build", ".dart_tool"]

    static func projectsRootURL(home: URL) -> URL {
        home.appending(path: "Developer/projects")
    }

    static func flutterProjects(in rootURL: URL) -> [URL] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: rootURL.path),
              let contents = try? fm.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              )
        else {
            return []
        }

        return contents.filter { url in
            var isDirectory = ObjCBool(false)
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else {
                return false
            }
            return fm.fileExists(atPath: url.appending(path: "pubspec.yaml").path)
        }
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

    static func projectsWithArtifacts(in rootURL: URL) -> [URL] {
        flutterProjects(in: rootURL).filter { !artifactFolders(in: $0).isEmpty }
    }

    static func latestProject(in rootURL: URL) -> URL? {
        projectsWithArtifacts(in: rootURL).max { lhs, rhs in
            latestModificationDate(for: lhs) < latestModificationDate(for: rhs)
        }
    }

    static func staleProjects(in rootURL: URL) -> [URL] {
        let withArtifacts = projectsWithArtifacts(in: rootURL)
        guard let latest = latestProject(in: rootURL) else {
            return []
        }
        return withArtifacts.filter { $0.path != latest.path }
    }

    static func staleArtifactFolders(in rootURL: URL) -> [URL] {
        staleProjects(in: rootURL).flatMap { artifactFolders(in: $0) }
    }

    static func latestArtifactFolders(in rootURL: URL) -> [URL] {
        guard let latest = latestProject(in: rootURL) else { return [] }
        return artifactFolders(in: latest)
    }

    static func totalSize(of urls: [URL]) -> Int64 {
        urls.reduce(0) { $0 + DerivedDataHelper.directorySize(at: $1) }
    }

    static func displayName(for projectURL: URL) -> String {
        projectURL.lastPathComponent
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
