import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        RunningInstanceHelper.terminateOtherInstances()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            MainWindowController.show()
        }
        return true
    }
}

enum MainWindowController {
    static let mainWindowIdentifier = "cleanmac-main-window"

    private static var openHandler: (() -> Void)?
    private static var pendingLaunchShow = true

    static func registerOpenHandler(_ handler: @escaping () -> Void) {
        openHandler = handler

        guard pendingLaunchShow else { return }
        pendingLaunchShow = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            show()
        }
    }

    static func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        openHandler?()
        presentMainWindow(retry: 0)
    }

    static func hide(_ window: NSWindow) {
        window.orderOut(nil)
    }

    static var mainWindow: NSWindow? {
        NSApp.windows.first { window in
            window.identifier?.rawValue == mainWindowIdentifier
                || window.title == "CleanMac"
        }
    }

    private static func presentMainWindow(retry: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let window = mainWindow {
                window.identifier = NSUserInterfaceItemIdentifier(mainWindowIdentifier)
                window.isReleasedWhenClosed = false
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            guard retry < 12 else { return }
            openHandler?()
            presentMainWindow(retry: retry + 1)
        }
    }
}

struct MainWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.identifier = NSUserInterfaceItemIdentifier(MainWindowController.mainWindowIdentifier)
            window.isReleasedWhenClosed = false
            window.delegate = context.coordinator
            window.makeKeyAndOrderFront(nil)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            MainWindowController.hide(sender)
            return false
        }
    }
}
