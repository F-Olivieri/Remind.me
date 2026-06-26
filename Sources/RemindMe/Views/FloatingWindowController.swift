import SwiftUI
import AppKit

/// Toggles the main Remind.me window's NSWindow.level between `.normal` and
/// `.floating`. Pin operates on the existing main window so we never have a
/// separate floating window alongside the menu-bar popover.
@MainActor
final class PinController: ObservableObject {
    @Published private(set) var isPinned = false
    private var normalStyleMask: NSWindow.StyleMask?
    private var normalTitleVisibility: NSWindow.TitleVisibility?
    private var normalTitlebarAppearsTransparent: Bool?
    private var normalBackgroundColor: NSColor?
    private var normalIsOpaque: Bool?
    private var normalMovableByBackground: Bool?

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

    func setCaptureBarVisible(_ visible: Bool) {
        guard let window = mainWindow() else { return }
        if visible {
            applyCaptureChrome(to: window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isPinned = true
        } else {
            restoreNormalChrome(on: window)
        }
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
            restoreNormalChrome(on: window)
            window.level = .normal
            window.collectionBehavior = []
            isPinned = false
        }
    }

    private func applyCaptureChrome(to window: NSWindow) {
        if normalStyleMask == nil {
            normalStyleMask = window.styleMask
            normalTitleVisibility = window.titleVisibility
            normalTitlebarAppearsTransparent = window.titlebarAppearsTransparent
            normalBackgroundColor = window.backgroundColor
            normalIsOpaque = window.isOpaque
            normalMovableByBackground = window.isMovableByWindowBackground
        }

        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.remove(.titled)
        window.styleMask.insert(.borderless)
        window.styleMask.remove(.resizable)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    private func restoreNormalChrome(on window: NSWindow) {
        if let normalStyleMask { window.styleMask = normalStyleMask }
        if let normalTitleVisibility { window.titleVisibility = normalTitleVisibility }
        if let normalTitlebarAppearsTransparent { window.titlebarAppearsTransparent = normalTitlebarAppearsTransparent }
        if let normalBackgroundColor { window.backgroundColor = normalBackgroundColor }
        if let normalIsOpaque { window.isOpaque = normalIsOpaque }
        if let normalMovableByBackground { window.isMovableByWindowBackground = normalMovableByBackground }
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
        window.level = .normal
        window.collectionBehavior = []
        isPinned = false
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
            if w.title == "Remind.me" {
                return w
            }
        }
        return NSApp.windows.first(where: {
            $0.styleMask.contains(.titled) && !($0 is NSPanel)
        })
    }
}
