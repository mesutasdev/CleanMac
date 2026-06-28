import Foundation

enum DerivedDataHelper {
    private static let systemFolderSuffix = ".noindex"

    static func derivedDataURL(home: URL) -> URL {
        home.appending(path: "Library/Developer/Xcode/DerivedData")
    }

    static func projectFolders(in derivedDataURL: URL) -> [URL] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: derivedDataURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey]
        ) else {
            return []
        }

        return contents.filter { url in
            guard !url.lastPathComponent.hasSuffix(systemFolderSuffix) else { return false }
            var isDirectory = ObjCBool(false)
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                return false
            }
            return true
        }
    }

    static func systemCacheFolders(in derivedDataURL: URL) -> [URL] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: derivedDataURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return []
        }

        return contents.filter { url in
            guard url.lastPathComponent.hasSuffix(systemFolderSuffix) else { return false }
            var isDirectory = ObjCBool(false)
            return fm.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }

    static func latestProjectFolder(in derivedDataURL: URL) -> URL? {
        projectFolders(in: derivedDataURL).max { lhs, rhs in
            modificationDate(of: lhs) < modificationDate(of: rhs)
        }
    }

    static func staleProjectFolders(in derivedDataURL: URL) -> [URL] {
        guard let latest = latestProjectFolder(in: derivedDataURL) else {
            return projectFolders(in: derivedDataURL)
        }
        return projectFolders(in: derivedDataURL).filter { $0.path != latest.path }
    }

    static func directorySize(at url: URL) -> Int64 {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        process.arguments = ["-sk", url.path]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return 0
        }

        guard process.terminationStatus == 0 else { return 0 }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\t")
            .first,
            let kilobytes = Int64(output)
        else {
            return 0
        }

        return kilobytes * 1024
    }

    static func totalSize(of urls: [URL]) -> Int64 {
        urls.reduce(0) { $0 + directorySize(at: $1) }
    }

    static func displayName(for folder: URL) -> String {
        let name = folder.lastPathComponent
        if let dashIndex = name.firstIndex(of: "-") {
            return String(name[..<dashIndex])
        }
        return name
    }

    private static func modificationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }
}
