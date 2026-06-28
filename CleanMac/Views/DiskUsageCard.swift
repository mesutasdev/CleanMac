import SwiftUI

struct DiskUsageCard: View {
    let diskSpace: DiskSpaceInfo?
    let selectedBytes: Int64
    let permanentBytes: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(diskSpace?.volumeName ?? L("disk.title"), systemImage: "internaldrive")
                    .font(.headline)
                Spacer()
                if let diskSpace {
                    Text(L("disk.full_percent", usedPercent(diskSpace)))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(progressTint(for: diskSpace))
                }
            }

            if let diskSpace {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(ByteCountFormatter.string(from: diskSpace.freeBytes))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(L("disk.free_label"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: diskSpace.usedFraction)
                    .tint(progressTint(for: diskSpace))

                HStack(spacing: 16) {
                    diskStat(
                        title: L("disk.total"),
                        value: ByteCountFormatter.string(from: diskSpace.totalBytes)
                    )
                    diskStat(
                        title: L("disk.used"),
                        value: ByteCountFormatter.string(from: diskSpace.usedBytes)
                    )
                    diskStat(
                        title: L("disk.remaining"),
                        value: ByteCountFormatter.string(from: diskSpace.freeBytes),
                        emphasized: true
                    )
                }

                if selectedBytes > 0 {
                    Divider()

                    Label {
                        Text(projectionText(for: diskSpace))
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                    .foregroundStyle(.green)
                }
            } else {
                Text(L("disk.unavailable"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func diskStat(title: String, value: String, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(emphasized ? .body.weight(.semibold) : .body)
                .monospacedDigit()
                .foregroundStyle(emphasized ? .primary : .secondary)
        }
    }

    private func usedPercent(_ disk: DiskSpaceInfo) -> Int {
        Int((disk.usedFraction * 100).rounded())
    }

    private func progressTint(for disk: DiskSpaceInfo) -> Color {
        let freeRatio = 1 - disk.usedFraction
        if freeRatio < 0.08 { return .red }
        if freeRatio < 0.15 { return .orange }
        return .accentColor
    }

    private func projectionText(for disk: DiskSpaceInfo) -> String {
        let projected = ByteCountFormatter.string(from: disk.projectedFree(afterReclaiming: selectedBytes))
        if permanentBytes > 0, selectedBytes > permanentBytes {
            let permanent = ByteCountFormatter.string(from: disk.projectedFree(afterReclaiming: permanentBytes))
            return L("disk.projection.both", projected, permanent)
        }
        return L("disk.projection.single", projected)
    }
}
