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
    @Published private(set) var selectedTargetIDs: Set<String> = []
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

    func isSelected(_ id: String) -> Bool {
        selectedTargetIDs.contains(id)
    }

    var selectedTotalBytes: Int64 {
        targets.filter { isSelected($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    var permanentReclaimBytes: Int64 {
        targets
            .filter { isSelected($0.id) && $0.category != .regenerating && $0.sizeBytes > 0 }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    var temporaryReclaimBytes: Int64 {
        targets
            .filter { isSelected($0.id) && $0.category == .regenerating && $0.sizeBytes > 0 }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    var hasScanned: Bool {
        targets.contains { $0.sizeBytes > 0 || $0.exists }
    }

    var hasActiveSelection: Bool {
        targets.contains { isSelected($0.id) && $0.sizeBytes > 0 }
    }

    var includesLastBuildDeletion: Bool {
        targets.contains {
            ($0.kind == .xcodeDerivedDataLastBuild || $0.kind == .flutterLastBuild)
            && isSelected($0.id)
            && $0.sizeBytes > 0
        }
    }

    var includesRegeneratingSelection: Bool {
        targets.contains { $0.category == .regenerating && isSelected($0.id) && $0.sizeBytes > 0 }
    }

    var isRecommendedSelectionActive: Bool {
        let recommended = targets.filter { $0.category == .reclaimable && $0.sizeBytes > 0 }
        guard !recommended.isEmpty else { return false }
        return recommended.allSatisfy { isSelected($0.id) }
            && targets.filter { !($0.category == .reclaimable && $0.sizeBytes > 0) }
                .allSatisfy { !isSelected($0.id) }
    }

    func targets(in category: CleanTargetCategory) -> [CleanTarget] {
        targets.filter { $0.category == category }
    }

    func totalBytes(in category: CleanTargetCategory) -> Int64 {
        targets(in: category).reduce(0) { $0 + max(0, $1.sizeBytes) }
    }

    func selectedBytes(in category: CleanTargetCategory) -> Int64 {
        targets(in: category)
            .filter { isSelected($0.id) }
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
        let previousSelection = selectedTargetIDs
        let scanned = await DiskScanner.scanAll()

        targets = scanned

        selectedTargetIDs = previousSelection.filter { id in
            scanned.first(where: { $0.id == id })?.sizeBytes ?? 0 > 0
        }

        isScanning = false
        if options.clearStatusMessage {
            statusMessage = nil
        }
        refreshDiskSpace()

        if options.autoSelectRecommended {
            let hadMeaningfulSelection = previousSelection.contains { id in
                scanned.first(where: { $0.id == id })?.sizeBytes ?? 0 > 0
            }
            if wasFirstScan || !hadMeaningfulSelection {
                selectRecommended()
            }
        }
    }

    func toggleSelection(for target: CleanTarget) {
        setSelected(id: target.id, selected: !isSelected(target.id))
    }

    func setSelected(id: String, selected: Bool) {
        guard !isInteractionLocked else { return }
        guard let target = targets.first(where: { $0.id == id }) else { return }
        guard target.sizeBytes > 0 || !selected else { return }

        if selected {
            guard !selectedTargetIDs.contains(id) else { return }
            selectedTargetIDs.insert(id)
        } else {
            guard selectedTargetIDs.contains(id) else { return }
            selectedTargetIDs.remove(id)
        }
    }

    var includesDestructiveDeletion: Bool {
        targets.contains {
            ($0.kind == .xcodeDerivedDataLastBuild || $0.kind == .flutterLastBuild || $0.kind == .xcodeDeviceSupportLatest)
            && isSelected($0.id)
            && $0.sizeBytes > 0
        }
    }

    func selectRecommended() {
        guard !isInteractionLocked else { return }

        selectedTargetIDs = Set(
            targets
                .filter { $0.category == .reclaimable && $0.sizeBytes > 0 }
                .map(\.id)
        )
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

        if !selected {
            selectedTargetIDs.removeAll()
            return
        }

        selectedTargetIDs = Set(
            targets.filter { target in
                guard target.sizeBytes > 0 else { return false }
                if target.category == .regenerating && !showRegeneratingCaches { return false }
                if target.kind == .xcodeDerivedDataLastBuild
                    || target.kind == .flutterLastBuild
                    || target.kind == .xcodeDeviceSupportLatest {
                    return false
                }
                return true
            }
            .map(\.id)
        )
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
        let toClean = targets.filter { isSelected($0.id) && $0.sizeBytes > 0 }
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
}
