import SwiftUI

struct LanguageToggleView: View {
    @ObservedObject var languageManager: LanguageManager

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    languageManager.selectedLanguage = language
                } label: {
                    HStack(spacing: 4) {
                        Text(language.flag)
                        Text(L(language.titleKey))
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(
                        languageManager.selectedLanguage == language
                            ? AnyShapeStyle(Color.accentColor.opacity(0.18))
                            : AnyShapeStyle(Color.clear),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                languageManager.selectedLanguage == language ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.25),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .help(L("language.switch_help", L(language.titleKey)))
            }
        }
        .accessibilityLabel(L("language.accessibility"))
    }
}
