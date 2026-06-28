import SwiftUI

@main
struct CleanMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = CleanMacViewModel()
    @StateObject private var updateManager = UpdateManager()
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel, updateManager: updateManager)
                .id(languageManager.refreshToken)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.menu)

        Window(L("app.name"), id: "main") {
            ContentView(viewModel: viewModel, updateManager: updateManager, languageManager: languageManager)
                .background {
                    MainWindowConfigurator()
                }
                .onAppear {
                    appDelegate.updateManager = updateManager
                }
                .id(languageManager.refreshToken)
        }
        .defaultSize(width: 1020, height: 800)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CleanMacCommands()

            CommandGroup(replacing: .appInfo) {
                Button(L("menu.about")) {
                    viewModel.presentAbout()
                }
            }

            CommandGroup(replacing: .appTermination) {
                Button(L("menu.hide_window")) {
                    if let window = MainWindowController.mainWindow {
                        MainWindowController.hide(window)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)

                Button(L("menu.quit")) {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}
