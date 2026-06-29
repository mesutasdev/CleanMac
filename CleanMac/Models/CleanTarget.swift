import Foundation

struct CleanTarget: Identifiable, Sendable, Equatable {
    let kind: CleanTargetKind
    var sizeBytes: Int64
    var exists: Bool
    var detail: String?
    var locationPaths: [String] = []

    var id: String { kind.id }

    var title: String { kind.title }
    var description: String { kind.subtitle }
    var deletionImpact: String { kind.deletionImpact }
    var impactBadge: CleanTargetKind.ImpactBadge { kind.impactBadge }
    var category: CleanTargetCategory { kind.category }
    var statusNote: String? { detail }
    var locationNote: String?
    var icon: String { kind.icon }

    static func makeDefaults() -> [CleanTarget] {
        CleanTargetKind.allCases.map { kind in
            CleanTarget(
                kind: kind,
                sizeBytes: 0,
                exists: false,
                detail: nil
            )
        }
    }
}
