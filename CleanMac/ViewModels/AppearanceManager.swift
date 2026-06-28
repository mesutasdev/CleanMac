import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.fill"
        }
    }

    var titleKey: String {
        switch self {
        case .system: return "appearance.system"
        case .light: return "appearance.light"
        case .dark: return "appearance.dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    @Published private(set) var refreshToken = UUID()
    @Published var selectedAppearance: AppAppearance {
        didSet {
            guard oldValue != selectedAppearance else { return }
            UserDefaults.standard.set(selectedAppearance.rawValue, forKey: storageKey)
            refreshToken = UUID()
        }
    }

    private let storageKey = "appAppearance"

    var preferredColorScheme: ColorScheme? {
        selectedAppearance.preferredColorScheme
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: storageKey),
           let appearance = AppAppearance(rawValue: stored) {
            selectedAppearance = appearance
        } else {
            selectedAppearance = .system
        }
    }
}
