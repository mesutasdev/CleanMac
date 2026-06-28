import Foundation

enum CleanTargetCategory: Int, CaseIterable, Hashable, Sendable {
    /// Silinince kalıcı yer açar; bir sonraki build'de otomatik geri gelmez.
    case reclaimable
    /// Gerçek yer açar ama o dosyaya ihtiyacın olabilir.
    case conditional
    /// Bilinçli müdahale — aktif projenin build'i.
    case destructive
    /// Bir sonraki build/install ile disk yeniden dolar; rutin temizlik için uygun değil.
    case regenerating

    var sectionTitle: String {
        switch self {
        case .reclaimable: return "Önerilen — kalıcı yer açar"
        case .conditional: return "İsteğe bağlı — geri gelmez ama lazım olabilir"
        case .destructive: return "Aktif proje"
        case .regenerating: return "Genelde silme — bir sonraki build'de geri gelir"
        }
    }

    var sectionFooter: String {
        switch self {
        case .reclaimable:
            return "Eski build ve kullanılmayan dosyalar. Silince disk gerçekten boşalır; sadece o projeyi tekrar derlersen dolmaya başlar."
        case .conditional:
            return "Arşiv veya eski cihaz sembolleri. Yeniden yükleme veya debug için tekrar oluşturman gerekebilir."
        case .destructive:
            return "Yalnızca kasıtlı sıfırlama için. Son build ve güncel cihaz sembolleri varsayılan olarak korunur."
        case .regenerating:
            return "Gradle, npm, pub cache gibi önbellekler. Silmek diski geçici boşaltır; bir sonraki build'de aynı dosyalar yeniden iner."
        }
    }

    var sortOrder: Int { rawValue }

    var sidebarTitle: String {
        switch self {
        case .reclaimable: return "Önerilen"
        case .conditional: return "İsteğe Bağlı"
        case .destructive: return "Aktif Proje"
        case .regenerating: return "Gelişmiş"
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
