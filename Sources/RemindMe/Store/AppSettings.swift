import SwiftUI
import AppKit

@MainActor
final class AppSettings: ObservableObject {
    private let key = "showDockIcon"

    @Published var showDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: key)
            applyActivationPolicy()
        }
    }

    init() {
        // Default true on first launch so the app is immediately visible.
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(true, forKey: key)
        }
        self.showDockIcon = UserDefaults.standard.bool(forKey: key)
    }

    func applyActivationPolicy() {
        let target: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        guard NSApp.activationPolicy() != target else { return }
        NSApp.setActivationPolicy(target)
        if target == .regular {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
