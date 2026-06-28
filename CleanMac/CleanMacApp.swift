import SwiftUI

@main
struct CleanMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = CleanMacViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.menu)

        Window("CleanMac", id: "main") {
            ContentView(viewModel: viewModel)
                .background {
                    MainWindowConfigurator()
                }
        }
        .defaultSize(width: 1020, height: 720)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CleanMacCommands()

            CommandGroup(replacing: .appInfo) {
                Button("CleanMac Hakkında") {
                    viewModel.presentAbout()
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
