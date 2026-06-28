import Foundation

enum BundleLocalization {
    private static var bundle: Bundle = .main

    static func setLanguage(_ code: String) {
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let localized = Bundle(path: path)
        else {
            bundle = .main
            return
        }
        bundle = localized
    }

    static func localized(_ key: String) -> String {
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        if value != key { return value }

        if bundle !== Bundle.main,
           let fallback = Bundle.main.localizedString(forKey: key, value: nil, table: nil) as String?,
           fallback != key {
            return fallback
        }

        return key
    }

    static func localized(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localized(key), arguments: arguments)
    }
}

func L(_ key: String) -> String {
    BundleLocalization.localized(key)
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    let format = BundleLocalization.localized(key)
    guard !arguments.isEmpty else { return format }
    return withVaList(Array(arguments)) { pointer in
        NSString(format: format, locale: Locale.current, arguments: pointer) as String
    }
}
