import SwiftUI

@main
struct CleanMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = CleanMacViewModel()
    @StateObject private var updateManager = UpdateManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel, updateManager: updateManager)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.menu)

        Window("CleanMac", id: "main") {
            ContentView(viewModel: viewModel, updateManager: updateManager)
                .background {
                    MainWindowConfigurator()
                }
                .onAppear {
                    appDelegate.updateManager = updateManager
                }
        }
        .defaultSize(width: 1020, height: 800)
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
