import SwiftUI
import AppKit

/// Toggles the main Remind.me window's NSWindow.level between `.normal` and
/// `.floating`. Pin operates on the existing main window so we never have a
/// separate floating window alongside the menu-bar popover.
@MainActor
final class PinController: ObservableObject {
    @Published private(set) var isPinned = false

    /// Pin the main window and dismiss the menu-bar popover, fading both
    /// transitions for a smooth handoff. `openWindow` is the SwiftUI
    /// environment value from the calling view; we use it so the WindowGroup
    /// is brought up if it isn't visible yet.
    func pinFromMenuBar(openWindow: (String) -> Void) {
        dismissMenuBarPopover()
        openWindow("main")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.applyPinned(true, fadeIn: true)
        }
    }

    /// Toggle pin from the popup itself (no popover to dismiss).
    func togglePin() {
        applyPinned(!isPinned, fadeIn: false)
    }

    // MARK: - Implementation

    private func applyPinned(_ pinned: Bool, fadeIn: Bool) {
        guard let window = mainWindow() else { return }
        if pinned {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            if fadeIn {
                window.alphaValue = 0
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.22
                    ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    window.animator().alphaValue = 1
                }
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            isPinned = true
        } else {
            window.level = .normal
            window.collectionBehavior = []
            isPinned = false
        }
    }

    private func dismissMenuBarPopover() {
        for w in NSApp.windows {
            let cls = String(describing: type(of: w))
            let isStatusPanel = w.level == .statusBar
                || cls.contains("StatusBar")
                || cls.contains("MenuBarExtra")
            guard isStatusPanel, w.isVisible else { continue }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.15
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                w.animator().alphaValue = 0
            }, completionHandler: {
                w.orderOut(nil)
                w.alphaValue = 1   // reset for next reveal
            })
        }
    }

    private func mainWindow() -> NSWindow? {
        for w in NSApp.windows {
            if w.title == "Remind.me" && w.styleMask.contains(.titled) {
                return w
            }
        }
        return NSApp.windows.first(where: {
            $0.styleMask.contains(.titled) && !($0 is NSPanel)
        })
    }
}
