import SwiftUI
import AppKit

@MainActor
final class FloatingWindowController: ObservableObject {
    @Published private(set) var isOpen = false
    private var window: NSWindow?
    private weak var store: TaskStore?
    private weak var settings: AppSettings?

    func attach(store: TaskStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
    }

    func toggle() {
        isOpen ? close() : open()
    }

    func open() {
        guard let store, let settings else { return }
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isOpen = true
            return
        }
        let delegate = FloatingWindowDelegate()
        let root = PopupView()
            .environmentObject(store)
            .environmentObject(settings)
            .environmentObject(self)
            .background(FloatingWindowChrome())
        let host = NSHostingController(rootView: root)
        let w = HoverRevealWindow(contentViewController: host)
        w.styleMask = [.titled, .closable, .fullSizeContentView]
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.title = "Remind.me"
        w.level = .floating
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.isReleasedWhenClosed = false
        w.backgroundColor = .clear
        w.isOpaque = false
        w.hasShadow = true
        w.setContentSize(NSSize(width: 340, height: 420))
        w.center()
        w.delegate = delegate
        delegate.onClose = { [weak self] in
            self?.isOpen = false
            self?.window = nil
        }
        objc_setAssociatedObject(w, "fwc_delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // Hide traffic lights by default; HoverRevealWindow toggles them on hover.
        w.standardWindowButton(.closeButton)?.alphaValue = 0
        w.standardWindowButton(.miniaturizeButton)?.isHidden = true
        w.standardWindowButton(.zoomButton)?.isHidden = true

        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
        isOpen = true
    }

    func close() {
        window?.close()
        window = nil
        isOpen = false
    }
}

private final class FloatingWindowDelegate: NSObject, NSWindowDelegate {
    var onClose: (() -> Void)?
    func windowWillClose(_ notification: Notification) { onClose?() }
}

/// NSWindow that reveals its close button on mouse-enter and hides it on mouse-exit.
final class HoverRevealWindow: NSWindow {
    private var trackingArea: NSTrackingArea?

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        installTrackingIfNeeded()
    }

    private func installTrackingIfNeeded() {
        guard let view = contentView else { return }
        if let existing = trackingArea { view.removeTrackingArea(existing) }
        let area = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        view.addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        animateTrafficLight(alpha: 1)
    }

    override func mouseExited(with event: NSEvent) {
        animateTrafficLight(alpha: 0)
    }

    private func animateTrafficLight(alpha: CGFloat) {
        guard let btn = standardWindowButton(.closeButton) else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.allowsImplicitAnimation = true
            btn.animator().alphaValue = alpha
        }
    }
}

/// Floating window chrome: solid fallback + 1pt hairline border, clipped to the design radius.
private struct FloatingWindowChrome: View {
    var body: some View {
        ZStack {
            // Solid fallback ensures legibility when material is unavailable / over busy windows.
            Color.rmWindowFallback
            // Vibrancy on top.
            Rectangle().fill(.regularMaterial)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.window, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.window, style: .continuous))
        .ignoresSafeArea()
    }
}
