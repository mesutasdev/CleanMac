import SwiftUI

struct CleanMacCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandMenu("Temizlik") {
            Button("Önerilenleri Seç") {
                NotificationCenter.default.post(name: .cleanMacSelectRecommended, object: nil)
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Button("Seçimi Kaldır") {
                NotificationCenter.default.post(name: .cleanMacDeselectAll, object: nil)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Divider()

            Button("Yeniden Tara") {
                NotificationCenter.default.post(name: .cleanMacScan, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Temizle…") {
                NotificationCenter.default.post(name: .cleanMacClean, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: [.command, .shift])
        }
    }
}
