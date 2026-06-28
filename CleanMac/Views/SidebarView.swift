import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: CleanMacViewModel

    var body: some View {
        List(selection: $viewModel.sidebarSelection) {
            Section {
                SidebarSummaryCard(
                    permanentBytes: viewModel.permanentReclaimBytes,
                    temporaryBytes: viewModel.temporaryReclaimBytes,
                    isScanning: viewModel.isScanning
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                BrandLogoView(size: 64, cornerRadius: 16)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Seçili Alan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if isScanning {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Text(ByteCountFormatter.string(from: permanentBytes))
                            .font(.title.weight(.semibold))
                            .monospacedDigit()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if temporaryBytes > 0 {
                Label {
                    Text("\(ByteCountFormatter.string(from: temporaryBytes)) geçici (build'de geri gelir)")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            } else if !isScanning {
                Text("Kalıcı disk tasarrufu")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
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
