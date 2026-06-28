import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .turkish: return "🇹🇷"
        }
    }

    var titleKey: String {
        switch self {
        case .english: return "language.english"
        case .turkish: return "language.turkish"
        }
    }

    static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("tr") ? .turkish : .english
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published private(set) var refreshToken = UUID()
    @Published var selectedLanguage: AppLanguage {
        didSet {
            guard oldValue != selectedLanguage else { return }
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: storageKey)
            applyLanguage(selectedLanguage)
            refreshToken = UUID()
        }
    }

    private let storageKey = "appLanguage"

    init() {
        if let stored = UserDefaults.standard.string(forKey: storageKey),
           let language = AppLanguage(rawValue: stored) {
            selectedLanguage = language
        } else {
            selectedLanguage = AppLanguage.systemDefault
        }
        applyLanguage(selectedLanguage)
    }

    func toggleLanguage() {
        selectedLanguage = selectedLanguage == .english ? .turkish : .english
    }

    private func applyLanguage(_ language: AppLanguage) {
        BundleLocalization.setLanguage(language.rawValue)
    }
}
