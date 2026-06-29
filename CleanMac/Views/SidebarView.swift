import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: CleanMacViewModel
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var appearanceManager: AppearanceManager

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
                Section(L("sidebar.categories")) {
                    NavigationLink(value: SidebarSelection.overview) {
                        SidebarCategoryLabel(
                            title: L("sidebar.overview"),
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

            AppearanceToggleView(appearanceManager: appearanceManager)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .background(.bar)

            LanguageToggleView(languageManager: languageManager)
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 10)
                .background(.bar)

            Divider()

            Button {
                viewModel.presentAbout()
            } label: {
                Label(L("menu.about"), systemImage: "info.circle")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(.bar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(L("app.name"))
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
                BrandLogoView(size: 64, cornerRadius: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L("sidebar.selected_space"))
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
                    Text(L("sidebar.scanning"))
                } else if temporaryBytes > 0 {
                    Label {
                        Text("\(ByteCountFormatter.string(from: temporaryBytes)) \(L("sidebar.temporary_suffix"))")
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                } else {
                    Text(L("sidebar.permanent_savings"))
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
