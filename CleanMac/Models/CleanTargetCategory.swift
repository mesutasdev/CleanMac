import Foundation

enum CleanTargetCategory: Int, CaseIterable, Hashable, Sendable {
    case reclaimable
    case conditional
    case destructive
    case regenerating

    var sectionTitle: String {
        switch self {
        case .reclaimable: return L("category.reclaimable.title")
        case .conditional: return L("category.conditional.title")
        case .destructive: return L("category.destructive.title")
        case .regenerating: return L("category.regenerating.title")
        }
    }

    var sectionFooter: String {
        switch self {
        case .reclaimable: return L("category.reclaimable.footer")
        case .conditional: return L("category.conditional.footer")
        case .destructive: return L("category.destructive.footer")
        case .regenerating: return L("category.regenerating.footer")
        }
    }

    var sortOrder: Int { rawValue }

    var sidebarTitle: String {
        switch self {
        case .reclaimable: return L("category.reclaimable.sidebar")
        case .conditional: return L("category.conditional.sidebar")
        case .destructive: return L("category.destructive.sidebar")
        case .regenerating: return L("category.regenerating.sidebar")
        }
    }

    var systemImage: String {
        switch self {
        case .reclaimable: return "checkmark.seal.fill"
        case .conditional: return "doc.on.doc"
        case .destructive: return "exclamationmark.triangle.fill"
        case .regenerating: return "arrow.triangle.2.circlepath"
        }
    }
}
