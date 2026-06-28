import Foundation

enum PathDisplayHelper {
    static func displayPath(_ url: URL, home: URL) -> String {
        let homePath = home.path
        let path = url.path
        if path.hasPrefix(homePath + "/") {
            return "~/" + path.dropFirst(homePath.count + 1)
        }
        if path == homePath {
            return "~"
        }
        return path
    }

    static func displayPaths(_ urls: [URL], home: URL) -> [String] {
        urls.map { displayPath($0, home: home) }
    }
}
