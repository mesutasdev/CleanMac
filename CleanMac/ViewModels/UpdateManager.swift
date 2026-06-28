import Foundation

@MainActor
final class UpdateManager: ObservableObject {
    @Published var availableUpdate: AvailableUpdate?
    @Published var showUpdateAlert = false
    @Published var isUpdating = false
    @Published var updateStatus: String?
    @Published var manualCheckMessage: String?
    @Published var showManualCheckAlert = false

    private let skippedVersionKey = "skippedUpdateVersion"

    private var hasCheckedThisSession = false

    func checkForUpdates(force: Bool = false) async {
        guard !isUpdating else { return }
        if !force, hasCheckedThisSession { return }
        if !force { hasCheckedThisSession = true }

        do {
            guard let latest = try await UpdateService.shared.fetchLatestUpdate() else { return }
            guard let current = AppVersion.current else { return }

            if latest.version <= current {
                availableUpdate = nil
                if force {
                    manualCheckMessage = L("update.latest", current.displayString)
                    showManualCheckAlert = true
                }
                return
            }

            availableUpdate = latest

            if force {
                showUpdateAlert = true
                MainWindowController.show()
                return
            }

            let skippedVersion = UserDefaults.standard.string(forKey: skippedVersionKey)
            guard skippedVersion != latest.version.displayString else { return }

            showUpdateAlert = true
            MainWindowController.show()
        } catch {
            if force {
                manualCheckMessage = error.localizedDescription
                showManualCheckAlert = true
            }
        }
    }

    func skipUpdate() {
        if let version = availableUpdate?.version.displayString {
            UserDefaults.standard.set(version, forKey: skippedVersionKey)
        }
        showUpdateAlert = false
    }

    func installUpdate() async {
        guard let update = availableUpdate else { return }

        isUpdating = true
        showUpdateAlert = false
        updateStatus = L("update.downloading")

        do {
            try await UpdateService.shared.downloadAndInstall(from: update.downloadURL) { [weak self] status in
                Task { @MainActor in
                    self?.updateStatus = status
                }
            }
        } catch {
            isUpdating = false
            updateStatus = nil
            manualCheckMessage = error.localizedDescription
            showManualCheckAlert = true
        }
    }
}
