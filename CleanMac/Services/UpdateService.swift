import AppKit
import Foundation

enum UpdateError: LocalizedError {
    case invalidResponse
    case missingVersion
    case missingDownload
    case downloadFailed
    case mountFailed
    case missingInstaller

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return L("update.error.invalid_response")
        case .missingVersion:
            return L("update.error.missing_version")
        case .missingDownload:
            return L("update.error.missing_download")
        case .downloadFailed:
            return L("update.error.download_failed")
        case .mountFailed:
            return L("update.error.mount_failed")
        case .missingInstaller:
            return L("update.error.missing_installer")
        }
    }
}

struct AvailableUpdate: Identifiable, Sendable {
    let id: String
    let version: AppVersion
    let downloadURL: URL
    let releaseNotes: String?

    var versionLabel: String { version.displayString }
}

actor UpdateService {
    static let shared = UpdateService()

    private let repo = "mesutasdev/CleanMac"
    private let installerBundleID = "com.cleanmac.app.installer"
    private let installerAppNames = ["Install CleanMac.app", "CleanMac'i Kur.app"]
    private let appName = "CleanMac.app"

    func fetchLatestUpdate() async throws -> AvailableUpdate? {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("CleanMac/\(AppVersion.current?.displayString ?? "1.0")", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw UpdateError.invalidResponse
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard let version = AppVersion(release.tagName) else {
            throw UpdateError.missingVersion
        }

        guard let asset = release.assets.first(where: {
            $0.name.hasSuffix(".dmg") && $0.name.hasPrefix("CleanMac-")
        }), let downloadURL = URL(string: asset.browserDownloadURL) else {
            throw UpdateError.missingDownload
        }

        return AvailableUpdate(
            id: version.displayString,
            version: version,
            downloadURL: downloadURL,
            releaseNotes: release.body
        )
    }

    func downloadAndInstall(
        from downloadURL: URL,
        progress: @escaping @Sendable (String) -> Void
    ) async throws {
        progress(L("update.downloading"))

        let downloadDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CleanMac-Update", isDirectory: true)
        try FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true)

        let destination = downloadDirectory.appendingPathComponent(downloadURL.lastPathComponent)
        try? FileManager.default.removeItem(at: destination)

        let (temporaryFile, response) = try await URLSession.shared.download(from: downloadURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw UpdateError.downloadFailed
        }

        try FileManager.default.moveItem(at: temporaryFile, to: destination)

        progress(L("update.preparing"))
        let mountPoint = try mountImage(at: destination)

        guard let installerURL = await findInstallerApp(in: mountPoint) else {
            throw UpdateError.missingInstaller
        }

        progress(L("update.installing"))
        let opened = await MainActor.run {
            NSWorkspace.shared.open(installerURL)
        }
        guard opened else {
            throw UpdateError.missingInstaller
        }

        try await Task.sleep(nanoseconds: 600_000_000)
        await MainActor.run {
            NSApplication.shared.terminate(nil)
        }
    }

    private func findInstallerApp(in mountPoint: URL) async -> URL? {
        for attempt in 0..<6 {
            if let installerURL = locateInstallerApp(in: mountPoint) {
                return installerURL
            }

            guard attempt < 5 else { break }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        return nil
    }

    private func locateInstallerApp(in mountPoint: URL) -> URL? {
        let fileManager = FileManager.default

        for name in installerAppNames {
            let url = mountPoint.appendingPathComponent(name, isDirectory: true)
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: mountPoint,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for url in contents where url.pathExtension == "app" {
            guard url.lastPathComponent != appName else { continue }

            if installerAppNames.contains(url.lastPathComponent) {
                return url
            }

            if Bundle(url: url)?.bundleIdentifier == installerBundleID {
                return url
            }
        }

        return nil
    }

    private func mountImage(at url: URL) throws -> URL {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["attach", "-nobrowse", "-plist", url.path]

        let output = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = output
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let data = output.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            throw UpdateError.mountFailed
        }

        guard
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let entities = plist["system-entities"] as? [[String: Any]]
        else {
            throw UpdateError.mountFailed
        }

        let mountPoints = entities.compactMap { $0["mount-point"] as? String }.filter { !$0.isEmpty }
        guard let mountPoint = mountPoints.last(where: { $0.hasPrefix("/Volumes/") }) ?? mountPoints.last else {
            throw UpdateError.mountFailed
        }

        return URL(fileURLWithPath: mountPoint, isDirectory: true)
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let body: String?
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case assets
    }
}

private struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}
