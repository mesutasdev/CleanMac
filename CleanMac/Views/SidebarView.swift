import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: CleanMacViewModel

    var body: some View {
        VStack(spacing: 0) {
            SidebarSummaryCard(
                permanentBytes: viewModel.permanentReclaimBytes,
                temporaryBytes: viewModel.temporaryReclaimBytes,
                isScanning: viewModel.isScanning
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)

            List(selection: $viewModel.sidebarSelection) {
                Section("Kategoriler") {
                    NavigationLink(value: SidebarSelection.overview) {
                        SidebarCategoryLabel(
                            title: "Genel Bakış",
                            systemImage: "square.grid.2x2",
                            byteTotal: viewModel.selectedTotalBytes,
                            tint: .accentColor
                        )
                    }

                    ForEach(viewModel.visibleCategories(), id: \.self) { category in
                        NavigationLink(value: SidebarSelection.category(category)) {
                            SidebarCategoryLabel(
                                title: category.sidebarTitle,
                                systemImage: category.systemImage,
                                byteTotal: viewModel.totalBytes(in: category),
                                tint: tint(for: category)
                            )
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            Button {
                viewModel.presentAbout()
            } label: {
                Label("CleanMac Hakkında", systemImage: "info.circle")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("CleanMac")
    }

    private func tint(for category: CleanTargetCategory) -> Color {
        switch category {
        case .reclaimable: return .green
        case .conditional: return .blue
        case .destructive: return .orange
        case .regenerating: return .secondary
        }
    }
}

private struct SidebarSummaryCard: View {
    let permanentBytes: Int64
    let temporaryBytes: Int64
    let isScanning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                BrandLogoView(size: 44, cornerRadius: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Seçili Alan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if isScanning {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(ByteCountFormatter.string(from: permanentBytes))
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }

            if temporaryBytes > 0 {
                Label {
                    Text("\(ByteCountFormatter.string(from: temporaryBytes)) geçici (build'de geri gelir)")
                        .font(.caption)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                }
                .foregroundStyle(.orange)
            } else if !isScanning {
                Text("Kalıcı disk tasarrufu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SidebarCategoryLabel: View {
    let title: String
    let systemImage: String
    let byteTotal: Int64
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)

                if byteTotal > 0 {
                    Text(ByteCountFormatter.string(from: byteTotal))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
