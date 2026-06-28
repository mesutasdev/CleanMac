import Foundation
import SwiftUI

@MainActor
final class CleanMacViewModel: ObservableObject {
    @Published var targets: [CleanTarget] = CleanTarget.makeDefaults()
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var statusMessage: String?
    @Published var lastFreedBytes: Int64 = 0
    @Published var showCleanConfirmation = false
    @Published var showRegeneratingCaches = false
    @Published var sidebarSelection: SidebarSelection = .overview
    @Published var showAbout = false
    @Published var diskSpace: DiskSpaceInfo? = DiskSpaceService.current()

    var selectedTotalBytes: Int64 {
        targets.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    /// Geri gelmeyen, gerçekten boşalan alan.
    var permanentReclaimBytes: Int64 {
        targets
            .filter { $0.isSelected && $0.category != .regenerating && $0.sizeBytes > 0 }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    var temporaryReclaimBytes: Int64 {
        targets
            .filter { $0.isSelected && $0.category == .regenerating && $0.sizeBytes > 0 }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    var hasScanned: Bool {
        targets.contains { $0.sizeBytes > 0 || $0.exists }
    }

    var includesLastBuildDeletion: Bool {
        targets.contains {
            ($0.kind == .xcodeDerivedDataLastBuild || $0.kind == .flutterLastBuild)
            && $0.isSelected
            && $0.sizeBytes > 0
        }
    }

    var includesRegeneratingSelection: Bool {
        targets.contains { $0.category == .regenerating && $0.isSelected && $0.sizeBytes > 0 }
    }

    func targets(in category: CleanTargetCategory) -> [CleanTarget] {
        targets.filter { $0.category == category }
    }

    func totalBytes(in category: CleanTargetCategory) -> Int64 {
        targets(in: category).reduce(0) { $0 + max(0, $1.sizeBytes) }
    }

    func visibleCategories() -> [CleanTargetCategory] {
        CleanTargetCategory.allCases.filter { category in
            category != .regenerating || showRegeneratingCaches
        }
    }

    func filteredTargets(for selection: SidebarSelection) -> [(CleanTargetCategory, [CleanTarget])] {
        switch selection {
        case .overview:
            return visibleCategories().map { ($0, targets(in: $0)) }
        case .category(let category):
            return [(category, targets(in: category))]
        }
    }

    var detailTitle: String {
        switch sidebarSelection {
        case .overview: return "Genel Bakış"
        case .category(let category): return category.sidebarTitle
        }
    }

    func refreshDiskSpace() {
        diskSpace = DiskSpaceService.current()
    }

    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        statusMessage = "Önbellekler taranıyor..."
        lastFreedBytes = 0
        refreshDiskSpace()

        let previousSelection = Dictionary(uniqueKeysWithValues: targets.map { ($0.id, $0.isSelected) })
        let scanned = await DiskScanner.scanAll()

        targets = scanned.map { target in
            var updated = target
            if let selected = previousSelection[target.id] {
                updated.isSelected = selected
            }
            return updated
        }

        isScanning = false
        statusMessage = nil
        refreshDiskSpace()

        if !previousSelection.values.contains(true) {
            selectRecommended()
        }
    }

    func toggleSelection(for target: CleanTarget) {
        guard let index = targets.firstIndex(where: { $0.id == target.id }) else { return }
        targets[index].isSelected.toggle()
    }

    var includesDestructiveDeletion: Bool {
        targets.contains {
            ($0.kind == .xcodeDerivedDataLastBuild || $0.kind == .flutterLastBuild || $0.kind == .xcodeDeviceSupportLatest)
            && $0.isSelected
            && $0.sizeBytes > 0
        }
    }

    func selectRecommended() {
        for index in targets.indices {
            let target = targets[index]
            let shouldSelect = target.category == .reclaimable && target.sizeBytes > 0
            targets[index].isSelected = shouldSelect
        }
    }

    func selectAll(_ selected: Bool) {
        for index in targets.indices {
            let target = targets[index]
            if !selected {
                targets[index].isSelected = false
                continue
            }

            let isHiddenRegenerating = target.category == .regenerating && !showRegeneratingCaches
            let isProtectedDestructive = target.kind == .xcodeDerivedDataLastBuild
                || target.kind == .flutterLastBuild
                || target.kind == .xcodeDeviceSupportLatest
            targets[index].isSelected = target.sizeBytes > 0 && !isHiddenRegenerating && !isProtectedDestructive
        }
    }

    func requestClean() {
        guard selectedTotalBytes > 0, !isCleaning else { return }
        showCleanConfirmation = true
    }

    func cleanConfirmed() async {
        showCleanConfirmation = false
        guard !isCleaning else { return }

        isCleaning = true
        statusMessage = "Temizleniyor..."

        let hadRegenerating = includesRegeneratingSelection
        let toClean = targets.filter { $0.isSelected && $0.sizeBytes > 0 }
        let results = await DiskCleaner.clean(targets: toClean)

        let freed = results.filter(\.success).reduce(0) { $0 + $1.freedBytes }
        lastFreedBytes = freed

        let failed = results.filter { !$0.success }
        if failed.isEmpty {
            if hadRegenerating {
                statusMessage = "\(ByteCountFormatter.string(from: freed)) açıldı — bir kısmı bir sonraki build'de geri gelebilir"
            } else {
                statusMessage = "\(ByteCountFormatter.string(from: freed)) kalıcı olarak açıldı"
            }
        } else {
            let names = failed.map(\.kind.title).joined(separator: ", ")
            statusMessage = "\(ByteCountFormatter.string(from: freed)) açıldı — hata: \(names)"
        }

        await scan()
        isCleaning = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let message = self?.statusMessage else { return }
            if message.contains("açıldı") {
                self?.statusMessage = nil
            }
        }
    }
}
