import SwiftUI
import AppKit

/// Toggles the main Remind.me window's NSWindow.level between `.normal` and
/// `.floating`, so "pin" keeps the existing window above all other apps
/// instead of spawning a separate floating window.
@MainActor
final class PinController: ObservableObject {
    @Published private(set) var isPinned = false

    func togglePin() {
        guard let window = mainWindow() else { return }
        if isPinned {
            window.level = .normal
            window.collectionBehavior = []
            isPinned = false
        } else {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isPinned = true
        }
    }

    private func mainWindow() -> NSWindow? {
        for w in NSApp.windows where w.isVisible {
            // The SwiftUI WindowGroup window carries the scene title.
            if w.title == "Remind.me" || w.identifier?.rawValue.contains("main") == true {
                return w
            }
        }
        // Fallback: first visible non-status, non-popover window.
        return NSApp.windows.first(where: {
            $0.isVisible
            && !($0 is NSPanel)
            && $0.styleMask.contains(.titled)
        })
    }
}
