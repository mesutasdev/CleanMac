import SwiftUI

struct DetailView: View {
    @ObservedObject var viewModel: CleanMacViewModel

    var body: some View {
        VStack(spacing: 0) {
            DetailTitleBar(
                title: viewModel.detailTitle,
                isInteractionLocked: viewModel.isInteractionLocked,
                onRefresh: { Task { await viewModel.scan() } }
            )

            SelectionActionsBar(
                selectedBytes: viewModel.selectedTotalBytes,
                isRecommendedSelectionActive: viewModel.isRecommendedSelectionActive,
                isSelectionDisabled: viewModel.isInteractionLocked,
                isCleanDisabled: viewModel.isInteractionLocked || viewModel.selectedTotalBytes == 0,
                onToggleRecommended: { viewModel.toggleRecommendedSelection() },
                onClean: { viewModel.requestClean() }
            )
            .opacity(viewModel.isScanning && !viewModel.hasScanned ? 0.55 : 1)

            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StatusBarView(
                message: viewModel.statusMessage,
                isScanning: viewModel.isScanning,
                isCleaning: viewModel.isCleaning,
                lastFreedBytes: viewModel.lastFreedBytes,
                hasActiveSelection: viewModel.hasActiveSelection
            )
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch viewModel.sidebarSelection {
        case .overview:
            OverviewDetailContent(viewModel: viewModel)
        case .category(let category):
            CategoryDetailContent(
                viewModel: viewModel,
                category: category,
                targets: viewModel.targets(in: category),
                selectedIDs: viewModel.selectedTargetIDs
            )
        }
    }
}

private struct DetailTitleBar: View {
    let title: String
    let isInteractionLocked: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))
                .lineLimit(1)

            Spacer()

            Button(action: onRefresh) {
                Label(L("menu.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.titleAndIcon)
            .help(L("detail.refresh_help"))
            .disabled(isInteractionLocked)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(height: 52)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}

private struct OverviewDetailContent: View {
    @ObservedObject var viewModel: CleanMacViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(L("detail.disk_space"))

                DiskUsageCard(
                    diskSpace: viewModel.diskSpace,
                    selectedBytes: viewModel.selectedTotalBytes,
                    permanentBytes: viewModel.permanentReclaimBytes
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .onAppear {
                    viewModel.refreshDiskSpace()
                }

                if viewModel.isScanning && !viewModel.hasScanned {
                    ScanningTargetsCard()
                } else {
                    ForEach(viewModel.visibleCategories(), id: \.self) { category in
                        TargetCategorySection(
                            category: category,
                            targets: viewModel.targets(in: category),
                            selectedIDs: viewModel.selectedTargetIDs,
                            isInteractionLocked: viewModel.isInteractionLocked,
                            showHeader: true,
                            onSelectionChange: { id, selected in
                                viewModel.setSelected(id: id, selected: selected)
                            }
                        )
                    }

                    if !viewModel.showRegeneratingCaches {
                        Button {
                            viewModel.showRegeneratingCaches = true
                        } label: {
                            Label(L("detail.show_advanced_caches"), systemImage: "gearshape")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        Text(L("detail.advanced_caches_footer"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct CategoryDetailContent: View {
    @ObservedObject var viewModel: CleanMacViewModel
    let category: CleanTargetCategory
    let targets: [CleanTarget]
    let selectedIDs: Set<String>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isScanning && !viewModel.hasScanned {
                    ScanningTargetsCard()
                } else {
                    TargetCategorySection(
                        category: category,
                        targets: targets,
                        selectedIDs: selectedIDs,
                        isInteractionLocked: viewModel.isInteractionLocked,
                        showHeader: false,
                        onSelectionChange: { id, selected in
                            viewModel.setSelected(id: id, selected: selected)
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct ScanningTargetsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(L("sidebar.categories"))

            HStack(alignment: .center, spacing: 12) {
                ProgressView()
                    .controlSize(.regular)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("detail.scanning_title"))
                        .font(.body)
                    Text(L("detail.scanning_subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

private struct TargetCategorySection: View {
    let category: CleanTargetCategory
    let targets: [CleanTarget]
    let selectedIDs: Set<String>
    let isInteractionLocked: Bool
    let showHeader: Bool
    let onSelectionChange: (String, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showHeader {
                sectionHeader(category.sectionTitle, systemImage: category.systemImage)
            }

            ForEach(Array(targets.enumerated()), id: \.element.id) { index, target in
                TargetRowView(
                    target: target,
                    isSelected: selectedIDs.contains(target.id),
                    isInteractionLocked: isInteractionLocked,
                    onSelectionChange: { selected in
                        onSelectionChange(target.id, selected)
                    }
                )
                .equatable()
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(index.isMultiple(of: 2) ? Color.clear : Color.primary.opacity(0.03))
            }

            Text(category.sectionFooter)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func sectionHeader(_ title: String, systemImage: String? = nil) -> some View {
    HStack(spacing: 8) {
        if let systemImage {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
        Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 8)
}

private struct SelectionActionsBar: View {
    let selectedBytes: Int64
    let isRecommendedSelectionActive: Bool
    let isSelectionDisabled: Bool
    let isCleanDisabled: Bool
    let onToggleRecommended: () -> Void
    let onClean: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleRecommended) {
                Label {
                    Text(
                        isRecommendedSelectionActive
                            ? L("detail.deselect_recommended")
                            : L("detail.select_recommended")
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                } icon: {
                    Image(
                        systemName: isRecommendedSelectionActive
                            ? "checkmark.circle.fill"
                            : "checkmark.circle"
                    )
                }
            }
            .buttonStyle(.bordered)
            .disabled(isSelectionDisabled)
            .frame(minWidth: 168, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: 12)

            Button(action: onClean) {
                Label {
                    Text(cleanButtonTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                } icon: {
                    Image(systemName: "trash")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(isCleanDisabled)
            .help(L("detail.free_space_help"))
            .frame(minWidth: 140, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 52)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var cleanButtonTitle: String {
        if selectedBytes > 0 {
            return "\(L("detail.free_space")) · \(ByteCountFormatter.string(from: selectedBytes))"
        }
        return L("detail.free_space")
    }
}

private struct StatusBarView: View {
    let message: String?
    let isScanning: Bool
    let isCleaning: Bool
    let lastFreedBytes: Int64
    let hasActiveSelection: Bool

    var body: some View {
        HStack(spacing: 8) {
            if let message {
                if isCleaning || isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            } else if lastFreedBytes > 0 {
                Image(systemName: "sparkles")
                    .foregroundStyle(.secondary)
                Text(L("detail.last_clean", ByteCountFormatter.string(from: lastFreedBytes)))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if hasActiveSelection {
                Text(L("detail.status_ready"))
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L("detail.status_hint"))
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
