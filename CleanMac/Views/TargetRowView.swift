import AppKit
import SwiftUI

struct TargetRowView: View {
    let target: CleanTarget
    let isSelected: Bool
    let isInteractionLocked: Bool
    let onSelectionChange: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Toggle(
                    isOn: Binding(
                        get: { isSelected },
                        set: { onSelectionChange($0) }
                    )
                ) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .disabled(target.sizeBytes == 0 || isInteractionLocked)
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

                    if !target.locationPaths.isEmpty {
                        LocationPathsView(paths: target.locationPaths, note: target.locationNote)
                    }

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
                            Text(L("target.deletion_impact_title"))
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
        .id(target.id)
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
        if target.kind == .simulatorUnavailable, let note = target.statusNote {
            return note
        }
        return "—"
    }
}

private struct LocationPathsView: View {
    let paths: [String]
    let note: String?

    private let displayLimit = 5

    private var visiblePaths: [String] {
        Array(paths.prefix(displayLimit))
    }

    private var hiddenCount: Int {
        max(0, paths.count - displayLimit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("target.location"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(visiblePaths, id: \.self) { path in
                HStack(alignment: .top, spacing: 6) {
                    Text(path)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)

                    if path.hasPrefix("~/") || path.hasPrefix("/") {
                        Button {
                            revealInFinder(path)
                        } label: {
                            Image(systemName: "folder")
                                .font(.caption2)
                                .padding(4)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .help(L("target.show_in_finder"))
                    }
                }
            }

            if hiddenCount > 0 {
                Text(L("target.more_locations", hiddenCount))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 2)
    }

    private func revealInFinder(_ path: String) {
        let expanded = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded) else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expanded)
    }
}
