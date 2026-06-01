import SwiftUI
import AppKit

@main
struct RemindMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings: AppSettings
    @StateObject private var store: TaskStore
    @StateObject private var pinController = PinController()

    init() {
        let s = AppSettings()
        let t = TaskStore(folderURL: s.dbFolderURL)
        // When the user picks a new folder, move the database there.
        s.onDbFolderChange = { [weak t] newURL in
            _ = t?.relocate(to: newURL)
        }
        // When retention changes, prune immediately.
        s.onRetentionChange = { [weak t] _ in
            t?.pruneArchive()
        }
        _settings = StateObject(wrappedValue: s)
        _store = StateObject(wrappedValue: t)
    }

    var body: some Scene {
        WindowGroup("Remind.me", id: "main") {
            PopupView()
                .environmentObject(store)
                .environmentObject(pinController)
                .environmentObject(settings)
                .onAppear { settings.applyActivationPolicy() }
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            PopupView()
                .environmentObject(store)
                .environmentObject(pinController)
                .environmentObject(settings)
        } label: {
            // SF Symbol → guaranteed visible template render in any menu bar.
            Image(systemName: "checklist")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let shouldShowDock = UserDefaults.standard.object(forKey: AppSettings.dockKey) as? Bool ?? true
        NSApp.setActivationPolicy(shouldShowDock ? .regular : .accessory)
        if shouldShowDock {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for w in NSApp.windows where w.title == "Remind.me" {
                w.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return false
            }
        }
        return true
    }
}
