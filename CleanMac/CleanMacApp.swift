import SwiftUI

@main
struct CleanMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = CleanMacViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Image("AppLogo")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)

        WindowGroup("CleanMac", id: "main") {
            ContentView(viewModel: viewModel)
                .background {
                    MainWindowConfigurator()
                }
                .onReceive(NotificationCenter.default.publisher(for: .cleanMacShowWindow)) { _ in
                    openWindow(id: "main")
                    DispatchQueue.main.async {
                        MainWindowController.show()
                    }
                }
        }
        .defaultSize(width: 1020, height: 680)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CleanMacCommands()

            CommandGroup(replacing: .appInfo) {
                Button("CleanMac Hakkında") {
                    viewModel.showAbout = true
                }
            }

            CommandGroup(replacing: .appTermination) {
                Button("Pencereyi Gizle") {
                    if let window = MainWindowController.mainWindow {
                        MainWindowController.hide(window)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("CleanMac'den Çık") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}
