import AppKit

enum RunningInstanceHelper {
    /// Güncelleme sırasında açık kalan eski CleanMac sürecini kapatır.
    static func terminateOtherInstances() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != currentPID }

        guard !others.isEmpty else { return }

        for app in others {
            app.terminate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            for app in others where !app.isTerminated {
                app.forceTerminate()
            }
        }
    }
}
