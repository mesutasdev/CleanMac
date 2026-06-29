import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: CleanMacViewModel
    @ObservedObject var updateManager: UpdateManager

    var body: some View {
        Button(L("menu.open")) {
            MainWindowController.show()
        }

        Divider()

        if updateManager.availableUpdate != nil {
            Button(L("menu.update", updateManager.availableUpdate?.versionLabel ?? "")) {
                MainWindowController.show()
                updateManager.showUpdateAlert = true
            }
            Divider()
        }

        Button(L("menu.refresh")) {
            MainWindowController.show()
            NotificationCenter.default.post(name: .cleanMacScan, object: nil)
        }
        .disabled(viewModel.isInteractionLocked)

        Button(L("menu.free_space")) {
            MainWindowController.show()
            viewModel.requestClean()
        }
        .disabled(viewModel.selectedTotalBytes == 0 || viewModel.isInteractionLocked)

        Divider()

        Button(L("menu.about")) {
            viewModel.presentAbout()
        }

        Divider()

        Button(L("menu.quit")) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
