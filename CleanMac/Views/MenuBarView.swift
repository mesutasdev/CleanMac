import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: CleanMacViewModel

    var body: some View {
        Button("CleanMac'i Aç") {
            MainWindowController.show()
        }

        Divider()

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
            MainWindowController.show()
            viewModel.showAbout = true
        }

        Divider()

        Button("CleanMac'den Çık") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
