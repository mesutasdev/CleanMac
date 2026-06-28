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
                                byteTotal: viewModel.selectedBytes(in: category),
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

    private let valueRowHeight: CGFloat = 18
    private let captionRowHeight: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                BrandLogoView(size: 44, cornerRadius: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Seçili Alan")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .leading) {
                        Text("999,99 GB")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .hidden()

                        if isScanning {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(ByteCountFormatter.string(from: permanentBytes))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .frame(height: valueRowHeight, alignment: .leading)
                }
            }

            Group {
                if isScanning {
                    Text("Taranıyor…")
                } else if temporaryBytes > 0 {
                    Label {
                        Text("\(ByteCountFormatter.string(from: temporaryBytes)) geçici")
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                } else {
                    Text("Kalıcı disk tasarrufu")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            .frame(height: captionRowHeight, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 88, maxHeight: 88, alignment: .leading)
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

                Text(byteTotal > 0 ? ByteCountFormatter.string(from: byteTotal) : " ")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(byteTotal > 0 ? Color.secondary : Color.clear)
                    .frame(height: 14, alignment: .leading)
            }
        }
    }
}
