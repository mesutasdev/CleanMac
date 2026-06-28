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

    var id: String { rawValue }

    /// Mantıklı temizlik sırası: önerilen → isteğe bağlı → aktif proje → geri gelenler.
    static var displayOrder: [CleanTargetKind] {
        allCases.sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    var category: CleanTargetCategory {
        switch self {
        case .xcodeDerivedData, .flutterStaleBuilds, .simulatorUnavailable, .xcodeDeviceSupport:
            return .reclaimable
        case .xcodeArchives, .simulatorData:
            return .conditional
        case .xcodeDerivedDataLastBuild, .flutterLastBuild, .xcodeDeviceSupportLatest:
            return .destructive
        case .xcodeCaches, .cocoaPodsCache, .flutterPubCache, .gradleCache, .npmCache, .homebrewCache, .swiftPMCache:
            return .regenerating
        }
    }

    var title: String {
        switch self {
        case .xcodeDerivedData: return "Eski DerivedData"
        case .xcodeDerivedDataLastBuild: return "Son Build (DerivedData)"
        case .flutterStaleBuilds: return "Eski Flutter Build"
        case .flutterLastBuild: return "Son Build (Flutter)"
        case .xcodeArchives: return "Xcode Arşivleri"
        case .xcodeDeviceSupport: return "Eski iOS Device Support"
        case .xcodeDeviceSupportLatest: return "Güncel iOS Device Support"
        case .xcodeCaches: return "Xcode Önbelleği"
        case .simulatorUnavailable: return "Kullanılmayan Simülatörler"
        case .simulatorData: return "Simülatör Verileri"
        case .cocoaPodsCache: return "CocoaPods Önbelleği"
        case .flutterPubCache: return "Flutter Pub Cache"
        case .gradleCache: return "Gradle Önbelleği"
        case .npmCache: return "npm Önbelleği"
        case .homebrewCache: return "Homebrew Önbelleği"
        case .swiftPMCache: return "Swift Package Manager"
        }
    }

    var subtitle: String {
        switch self {
        case .xcodeDerivedData:
            return "Artık derlemediğin projelerin build çıktıları"
        case .xcodeDerivedDataLastBuild:
            return "En son derlediğin projenin DerivedData klasörü"
        case .flutterStaleBuilds:
            return "~/Developer/projects altındaki eski Flutter build ve .dart_tool klasörleri"
        case .flutterLastBuild:
            return "En son derlediğin Flutter projesinin build ve .dart_tool klasörleri"
        case .xcodeArchives:
            return "App Store ve TestFlight .xcarchive dosyaları"
        case .xcodeDeviceSupport:
            return "Gerçek iPhone/iPad için eski iOS sürüm sembolleri — simülatör değil"
        case .xcodeDeviceSupportLatest:
            return "Diskteki en yüksek iOS sürüm sembolleri — simülatör değil"
        case .xcodeCaches:
            return "Xcode geçici dosyaları — kısa sürede yeniden oluşur"
        case .simulatorUnavailable:
            return "Güncelleme sonrası kullanılamayan simülatör cihaz kayıtları"
        case .simulatorData:
            return "Simülatör cache ve log dosyaları"
        case .cocoaPodsCache:
            return "Pod paketleri — pod install ile geri gelir"
        case .flutterPubCache:
            return "Dart paketleri — flutter pub get ile geri gelir"
        case .gradleCache:
            return "Android bağımlılıkları — build ile geri gelir"
        case .npmCache:
            return "~/.npm/_cacache indirme önbelleği — npm install ile geri gelir"
        case .homebrewCache:
            return "Homebrew indirme arşivi — brew ile geri gelir"
        case .swiftPMCache:
            return "Swift paket derlemesi — Xcode build ile geri gelir"
        }
    }

    var deletionImpact: String {
        switch self {
        case .xcodeDerivedData:
            return "Kalıcı yer açar. Son build korunur; eski projeyi tekrar açana kadar disk boş kalır."
        case .xcodeDerivedDataLastBuild:
            return "Aktif projen sıfırdan derlenir. Koduna dokunulmaz; bir sonraki build uzun sürer."
        case .flutterStaleBuilds:
            return "Kalıcı yer açar. Son build edilen Flutter projesi korunur; o projeyi tekrar derleyene kadar disk boş kalır."
        case .flutterLastBuild:
            return "Aktif Flutter projen sıfırdan derlenir. Koduna dokunulmaz; bir sonraki build uzun sürer."
        case .xcodeArchives:
            return "Kalıcı yer açar. Yayındaki uygulama etkilenmez; aynı build'i tekrar yüklemek için yeniden Archive gerekir."
        case .xcodeDeviceSupport:
            return "Simülatör etkilenmez, internetten simülatör indirmezsin. Eski iOS sürümleri kalıcı silinir; o sürümdeki cihazı USB ile bağlarsan semboller cihazdan yeniden kopyalanır."
        case .xcodeDeviceSupportLatest:
            return "Diskteki en yüksek iOS sembolleri silinir. Cihazı USB ile bağladığında Xcode yeniden kopyalar."
        case .xcodeCaches:
            return "Geçici boşluk — Xcode açılınca dosyalar yeniden oluşur. Bozuk cache şüphesi dışında silmeye değmez."
        case .simulatorUnavailable:
            return "Kalıcı yer açar. Kullandığın simülatörlere dokunmaz; geri gelmez."
        case .simulatorData:
            return "Kısmen kalıcı. Simülatör uygulama verileri gidebilir; cache kısa sürede yeniden oluşabilir."
        case .cocoaPodsCache:
            return "Geçici boşluk — bir sonraki pod install/build ile disk tekrar dolar. Rutin temizlik için uygun değil."
        case .flutterPubCache:
            return "Geçici boşluk — flutter pub get ile paketler geri iner. Rutin temizlik için uygun değil."
        case .gradleCache:
            return "Geçici boşluk — bir sonraki Android/Flutter build ile Gradle yeniden indirir. Rutin temizlik için uygun değil."
        case .npmCache:
            return "Geçici boşluk — npm install ile paketler geri gelir. Rutin temizlik için uygun değil."
        case .homebrewCache:
            return "Geçici boşluk — brew install/upgrade sırasında arşivler yeniden iner. Rutin temizlik için uygun değil."
        case .swiftPMCache:
            return "Geçici boşluk — bir sonraki Xcode build ile paketler yeniden derlenir. Rutin temizlik için uygun değil."
        }
    }

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
            case .recommended: return "Önerilen"
            case .optional: return "İsteğe bağlı"
            case .caution: return "Dikkat"
            case .regenerates: return "Geri gelir"
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
        }
    }

    var defaultSelected: Bool {
        category == .reclaimable
    }

    var usesShellCommand: Bool {
        self == .simulatorUnavailable
    }

    func resolvePath(home: URL) -> URL? {
        switch self {
        case .xcodeDerivedData, .xcodeDerivedDataLastBuild:
            return home.appending(path: "Library/Developer/Xcode/DerivedData")
        case .flutterStaleBuilds, .flutterLastBuild:
            return home.appending(path: "Developer/projects")
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
        }
    }
}
