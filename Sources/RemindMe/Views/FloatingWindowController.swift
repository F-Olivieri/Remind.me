import SwiftUI
import AppKit

@MainActor
final class FloatingWindowController: ObservableObject {
    @Published private(set) var isOpen = false
    private var window: NSWindow?
    private weak var store: TaskStore?

    func attach(store: TaskStore) {
        self.store = store
    }

    func toggle() {
        isOpen ? close() : open()
    }

    func open() {
        guard let store else { return }
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isOpen = true
            return
        }
        let controller = FloatingWindowController_Internal()
        let root = PopupView()
            .environmentObject(store)
            .environmentObject(self)
        let host = NSHostingController(rootView: root)
        let w = NSWindow(contentViewController: host)
        w.styleMask = [.titled, .closable, .fullSizeContentView]
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.title = "Remind.me"
        w.level = .floating
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.isReleasedWhenClosed = false
        w.setContentSize(NSSize(width: 340, height: 420))
        w.center()
        w.delegate = controller
        controller.onClose = { [weak self] in
            self?.isOpen = false
            self?.window = nil
        }
        // retain delegate via objc_setAssociatedObject pattern
        objc_setAssociatedObject(w, "fwc_delegate", controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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

private final class FloatingWindowController_Internal: NSObject, NSWindowDelegate {
    var onClose: (() -> Void)?
    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
