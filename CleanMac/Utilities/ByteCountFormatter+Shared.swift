import Foundation

extension ByteCountFormatter {
    static let cleanMac: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static func string(from bytes: Int64) -> String {
        cleanMac.string(fromByteCount: bytes)
    }
}
