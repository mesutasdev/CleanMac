import SwiftUI

struct CleanMacCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandMenu(L("menu.clean_menu")) {
            Button(L("menu.toggle_recommended")) {
                NotificationCenter.default.post(name: .cleanMacToggleRecommended, object: nil)
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Divider()

            Button(L("menu.refresh")) {
                NotificationCenter.default.post(name: .cleanMacScan, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Button(L("menu.clean")) {
                NotificationCenter.default.post(name: .cleanMacClean, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: [.command, .shift])
        }
    }
}
