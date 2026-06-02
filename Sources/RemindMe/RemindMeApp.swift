import SwiftUI
import AppKit

@main
struct RemindMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings()
    @StateObject private var store: TaskStore

    @StateObject private var pinController = PinController()

    init() {
        let s = AppSettings()
        _store = StateObject(wrappedValue: TaskStore(folderURL: s.dbFolderURL))
    }

    var body: some Scene {
        WindowGroup("Remind.me", id: "main") {
            PopupView()
                .environmentObject(store)
                .environmentObject(pinController)
                .environmentObject(settings)
                .onAppear {
                    settings.applyActivationPolicy()
                    // Wire up store actions when settings change
                    settings.onDbFolderChange = { [weak store] newURL in
                        _ = store?.relocate(to: newURL)
                    }
                    settings.onRetentionChange = { [weak store] _ in
                        store?.pruneArchive()
                    }
                }
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            PopupView(inMenuBar: true)
                .environmentObject(store)
                .environmentObject(pinController)
                .environmentObject(settings)
                .onAppear {
                    settings.onDbFolderChange = { [weak store] newURL in
                        _ = store?.relocate(to: newURL)
                    }
                    settings.onRetentionChange = { [weak store] _ in
                        store?.pruneArchive()
                    }
                }
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
