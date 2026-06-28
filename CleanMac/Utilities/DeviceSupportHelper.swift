import Foundation

enum DeviceSupportHelper {
    struct Folder: Sendable {
        let url: URL
        let version: IOSVersion
        let displayName: String
    }

    struct IOSVersion: Sendable, Comparable {
        let major: Int
        let minor: Int
        let patch: Int

        var displayString: String {
            if patch == 0 {
                return "\(major).\(minor)"
            }
            return "\(major).\(minor).\(patch)"
        }

        static func < (lhs: IOSVersion, rhs: IOSVersion) -> Bool {
            if lhs.major != rhs.major { return lhs.major < rhs.major }
            if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
            return lhs.patch < rhs.patch
        }
    }

    static func deviceSupportURL(home: URL) -> URL {
        home.appending(path: "Library/Developer/Xcode/iOS DeviceSupport")
    }

    static func allFolders(in deviceSupportURL: URL) -> [Folder] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: deviceSupportURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return []
        }

        return contents.compactMap { url -> Folder? in
            var isDirectory = ObjCBool(false)
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                return nil
            }
            guard let version = parseIOSVersion(from: url.lastPathComponent) else {
                return nil
            }
            return Folder(url: url, version: version, displayName: url.lastPathComponent)
        }
    }

    static func latestIOSVersion(in deviceSupportURL: URL) -> IOSVersion? {
        allFolders(in: deviceSupportURL).map(\.version).max()
    }

    static func staleFolders(in deviceSupportURL: URL) -> [URL] {
        guard let latest = latestIOSVersion(in: deviceSupportURL) else {
            return []
        }
        return allFolders(in: deviceSupportURL)
            .filter { $0.version < latest }
            .map(\.url)
    }

    static func latestFolders(in deviceSupportURL: URL) -> [URL] {
        guard let latest = latestIOSVersion(in: deviceSupportURL) else {
            return []
        }
        return allFolders(in: deviceSupportURL)
            .filter { $0.version == latest }
            .map(\.url)
    }

    static func totalSize(of urls: [URL]) -> Int64 {
        urls.reduce(0) { $0 + DerivedDataHelper.directorySize(at: $1) }
    }

    static func preservedVersionLabel(in deviceSupportURL: URL) -> String? {
        latestIOSVersion(in: deviceSupportURL)?.displayString
    }

    /// "iPhone16,1 26.5 (23F77)" veya "16.4 (20E247)" gibi klasör adlarından iOS sürümünü çıkarır.
    static func parseIOSVersion(from folderName: String) -> IOSVersion? {
        let pattern = #"(\d+)\.(\d+)(?:\.(\d+))?\s*\("#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: folderName, range: NSRange(folderName.startIndex..., in: folderName)),
              match.numberOfRanges >= 3,
              let majorRange = Range(match.range(at: 1), in: folderName),
              let minorRange = Range(match.range(at: 2), in: folderName),
              let major = Int(folderName[majorRange]),
              let minor = Int(folderName[minorRange])
        else {
            return nil
        }

        var patch = 0
        if match.numberOfRanges >= 4,
           match.range(at: 3).location != NSNotFound,
           let patchRange = Range(match.range(at: 3), in: folderName) {
            patch = Int(folderName[patchRange]) ?? 0
        }

        return IOSVersion(major: major, minor: minor, patch: patch)
    }
}
