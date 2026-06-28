import SwiftUI

struct TargetRowView: View {
    let target: CleanTarget
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Toggle(isOn: Binding(
                    get: { target.isSelected },
                    set: { _ in onToggle() }
                )) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .disabled(target.sizeBytes == 0)
                .padding(.top, 4)

                Image(systemName: target.icon)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(iconTint.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(target.title)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        Text(sizeLabel)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(target.sizeBytes > 0 ? .primary : .tertiary)
                            .layoutPriority(1)
                    }

                    Text(target.impactBadge.label)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(badgeColor)

                    Text(target.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let note = target.statusNote {
                        Label {
                            Text(note)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "shield.checkered")
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }

                    if target.sizeBytes > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Silersen ne olur?")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(target.deletionImpact)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 2)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .opacity(target.sizeBytes > 0 ? 1 : 0.5)
        .padding(.vertical, 6)
        .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 12))
    }

    private var iconTint: Color {
        switch target.category {
        case .reclaimable: return .green
        case .conditional: return .blue
        case .destructive: return .orange
        case .regenerating: return .gray
        }
    }

    private var badgeColor: Color {
        switch target.impactBadge {
        case .recommended: return .green
        case .optional: return .blue
        case .caution: return .orange
        case .regenerates: return .secondary
        }
    }

    private var sizeLabel: String {
        if target.sizeBytes > 0 {
            return ByteCountFormatter.string(from: target.sizeBytes)
        }
        return "—"
    }
}
