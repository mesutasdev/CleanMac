import SwiftUI

struct AppearanceToggleView: View {
    @ObservedObject var appearanceManager: AppearanceManager

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppAppearance.allCases) { appearance in
                Button {
                    appearanceManager.selectedAppearance = appearance
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: appearance.icon)
                            .font(.caption.weight(.semibold))
                        Text(L(appearance.titleKey))
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        appearanceManager.selectedAppearance == appearance
                            ? AnyShapeStyle(Color.accentColor.opacity(0.18))
                            : AnyShapeStyle(Color.clear),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                appearanceManager.selectedAppearance == appearance ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.25),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .help(L("appearance.switch_help", L(appearance.titleKey)))
            }
        }
        .accessibilityLabel(L("appearance.accessibility"))
    }
}
