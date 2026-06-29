import Foundation
import SwiftUI

@MainActor
final class CleanMacViewModel: ObservableObject {
    struct ScanOptions {
        var clearStatusMessage = true
        var resetLastFreed = true
        var autoSelectRecommended = true
    }

    @Published var targets: [CleanTarget] = CleanTarget.makeDefaults()
    @Published private(set) var targetsGeneration = 0
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var statusMessage: String?
    @Published var lastFreedBytes: Int64 = 0
    @Published var showCleanConfirmation = false
    @Published var showRegeneratingCaches = false
    @Published var sidebarSelection: SidebarSelection = .overview
    @Published var showAbout = false
    @Published var diskSpace: DiskSpaceInfo? = DiskSpaceService.current()

    private var shouldAutoClearStatus = false
    private var runningScan: Task<Void, Never>?

    var isInteractionLocked: Bool {
        isScanning || isCleaning
    }

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

    var hasActiveSelection: Bool {
        targets.contains { $0.isSelected && $0.sizeBytes > 0 }
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

    var isRecommendedSelectionActive: Bool {
        let hasRecommended = targets.contains { $0.category == .reclaimable && $0.sizeBytes > 0 }
        guard hasRecommended else { return false }

        return targets.allSatisfy { target in
            let shouldSelect = target.category == .reclaimable && target.sizeBytes > 0
            return target.isSelected == shouldSelect
        }
    }

    func targets(in category: CleanTargetCategory) -> [CleanTarget] {
        targets.filter { $0.category == category }
    }

    func totalBytes(in category: CleanTargetCategory) -> Int64 {
        targets(in: category).reduce(0) { $0 + max(0, $1.sizeBytes) }
    }

    func selectedBytes(in category: CleanTargetCategory) -> Int64 {
        targets(in: category)
            .filter(\.isSelected)
            .reduce(0) { $0 + max(0, $1.sizeBytes) }
    }

    func visibleCategories() -> [CleanTargetCategory] {
        CleanTargetCategory.allCases.filter { category in
            category != .regenerating || showRegeneratingCaches
        }
    }

    var detailTitle: String {
        switch sidebarSelection {
        case .overview: return L("sidebar.overview")
        case .category(let category): return category.sidebarTitle
        }
    }

    func refreshDiskSpace() {
        diskSpace = DiskSpaceService.current()
    }

    func presentAbout() {
        guard !showAbout else {
            MainWindowController.show()
            return
        }
        MainWindowController.show()
        showAbout = true
    }

    func scan(options: ScanOptions = ScanOptions()) async {
        if let runningScan {
            await runningScan.value
        }

        guard !isScanning else { return }

        let task = Task { @MainActor in
            await performScan(options: options)
        }
        runningScan = task
        await task.value
        runningScan = nil
    }

    private func performScan(options: ScanOptions) async {
        guard !isScanning else { return }

        isScanning = true
        statusMessage = L("scan.scanning_status")
        if options.resetLastFreed {
            lastFreedBytes = 0
        }
        refreshDiskSpace()

        let wasFirstScan = !hasScanned
        let previousSelection = Dictionary(uniqueKeysWithValues: targets.map { ($0.id, $0.isSelected) })
        let scanned = await DiskScanner.scanAll()

        replaceTargets(scanned.map { target in
            var updated = target
            if let selected = previousSelection[target.id] {
                updated.isSelected = selected
            }
            if updated.sizeBytes == 0 {
                updated.isSelected = false
            }
            return updated
        })

        isScanning = false
        if options.clearStatusMessage {
            statusMessage = nil
        }
        refreshDiskSpace()

        if options.autoSelectRecommended {
            let hadMeaningfulSelection = previousSelection.contains { id, selected in
                guard selected else { return false }
                return scanned.first(where: { $0.id == id })?.sizeBytes ?? 0 > 0
            }
            if wasFirstScan || !hadMeaningfulSelection {
                selectRecommended()
            }
        }
    }

    func toggleSelection(for target: CleanTarget) {
        setSelected(id: target.id, selected: !target.isSelected)
    }

    func setSelected(id: String, selected: Bool) {
        guard !isInteractionLocked else { return }
        guard let index = targets.firstIndex(where: { $0.id == id }) else { return }
        guard targets[index].isSelected != selected else { return }
        guard targets[index].sizeBytes > 0 || !selected else { return }

        var updated = targets
        updated[index].isSelected = selected
        replaceTargets(updated)
    }

    var includesDestructiveDeletion: Bool {
        targets.contains {
            ($0.kind == .xcodeDerivedDataLastBuild || $0.kind == .flutterLastBuild || $0.kind == .xcodeDeviceSupportLatest)
            && $0.isSelected
            && $0.sizeBytes > 0
        }
    }

    func selectRecommended() {
        guard !isInteractionLocked else { return }

        replaceTargets(targets.map { target in
            var updated = target
            updated.isSelected = target.category == .reclaimable && target.sizeBytes > 0
            return updated
        })
    }

    func toggleRecommendedSelection() {
        guard !isInteractionLocked else { return }

        if isRecommendedSelectionActive {
            selectAll(false)
        } else {
            selectRecommended()
        }
    }

    func selectAll(_ selected: Bool) {
        guard !isInteractionLocked else { return }

        replaceTargets(targets.map { target in
            var updated = target
            if !selected {
                updated.isSelected = false
                return updated
            }

            let isHiddenRegenerating = target.category == .regenerating && !showRegeneratingCaches
            let isProtectedDestructive = target.kind == .xcodeDerivedDataLastBuild
                || target.kind == .flutterLastBuild
                || target.kind == .xcodeDeviceSupportLatest
            updated.isSelected = target.sizeBytes > 0 && !isHiddenRegenerating && !isProtectedDestructive
            return updated
        })
    }

    func requestClean() {
        guard selectedTotalBytes > 0, !isInteractionLocked else { return }
        MainWindowController.show()
        showCleanConfirmation = true
    }

    func cleanConfirmed() async {
        showCleanConfirmation = false
        guard !isInteractionLocked else { return }

        isCleaning = true
        shouldAutoClearStatus = false
        statusMessage = L("scan.cleaning_status")

        let hadRegenerating = includesRegeneratingSelection
        let toClean = targets.filter { $0.isSelected && $0.sizeBytes > 0 }
        let results = await DiskCleaner.clean(targets: toClean)

        let freed = results.filter(\.success).reduce(0) { $0 + $1.freedBytes }
        lastFreedBytes = freed

        let failed = results.filter { !$0.success }
        let partial = results.filter { $0.success && $0.message != nil }

        let completionMessage: String
        if failed.isEmpty {
            if hadRegenerating {
                completionMessage = L("scan.freed.regenerating", ByteCountFormatter.string(from: freed))
            } else {
                completionMessage = L("scan.freed.permanent", ByteCountFormatter.string(from: freed))
            }
        } else {
            let names = failed.map(\.kind.title).joined(separator: ", ")
            completionMessage = L("scan.freed.partial_error", ByteCountFormatter.string(from: freed), names)
        }

        if !partial.isEmpty, failed.isEmpty {
            let notes = partial.compactMap(\.message).joined(separator: "; ")
            statusMessage = "\(completionMessage) (\(notes))"
        } else {
            statusMessage = completionMessage
        }
        shouldAutoClearStatus = true

        await scan(options: ScanOptions(clearStatusMessage: false, resetLastFreed: false, autoSelectRecommended: true))
        isCleaning = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            guard let self, self.shouldAutoClearStatus else { return }
            self.statusMessage = nil
            self.shouldAutoClearStatus = false
        }
    }

    private func replaceTargets(_ newTargets: [CleanTarget]) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            targets = newTargets
            targetsGeneration += 1
        }
    }
}
