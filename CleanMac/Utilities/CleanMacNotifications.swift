import Foundation

extension Notification.Name {
    static let cleanMacSelectRecommended = Notification.Name("CleanMac.selectRecommended")
    static let cleanMacToggleRecommended = Notification.Name("CleanMac.toggleRecommended")
    static let cleanMacDeselectAll = Notification.Name("CleanMac.deselectAll")
    static let cleanMacScan = Notification.Name("CleanMac.scan")
    static let cleanMacClean = Notification.Name("CleanMac.clean")
    /// DMG kurulum scriptinden gelen kapatma isteği
    static let cleanMacInstallQuit = Notification.Name("com.cleanmac.app.installQuit")
}
