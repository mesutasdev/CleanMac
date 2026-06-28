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

        for _ in 0..<40 {
            if others.allSatisfy(\.isTerminated) { return }
            Thread.sleep(forTimeInterval: 0.1)
        }

        for app in others where !app.isTerminated {
            app.forceTerminate()
        }

        Thread.sleep(forTimeInterval: 0.3)
    }
}
