import SwiftUI

struct DetailView: View {
    @ObservedObject var viewModel: CleanMacViewModel

    var body: some View {
        VStack(spacing: 0) {
            SelectionActionsBar(
                selectedBytes: viewModel.selectedTotalBytes,
                isSelectionDisabled: viewModel.isCleaning || (viewModel.isScanning && !viewModel.hasScanned),
                isCleanDisabled: viewModel.isCleaning || viewModel.isScanning || viewModel.selectedTotalBytes == 0,
                onSelectRecommended: { viewModel.selectRecommended() },
                onDeselectAll: { viewModel.selectAll(false) },
                onClean: { viewModel.requestClean() }
            )
            .opacity(viewModel.isScanning && !viewModel.hasScanned ? 0.55 : 1)

            List {
            if viewModel.sidebarSelection == .overview {
                Section {
                    DiskUsageCard(
                        diskSpace: viewModel.diskSpace,
                        selectedBytes: viewModel.selectedTotalBytes,
                        permanentBytes: viewModel.permanentReclaimBytes
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    Text("Disk Alanı")
                }
            }

            if viewModel.isScanning && !viewModel.hasScanned {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.regular)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Önbellekler taranıyor…")
                                .font(.body)
                            Text("Disk alanı hazır — temizlenebilir dosyalar hesaplanıyor")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } else {
                ForEach(viewModel.filteredTargets(for: viewModel.sidebarSelection), id: \.0) { category, targets in
                    Section {
                        ForEach(targets) { target in
                            TargetRowView(
                                target: target,
                                isSelected: viewModel.selectionBinding(for: target.id)
                            )
                        }

                        SectionCaptionRow(text: category.sectionFooter)
                    } header: {
                        if viewModel.sidebarSelection == .overview {
                            Label {
                                Text(category.sectionTitle)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: category.systemImage)
                            }
                        }
                    }
                }

                if !viewModel.showRegeneratingCaches && viewModel.sidebarSelection == .overview {
                    Section {
                        Button {
                            viewModel.showRegeneratingCaches = true
                        } label: {
                            Label("Gelişmiş Önbellekleri Göster", systemImage: "gearshape")
                        }

                        SectionCaptionRow(
                            text: "Gradle, npm ve pub cache gibi bir sonraki build'de geri gelen önbellekler."
                        )
                    }
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .navigationTitle(viewModel.detailTitle)
        .toolbar { detailToolbar }
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

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("Yeniden Tara", systemImage: "arrow.clockwise")
            }
            .help("Önbellek boyutlarını yeniden hesapla (⌘R)")
            .disabled(viewModel.isScanning || viewModel.isCleaning)
        }
    }
}

private struct SelectionActionsBar: View {
    let selectedBytes: Int64
    let isSelectionDisabled: Bool
    let isCleanDisabled: Bool
    let onSelectRecommended: () -> Void
    let onDeselectAll: () -> Void
    let onClean: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button("Önerilenleri Seç", action: onSelectRecommended)
                .buttonStyle(.bordered)
                .disabled(isSelectionDisabled)

            Button("Seçimi Kaldır", action: onDeselectAll)
                .buttonStyle(.bordered)
                .disabled(isSelectionDisabled)

            Spacer(minLength: 12)

            Button(action: onClean) {
                Label(cleanButtonTitle, systemImage: "trash")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(isCleanDisabled)
            .help("Seçili dosyaları sil ve disk alanı aç (⌘⇧⌫)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 52, maxHeight: 52)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var cleanButtonTitle: String {
        if selectedBytes > 0 {
            return "Yer Aç · \(ByteCountFormatter.string(from: selectedBytes))"
        }
        return "Yer Aç"
    }
}

private struct SectionCaptionRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 10, trailing: 16))
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
                Text("Son temizlik: \(ByteCountFormatter.string(from: lastFreedBytes))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if hasActiveSelection {
                Text("Seçili öğeler temizlenmeye hazır")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Önerilenleri Seç ile başlayabilirsin")
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
