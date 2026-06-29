import Foundation

enum CleanTargetKind: String, CaseIterable, Identifiable, Sendable {
    case xcodeDerivedData
    case xcodeDerivedDataLastBuild
    case flutterStaleBuilds
    case flutterLastBuild
    case simulatorUnavailable
    case xcodeArchives
    case xcodeDeviceSupport
    case xcodeDeviceSupportLatest
    case simulatorData
    case xcodeCaches
    case cocoaPodsCache
    case flutterPubCache
    case gradleCache
    case npmCache
    case homebrewCache
    case swiftPMCache
    case userLogs
    case generalAppCaches
    case diagnosticReports
    case userTrash
    case iosBackups
    case httpStorageCache
    case timeMachineLocalSnapshots
    case nodeStaleModules
    case nodeStaleNextCache
    case flutterEngineCache
    case gradleWrapperDists
    case staleProjectBuilds
    case staleIosPods
    case androidAvdSnapshots

    var id: String { rawValue }

    static var displayOrder: [CleanTargetKind] {
        allCases.sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    var category: CleanTargetCategory {
        switch self {
        case .xcodeDerivedData, .flutterStaleBuilds, .simulatorUnavailable, .xcodeDeviceSupport,
             .userLogs, .generalAppCaches, .diagnosticReports, .staleProjectBuilds:
            return .reclaimable
        case .xcodeArchives, .simulatorData, .userTrash, .iosBackups, .httpStorageCache,
             .timeMachineLocalSnapshots, .staleIosPods, .androidAvdSnapshots:
            return .conditional
        case .xcodeDerivedDataLastBuild, .flutterLastBuild, .xcodeDeviceSupportLatest:
            return .destructive
        case .xcodeCaches, .cocoaPodsCache, .flutterPubCache, .gradleCache, .npmCache, .homebrewCache,
             .swiftPMCache, .nodeStaleModules, .nodeStaleNextCache, .flutterEngineCache, .gradleWrapperDists:
            return .regenerating
        }
    }

    var title: String { L("target.\(rawValue).title") }
    var subtitle: String { L("target.\(rawValue).subtitle") }
    var deletionImpact: String { L("target.\(rawValue).impact") }

    var impactBadge: ImpactBadge {
        switch category {
        case .reclaimable: return .recommended
        case .conditional: return .optional
        case .destructive: return .caution
        case .regenerating: return .regenerates
        }
    }

    enum ImpactBadge {
        case recommended, optional, caution, regenerates

        var label: String {
            switch self {
            case .recommended: return L("badge.recommended")
            case .optional: return L("badge.optional")
            case .caution: return L("badge.caution")
            case .regenerates: return L("badge.regenerates")
            }
        }
    }

    var icon: String {
        switch self {
        case .xcodeDerivedData, .xcodeDerivedDataLastBuild, .flutterStaleBuilds, .flutterLastBuild, .xcodeArchives, .xcodeCaches:
            return "hammer.fill"
        case .xcodeDeviceSupport, .xcodeDeviceSupportLatest:
            return "cable.connector"
        case .simulatorUnavailable, .simulatorData:
            return "iphone"
        case .cocoaPodsCache, .flutterPubCache, .gradleCache, .npmCache, .swiftPMCache:
            return "shippingbox.fill"
        case .homebrewCache:
            return "mug.fill"
        case .userLogs, .diagnosticReports:
            return "doc.text.fill"
        case .generalAppCaches, .httpStorageCache:
            return "externaldrive.fill"
        case .userTrash:
            return "trash.fill"
        case .iosBackups:
            return "iphone.and.arrow.forward"
        case .timeMachineLocalSnapshots:
            return "clock.arrow.circlepath"
        case .nodeStaleModules, .nodeStaleNextCache:
            return "chevron.left.forwardslash.chevron.right"
        case .flutterEngineCache:
            return "wind"
        case .gradleWrapperDists:
            return "shippingbox.fill"
        case .staleProjectBuilds:
            return "hammer.fill"
        case .staleIosPods:
            return "leaf.fill"
        case .androidAvdSnapshots:
            return "smartphone"
        }
    }

    var defaultSelected: Bool {
        category == .reclaimable
    }

    var usesShellCommand: Bool {
        self == .simulatorUnavailable || self == .timeMachineLocalSnapshots
    }

    func resolvePath(home: URL) -> URL? {
        switch self {
        case .xcodeDerivedData, .xcodeDerivedDataLastBuild:
            return home.appending(path: "Library/Developer/Xcode/DerivedData")
        case .flutterStaleBuilds, .flutterLastBuild:
            return FlutterBuildHelper.projectSearchRoots(home: home).first
                ?? home.appending(path: "Developer/projects")
        case .xcodeArchives:
            return home.appending(path: "Library/Developer/Xcode/Archives")
        case .xcodeDeviceSupport, .xcodeDeviceSupportLatest:
            return home.appending(path: "Library/Developer/Xcode/iOS DeviceSupport")
        case .xcodeCaches:
            return home.appending(path: "Library/Caches/com.apple.dt.Xcode")
        case .simulatorUnavailable:
            return nil
        case .simulatorData:
            return home.appending(path: "Library/Developer/CoreSimulator/Caches")
        case .cocoaPodsCache:
            return home.appending(path: "Library/Caches/CocoaPods")
        case .flutterPubCache:
            return home.appending(path: ".pub-cache")
        case .gradleCache:
            return home.appending(path: ".gradle/caches")
        case .npmCache:
            return home.appending(path: ".npm/_cacache")
        case .homebrewCache:
            return home.appending(path: "Library/Caches/Homebrew")
        case .swiftPMCache:
            return home.appending(path: "Library/Caches/org.swift.swiftpm")
        case .userLogs:
            return home.appending(path: "Library/Logs")
        case .userTrash:
            return home.appending(path: ".Trash")
        case .iosBackups:
            return home.appending(path: "Library/Application Support/MobileSync/Backup")
        case .httpStorageCache:
            return home.appending(path: "Library/HTTPStorages")
        case .generalAppCaches, .diagnosticReports, .timeMachineLocalSnapshots,
             .nodeStaleModules, .nodeStaleNextCache, .staleProjectBuilds, .staleIosPods, .androidAvdSnapshots:
            return nil
        case .flutterEngineCache:
            return DevProjectBuildHelper.flutterEngineCacheURL(home: home)
        case .gradleWrapperDists:
            return home.appending(path: ".gradle/wrapper/dists")
        }
    }
}
