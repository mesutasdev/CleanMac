import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: CleanMacViewModel
    @ObservedObject var updateManager: UpdateManager

    var body: some View {
        Button("CleanMac'i Aç") {
            MainWindowController.show()
        }

        Divider()

        if updateManager.availableUpdate != nil {
            Button("Güncelle (\(updateManager.availableUpdate?.versionLabel ?? ""))") {
                MainWindowController.show()
                updateManager.showUpdateAlert = true
            }
            Divider()
        }

        Button("Yeniden Tara") {
            MainWindowController.show()
            NotificationCenter.default.post(name: .cleanMacScan, object: nil)
        }
        .disabled(viewModel.isScanning || viewModel.isCleaning)

        Button("Yer Aç…") {
            MainWindowController.show()
            viewModel.requestClean()
        }
        .disabled(viewModel.selectedTotalBytes == 0 || viewModel.isScanning || viewModel.isCleaning)

        Divider()

        Button("CleanMac Hakkında") {
            viewModel.presentAbout()
        }

        Divider()

        Button("CleanMac'den Çık") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
