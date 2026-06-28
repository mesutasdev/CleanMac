import SwiftUI

struct DiskUsageCard: View {
    let diskSpace: DiskSpaceInfo?
    let reclaimableBytes: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(diskSpace?.volumeName ?? "Disk", systemImage: "internaldrive")
                    .font(.headline)
                Spacer()
                if let diskSpace {
                    Text("\(usedPercent(diskSpace))% dolu")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(progressTint(for: diskSpace))
                }
            }

            if let diskSpace {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(ByteCountFormatter.string(from: diskSpace.freeBytes))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("boş")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: diskSpace.usedFraction)
                    .tint(progressTint(for: diskSpace))

                HStack(spacing: 16) {
                    diskStat(
                        title: "Toplam",
                        value: ByteCountFormatter.string(from: diskSpace.totalBytes)
                    )
                    diskStat(
                        title: "Kullanılan",
                        value: ByteCountFormatter.string(from: diskSpace.usedBytes)
                    )
                    diskStat(
                        title: "Kalan",
                        value: ByteCountFormatter.string(from: diskSpace.freeBytes),
                        emphasized: true
                    )
                }

                if reclaimableBytes > 0 {
                    Divider()

                    Label {
                        Text("Temizlik sonrası ~\(ByteCountFormatter.string(from: diskSpace.projectedFree(afterReclaiming: reclaimableBytes))) boş alan")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                    .foregroundStyle(.green)
                }
            } else {
                Text("Disk bilgisi alınamadı")
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
}

#Preview {
    DiskUsageCard(
        diskSpace: DiskSpaceInfo(volumeName: "Macintosh HD", totalBytes: 250_000_000_000, freeBytes: 12_000_000_000),
        reclaimableBytes: 16_000_000_000
    )
    .padding()
    .frame(width: 520)
}
